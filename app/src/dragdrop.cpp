// Messages as files with OLE: the data a drag of messages out of the list carries (the app's own format for the folder
// tree, files for Explorer), the drop source and the drop targets of the tree and the list, and what Explorer does
// with the data (for the UI test). The files are the core's: their names, their bytes and the Mark of the Web.
#include <windows.h>
#include <ole2.h>
#include <shellapi.h>
#include <shlobj.h>
#include <shlwapi.h>
#include <shobjidl.h>

#include <atomic>
#include <functional>
#include <map>
#include <mutex>
#include <optional>
#include <thread>

#include "app.h"

namespace {

// the app's own format: the id of the process that dragged, so a drop on another start of the app (another store)
// is not taken for its own messages
UINT OwnFormat() {
    static UINT format = RegisterClipboardFormatW(L"InboxClassicMessages");
    return format;
}

UINT DescriptorFormat() {
    static UINT format = RegisterClipboardFormatW(CFSTR_FILEDESCRIPTORW);
    return format;
}

UINT ContentsFormat() {
    static UINT format = RegisterClipboardFormatW(CFSTR_FILECONTENTS);
    return format;
}

UINT PreferredEffectFormat() {
    static UINT format = RegisterClipboardFormatW(CFSTR_PREFERREDDROPEFFECT);
    return format;
}

// a copy of what a medium holds, for the data a drag image helper leaves on the object (HGLOBAL only)
bool CopyMedium(const STGMEDIUM& from, STGMEDIUM& to) {
    if (from.tymed != TYMED_HGLOBAL) {
        return false;
    }
    SIZE_T size = GlobalSize(from.hGlobal);
    HGLOBAL copy = GlobalAlloc(GMEM_MOVEABLE, size);
    if (!copy) {
        return false;
    }
    void* source = GlobalLock(from.hGlobal);
    void* target = GlobalLock(copy);
    if (source && target) {
        memcpy(target, source, size);
    }
    GlobalUnlock(from.hGlobal);
    GlobalUnlock(copy);
    to = {};
    to.tymed = TYMED_HGLOBAL;
    to.hGlobal = copy;
    return true;
}

HGLOBAL GlobalOf(const void* data, size_t size) {
    HGLOBAL global = GlobalAlloc(GMEM_MOVEABLE | GMEM_ZEROINIT, size);
    if (global && size) {
        memcpy(GlobalLock(global), data, size);
        GlobalUnlock(global);
    }
    return global;
}

// CF_HDROP of `paths`
HGLOBAL DropFiles(const std::vector<std::wstring>& paths) {
    std::wstring list;
    for (const std::wstring& path : paths) {
        list += path;
        list.push_back(L'\0');
    }
    list.push_back(L'\0');
    size_t size = sizeof(DROPFILES) + list.size() * sizeof(wchar_t);
    HGLOBAL global = GlobalAlloc(GMEM_MOVEABLE | GMEM_ZEROINIT, size);
    if (!global) {
        return nullptr;
    }
    auto* drop = static_cast<DROPFILES*>(GlobalLock(global));
    drop->pFiles = sizeof(DROPFILES);
    drop->fWide = TRUE;
    memcpy(reinterpret_cast<BYTE*>(drop) + sizeof(DROPFILES), list.data(), list.size() * sizeof(wchar_t));
    GlobalUnlock(global);
    return global;
}

// runs `work` on a thread of its own while this one keeps its windows answering, as a drop into Explorer waits for
// messages that are downloaded first
template <typename T>
T WhilePumping(std::function<T()> work) {
    std::atomic<bool> done = false;
    T result{};
    std::thread worker([&] {
        result = work();
        done = true;
    });
    while (!done) {
        MsgWaitForMultipleObjects(0, nullptr, FALSE, 50, QS_ALLINPUT);
        MSG message;
        while (PeekMessageW(&message, nullptr, 0, 0, PM_REMOVE)) {
            TranslateMessage(&message);
            DispatchMessageW(&message);
        }
    }
    worker.join();
    return result;
}

// the messages of a drag out of the list as data: the app's own format, the files when they are written already
// (CF_HDROP), or their names and contents to be fetched when a drop asks for them (virtual files)
class MessageData : public IDataObject, public IDataObjectAsyncCapability {
public:
    MessageData(PeCore* core, core::Selection selection, std::vector<std::wstring> names, std::vector<std::wstring> written)
        : core_(core), selection_(std::move(selection)), names_(std::move(names)), written_(std::move(written)) {}

    ~MessageData() {
        for (auto& [format, medium] : extra_) {
            ReleaseStgMedium(&medium);
        }
    }

    // IUnknown
    HRESULT STDMETHODCALLTYPE QueryInterface(REFIID iid, void** out) override {
        if (!out) {
            return E_POINTER;
        }
        if (iid == __uuidof(IUnknown) || iid == __uuidof(IDataObject)) {
            *out = static_cast<IDataObject*>(this);
        } else if (iid == __uuidof(IDataObjectAsyncCapability)) {
            *out = static_cast<IDataObjectAsyncCapability*>(this);
        } else {
            *out = nullptr;
            return E_NOINTERFACE;
        }
        AddRef();
        return S_OK;
    }
    ULONG STDMETHODCALLTYPE AddRef() override { return ++references_; }
    ULONG STDMETHODCALLTYPE Release() override {
        ULONG left = --references_;
        if (left == 0) {
            delete this;
        }
        return left;
    }

    // IDataObject
    HRESULT STDMETHODCALLTYPE GetData(FORMATETC* format, STGMEDIUM* medium) override {
        if (!format || !medium) {
            return E_INVALIDARG;
        }
        *medium = {};
        if (auto found = extra_.find(format->cfFormat); found != extra_.end()) {
            return CopyMedium(found->second, *medium) ? S_OK : DV_E_TYMED;
        }
        if (!(format->tymed & TYMED_HGLOBAL) && format->cfFormat != ContentsFormat()) {
            return DV_E_TYMED;
        }
        if (format->cfFormat == OwnFormat()) {
            DWORD process = GetCurrentProcessId();
            medium->tymed = TYMED_HGLOBAL;
            medium->hGlobal = GlobalOf(&process, sizeof(process));
            return medium->hGlobal ? S_OK : E_OUTOFMEMORY;
        }
        if (format->cfFormat == PreferredEffectFormat()) {
            // a copy where it goes: the message stays in the mailbox
            DWORD effect = DROPEFFECT_COPY;
            medium->tymed = TYMED_HGLOBAL;
            medium->hGlobal = GlobalOf(&effect, sizeof(effect));
            return S_OK;
        }
        if (format->cfFormat == CF_HDROP && !written_.empty()) {
            medium->tymed = TYMED_HGLOBAL;
            medium->hGlobal = DropFiles(written_);
            return medium->hGlobal ? S_OK : E_OUTOFMEMORY;
        }
        if (format->cfFormat == DescriptorFormat() && written_.empty()) {
            size_t size = sizeof(FILEGROUPDESCRIPTORW) + (names_.empty() ? 0 : names_.size() - 1) * sizeof(FILEDESCRIPTORW);
            HGLOBAL global = GlobalAlloc(GMEM_MOVEABLE | GMEM_ZEROINIT, size);
            if (!global) {
                return E_OUTOFMEMORY;
            }
            auto* group = static_cast<FILEGROUPDESCRIPTORW*>(GlobalLock(global));
            group->cItems = static_cast<UINT>(names_.size());
            for (size_t i = 0; i < names_.size(); i++) {
                group->fgd[i].dwFlags = FD_PROGRESSUI;
                lstrcpynW(group->fgd[i].cFileName, names_[i].c_str(), MAX_PATH);
            }
            GlobalUnlock(global);
            medium->tymed = TYMED_HGLOBAL;
            medium->hGlobal = global;
            return S_OK;
        }
        if (format->cfFormat == ContentsFormat() && written_.empty()) {
            if (!(format->tymed & TYMED_ISTREAM) || format->lindex < 0 || static_cast<size_t>(format->lindex) >= names_.size()) {
                return DV_E_FORMATETC;
            }
            const std::vector<std::string>& files = Contents();
            if (static_cast<size_t>(format->lindex) >= files.size() || files[format->lindex].empty()) {
                // not to be had (gone from the server, not downloaded in time): the drop is told
                return E_FAIL;
            }
            const std::string& bytes = files[format->lindex];
            IStream* stream = SHCreateMemStream(reinterpret_cast<const BYTE*>(bytes.data()), static_cast<UINT>(bytes.size()));
            if (!stream) {
                return E_OUTOFMEMORY;
            }
            medium->tymed = TYMED_ISTREAM;
            medium->pstm = stream;
            return S_OK;
        }
        return DV_E_FORMATETC;
    }
    HRESULT STDMETHODCALLTYPE GetDataHere(FORMATETC*, STGMEDIUM*) override { return E_NOTIMPL; }
    HRESULT STDMETHODCALLTYPE QueryGetData(FORMATETC* format) override {
        if (!format) {
            return E_INVALIDARG;
        }
        if (extra_.contains(format->cfFormat) || format->cfFormat == OwnFormat() || format->cfFormat == PreferredEffectFormat()) {
            return S_OK;
        }
        if (written_.empty() ? (format->cfFormat == DescriptorFormat() || format->cfFormat == ContentsFormat())
                             : format->cfFormat == CF_HDROP) {
            return S_OK;
        }
        return DV_E_FORMATETC;
    }
    HRESULT STDMETHODCALLTYPE GetCanonicalFormatEtc(FORMATETC*, FORMATETC* out) override {
        if (out) {
            out->ptd = nullptr;
        }
        return DATA_S_SAMEFORMATETC;
    }
    // what a drag image helper or a drop target leaves on the data, kept for whoever asks for it
    HRESULT STDMETHODCALLTYPE SetData(FORMATETC* format, STGMEDIUM* medium, BOOL release) override {
        if (!format || !medium) {
            return E_INVALIDARG;
        }
        STGMEDIUM kept = {};
        if (release) {
            kept = *medium;
        } else if (!CopyMedium(*medium, kept)) {
            return DV_E_TYMED;
        }
        if (auto found = extra_.find(format->cfFormat); found != extra_.end()) {
            ReleaseStgMedium(&found->second);
        }
        extra_[format->cfFormat] = kept;
        return S_OK;
    }
    HRESULT STDMETHODCALLTYPE EnumFormatEtc(DWORD direction, IEnumFORMATETC** out) override {
        if (direction != DATADIR_GET) {
            return E_NOTIMPL;
        }
        std::vector<FORMATETC> formats = {
            {static_cast<CLIPFORMAT>(OwnFormat()), nullptr, DVASPECT_CONTENT, -1, TYMED_HGLOBAL},
            {static_cast<CLIPFORMAT>(PreferredEffectFormat()), nullptr, DVASPECT_CONTENT, -1, TYMED_HGLOBAL},
        };
        if (written_.empty()) {
            formats.push_back({static_cast<CLIPFORMAT>(DescriptorFormat()), nullptr, DVASPECT_CONTENT, -1, TYMED_HGLOBAL});
            formats.push_back({static_cast<CLIPFORMAT>(ContentsFormat()), nullptr, DVASPECT_CONTENT, -1, TYMED_ISTREAM});
        } else {
            formats.push_back({CF_HDROP, nullptr, DVASPECT_CONTENT, -1, TYMED_HGLOBAL});
        }
        for (const auto& [format, medium] : extra_) {
            formats.push_back({static_cast<CLIPFORMAT>(format), nullptr, DVASPECT_CONTENT, -1, TYMED_HGLOBAL});
        }
        return SHCreateStdEnumFmtEtc(static_cast<UINT>(formats.size()), formats.data(), out);
    }
    HRESULT STDMETHODCALLTYPE DAdvise(FORMATETC*, DWORD, IAdviseSink*, DWORD*) override { return OLE_E_ADVISENOTSUPPORTED; }
    HRESULT STDMETHODCALLTYPE DUnadvise(DWORD) override { return OLE_E_ADVISENOTSUPPORTED; }
    HRESULT STDMETHODCALLTYPE EnumDAdvise(IEnumSTATDATA**) override { return OLE_E_ADVISENOTSUPPORTED; }

    // IDataObjectAsyncCapability: Explorer takes the files of a drop on a thread of its own, not keeping the drag
    // waiting while messages are downloaded
    HRESULT STDMETHODCALLTYPE SetAsyncMode(BOOL async) override {
        async_ = async;
        return S_OK;
    }
    HRESULT STDMETHODCALLTYPE GetAsyncMode(BOOL* async) override {
        if (!async) {
            return E_POINTER;
        }
        *async = async_;
        return S_OK;
    }
    HRESULT STDMETHODCALLTYPE StartOperation(IBindCtx*) override {
        inOperation_ = true;
        return S_OK;
    }
    HRESULT STDMETHODCALLTYPE InOperation(BOOL* in) override {
        if (!in) {
            return E_POINTER;
        }
        *in = inOperation_;
        return S_OK;
    }
    HRESULT STDMETHODCALLTYPE EndOperation(HRESULT, IBindCtx*, DWORD) override {
        inOperation_ = false;
        return S_OK;
    }

    const std::vector<std::wstring>& Names() const { return names_; }

    // the files' bytes, fetched once when the first is asked for: from the store, or downloaded meanwhile
    const std::vector<std::string>& Contents() {
        std::lock_guard<std::mutex> lock(contentsLock_);
        if (contents_) {
            return *contents_;
        }
        PeCore* core = core_;
        PeSelection* selection = selection_.get();
        contents_ = WhilePumping<std::vector<std::string>>([core, selection] {
            std::vector<std::string> files;
            PeExport* exported = pe_selection_export(core, selection, 120000);
            for (size_t i = 0, count = pe_export_count(exported); i < count; i++) {
                const char* name = nullptr;
                const uint8_t* data = nullptr;
                size_t length = 0;
                const char* error = nullptr;
                pe_export_get(exported, i, &name, &data, &length, &error);
                files.emplace_back(data ? std::string(reinterpret_cast<const char*>(data), length) : std::string());
            }
            pe_export_free(exported);
            return files;
        });
        return *contents_;
    }

private:
    std::atomic<ULONG> references_ = 1;
    PeCore* core_;
    core::Selection selection_;
    std::vector<std::wstring> names_;
    std::vector<std::wstring> written_;
    std::map<UINT, STGMEDIUM> extra_;
    std::mutex contentsLock_;
    std::optional<std::vector<std::string>> contents_;
    BOOL async_ = TRUE;
    BOOL inOperation_ = FALSE;
};

class DropSource : public IDropSource {
public:
    HRESULT STDMETHODCALLTYPE QueryInterface(REFIID iid, void** out) override {
        if (iid == __uuidof(IUnknown) || iid == __uuidof(IDropSource)) {
            *out = static_cast<IDropSource*>(this);
            AddRef();
            return S_OK;
        }
        *out = nullptr;
        return E_NOINTERFACE;
    }
    ULONG STDMETHODCALLTYPE AddRef() override { return ++references_; }
    ULONG STDMETHODCALLTYPE Release() override {
        ULONG left = --references_;
        if (left == 0) {
            delete this;
        }
        return left;
    }
    // Esc cancels, letting go of the button drops
    HRESULT STDMETHODCALLTYPE QueryContinueDrag(BOOL escape, DWORD keys) override {
        if (escape) {
            return DRAGDROP_S_CANCEL;
        }
        return (keys & MK_LBUTTON) ? S_OK : DRAGDROP_S_DROP;
    }
    HRESULT STDMETHODCALLTYPE GiveFeedback(DWORD) override { return DRAGDROP_S_USEDEFAULTCURSORS; }

private:
    std::atomic<ULONG> references_ = 1;
};

class DropTarget : public IDropTarget {
public:
    DropTarget(HWND window, DropSite* site) : window_(window), site_(site) {
        CoCreateInstance(CLSID_DragDropHelper, nullptr, CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&helper_));
    }
    ~DropTarget() {
        if (helper_) {
            helper_->Release();
        }
    }
    HRESULT STDMETHODCALLTYPE QueryInterface(REFIID iid, void** out) override {
        if (iid == __uuidof(IUnknown) || iid == __uuidof(IDropTarget)) {
            *out = static_cast<IDropTarget*>(this);
            AddRef();
            return S_OK;
        }
        *out = nullptr;
        return E_NOINTERFACE;
    }
    ULONG STDMETHODCALLTYPE AddRef() override { return ++references_; }
    ULONG STDMETHODCALLTYPE Release() override {
        ULONG left = --references_;
        if (left == 0) {
            delete this;
        }
        return left;
    }
    HRESULT STDMETHODCALLTYPE DragEnter(IDataObject* data, DWORD keys, POINTL at, DWORD* effect) override {
        // what the drag carries, read once: it does not change on the way
        kind_ = DropKind(data);
        *effect = site_->Over(kind_, {at.x, at.y}, keys, *effect);
        if (helper_) {
            POINT point = {at.x, at.y};
            helper_->DragEnter(window_, data, &point, *effect);
        }
        return S_OK;
    }
    HRESULT STDMETHODCALLTYPE DragOver(DWORD keys, POINTL at, DWORD* effect) override {
        *effect = site_->Over(kind_, {at.x, at.y}, keys, *effect);
        if (helper_) {
            POINT point = {at.x, at.y};
            helper_->DragOver(&point, *effect);
        }
        return S_OK;
    }
    HRESULT STDMETHODCALLTYPE DragLeave() override {
        site_->Leave();
        kind_ = DropFrom::Nothing;
        if (helper_) {
            helper_->DragLeave();
        }
        return S_OK;
    }
    HRESULT STDMETHODCALLTYPE Drop(IDataObject* data, DWORD keys, POINTL at, DWORD* effect) override {
        if (helper_) {
            POINT point = {at.x, at.y};
            helper_->Drop(data, &point, *effect);
        }
        *effect = site_->Dropped(data, kind_, {at.x, at.y}, keys, *effect);
        kind_ = DropFrom::Nothing;
        return S_OK;
    }
    // the drag image hidden while the window under it changes
    void ShowImage(bool show) {
        if (helper_) {
            helper_->Show(show);
        }
    }

private:
    std::atomic<ULONG> references_ = 1;
    HWND window_;
    DropSite* site_;
    IDropTargetHelper* helper_ = nullptr;
    DropFrom kind_ = DropFrom::Nothing;
};

}  // namespace

DropFrom DropKind(IDataObject* data) {
    FORMATETC own = {static_cast<CLIPFORMAT>(OwnFormat()), nullptr, DVASPECT_CONTENT, -1, TYMED_HGLOBAL};
    STGMEDIUM medium = {};
    if (SUCCEEDED(data->GetData(&own, &medium))) {
        DWORD process = 0;
        if (void* bytes = GlobalLock(medium.hGlobal)) {
            memcpy(&process, bytes, std::min<SIZE_T>(sizeof(process), GlobalSize(medium.hGlobal)));
            GlobalUnlock(medium.hGlobal);
        }
        ReleaseStgMedium(&medium);
        // messages of another start of the app are of another store: not taken
        return process == GetCurrentProcessId() ? DropFrom::Messages : DropFrom::Nothing;
    }
    std::vector<std::wstring> files = DroppedFiles(data);
    if (files.empty()) {
        return DropFrom::Nothing;
    }
    // messages only: a file that is not one turns the drop away at the cursor
    for (const std::wstring& file : files) {
        if (!pe_is_message_file(core::Narrow(file).c_str())) {
            return DropFrom::Nothing;
        }
    }
    return DropFrom::Files;
}

std::vector<std::wstring> DroppedFiles(IDataObject* data) {
    std::vector<std::wstring> files;
    FORMATETC format = {CF_HDROP, nullptr, DVASPECT_CONTENT, -1, TYMED_HGLOBAL};
    STGMEDIUM medium = {};
    if (FAILED(data->GetData(&format, &medium))) {
        return files;
    }
    auto drop = static_cast<HDROP>(GlobalLock(medium.hGlobal));
    if (drop) {
        UINT count = DragQueryFileW(drop, 0xFFFFFFFF, nullptr, 0);
        for (UINT i = 0; i < count; i++) {
            UINT length = DragQueryFileW(drop, i, nullptr, 0);
            std::wstring file(length, L'\0');
            DragQueryFileW(drop, i, file.data(), length + 1);
            files.push_back(file);
        }
        GlobalUnlock(medium.hGlobal);
    }
    ReleaseStgMedium(&medium);
    return files;
}

IDropTarget* RegisterDropSite(HWND window, DropSite* site) {
    auto* target = new DropTarget(window, site);
    if (FAILED(RegisterDragDrop(window, target))) {
        target->Release();
        return nullptr;
    }
    return target;
}

void ShowDragImage(IDropTarget* target, bool show) {
    if (target) {
        static_cast<DropTarget*>(target)->ShowImage(show);
    }
}

IDataObject* MessagesData(PeCore* core, const PeSelection* selection) {
    core::Selection copy(pe_selection_new());
    int64_t folder = 0;
    uint64_t uid = 0;
    for (size_t i = 0; pe_selection_get(selection, i, &folder, &uid); i++) {
        pe_selection_add(copy.get(), folder, uid);
    }
    std::vector<std::wstring> names;
    if (PeTextList* list = pe_selection_file_names(core, copy.get())) {
        for (size_t i = 0, count = pe_text_list_count(list); i < count; i++) {
            names.push_back(Text(pe_text_list_get(list, i)));
        }
        pe_text_list_free(list);
    }
    // all downloaded: written now by the core into a folder of the user's own, with the Mark of the Web, and handed
    // over as files that keep it
    std::vector<std::wstring> written;
    if (pe_selection_all_downloaded(core, copy.get())) {
        char* reason = nullptr;
        if (PeTextList* paths = pe_selection_drag_files(core, copy.get(), 10000, &reason)) {
            for (size_t i = 0, count = pe_text_list_count(paths); i < count; i++) {
                written.push_back(Text(pe_text_list_get(paths, i)));
            }
            pe_text_list_free(paths);
        }
        // not written: offered as files fetched when a drop asks for them
        core::String why(reason);
    }
    return new MessageData(core, std::move(copy), std::move(names), std::move(written));
}

DWORD RunDrag(IDataObject* data, HBITMAP image, SIZE size, POINT offset) {
    if (image) {
        IDragSourceHelper* helper = nullptr;
        if (SUCCEEDED(CoCreateInstance(CLSID_DragDropHelper, nullptr, CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&helper)))) {
            SHDRAGIMAGE drag = {};
            drag.sizeDragImage = size;
            drag.ptOffset = offset;
            drag.hbmpDragImage = image;
            drag.crColorKey = CLR_NONE;
            // the helper owns the bitmap from here on
            if (FAILED(helper->InitializeFromBitmap(&drag, data))) {
                DeleteObject(image);
            }
            helper->Release();
        } else {
            DeleteObject(image);
        }
    }
    auto* source = new DropSource();
    DWORD effect = DROPEFFECT_NONE;
    DoDragDrop(data, source, DROPEFFECT_MOVE | DROPEFFECT_COPY, &effect);
    source->Release();
    return effect;
}

HBITMAP DragImage(HFONT font, const std::wstring& subject, size_t count, SIZE& size) {
    HDC screen = GetDC(nullptr);
    HDC dc = CreateCompatibleDC(screen);
    HGDIOBJ oldFont = SelectObject(dc, font);
    std::wstring badge = count > 1 ? std::to_wstring(count) : L"";
    std::wstring text = subject.empty() ? L"(no subject)" : subject;
    RECT measure = {0, 0, 0, 0};
    DrawTextW(dc, text.c_str(), -1, &measure, DT_CALCRECT | DT_SINGLELINE | DT_NOPREFIX);
    int pad = Scale(6);
    int textWidth = std::min<int>(measure.right, Scale(280));
    int height = measure.bottom + 2 * pad;
    RECT badgeBox = {0, 0, 0, 0};
    if (!badge.empty()) {
        DrawTextW(dc, badge.c_str(), -1, &badgeBox, DT_CALCRECT | DT_SINGLELINE);
    }
    int badgeWidth = badge.empty() ? 0 : std::max<int>(badgeBox.right + 2 * Scale(5), height - 2 * Scale(3));
    size = {textWidth + 2 * pad + (badgeWidth ? badgeWidth + pad : 0), height};

    BITMAPINFO info = {};
    info.bmiHeader.biSize = sizeof(info.bmiHeader);
    info.bmiHeader.biWidth = size.cx;
    info.bmiHeader.biHeight = -size.cy;
    info.bmiHeader.biPlanes = 1;
    info.bmiHeader.biBitCount = 32;
    void* bits = nullptr;
    HBITMAP bitmap = CreateDIBSection(dc, &info, DIB_RGB_COLORS, &bits, nullptr, 0);
    HGDIOBJ oldBitmap = SelectObject(dc, bitmap);
    // the row as the list shows it selected: the selection colour, its text
    RECT all = {0, 0, size.cx, size.cy};
    HBRUSH back = CreateSolidBrush(GetSysColor(COLOR_HIGHLIGHT));
    FillRect(dc, &all, back);
    DeleteObject(back);
    SetBkMode(dc, TRANSPARENT);
    SetTextColor(dc, GetSysColor(COLOR_HIGHLIGHTTEXT));
    RECT textBox = {pad, pad, pad + textWidth, size.cy - pad};
    DrawTextW(dc, text.c_str(), -1, &textBox, DT_SINGLELINE | DT_NOPREFIX | DT_END_ELLIPSIS | DT_VCENTER);
    if (badgeWidth) {
        // how many, in a red badge at the right, as the shell's own drag of several files shows it
        RECT box = {size.cx - pad - badgeWidth, Scale(3), size.cx - pad, size.cy - Scale(3)};
        HBRUSH red = CreateSolidBrush(RGB(0xD1, 0x34, 0x38));
        HGDIOBJ oldBrush = SelectObject(dc, red);
        HGDIOBJ oldPen = SelectObject(dc, GetStockObject(NULL_PEN));
        RoundRect(dc, box.left, box.top, box.right + 1, box.bottom + 1, box.bottom - box.top, box.bottom - box.top);
        SelectObject(dc, oldPen);
        SelectObject(dc, oldBrush);
        DeleteObject(red);
        SetTextColor(dc, RGB(0xFF, 0xFF, 0xFF));
        DrawTextW(dc, badge.c_str(), -1, &box, DT_SINGLELINE | DT_CENTER | DT_VCENTER);
    }
    GdiFlush();
    // opaque: GDI leaves the alpha at 0
    auto* pixel = static_cast<uint32_t*>(bits);
    for (LONG i = 0; i < size.cx * size.cy; i++) {
        pixel[i] |= 0xFF000000;
    }
    SelectObject(dc, oldBitmap);
    SelectObject(dc, oldFont);
    DeleteDC(dc);
    ReleaseDC(nullptr, screen);
    return bitmap;
}

int WriteDataInto(IDataObject* data, const std::wstring& dir) {
    // files written already: copied as Explorer copies them, keeping the Mark of the Web stream
    std::vector<std::wstring> files = DroppedFiles(data);
    int written = 0;
    if (!files.empty()) {
        for (const std::wstring& file : files) {
            std::wstring target = dir + L"\\" + PathFindFileNameW(file.c_str());
            if (CopyFileW(file.c_str(), target.c_str(), TRUE)) {
                written++;
            }
        }
        return written;
    }
    // virtual files: their names, then each one's contents
    FORMATETC descriptor = {static_cast<CLIPFORMAT>(DescriptorFormat()), nullptr, DVASPECT_CONTENT, -1, TYMED_HGLOBAL};
    STGMEDIUM medium = {};
    if (FAILED(data->GetData(&descriptor, &medium))) {
        return -1;
    }
    std::vector<std::wstring> names;
    if (auto* group = static_cast<FILEGROUPDESCRIPTORW*>(GlobalLock(medium.hGlobal))) {
        for (UINT i = 0; i < group->cItems; i++) {
            names.push_back(group->fgd[i].cFileName);
        }
        GlobalUnlock(medium.hGlobal);
    }
    ReleaseStgMedium(&medium);
    for (size_t i = 0; i < names.size(); i++) {
        FORMATETC contents = {static_cast<CLIPFORMAT>(ContentsFormat()), nullptr, DVASPECT_CONTENT, static_cast<LONG>(i), TYMED_ISTREAM};
        STGMEDIUM stream = {};
        if (FAILED(data->GetData(&contents, &stream))) {
            continue;
        }
        std::string bytes;
        char buffer[16384];
        ULONG read = 0;
        while (SUCCEEDED(stream.pstm->Read(buffer, sizeof(buffer), &read)) && read > 0) {
            bytes.append(buffer, read);
        }
        ReleaseStgMedium(&stream);
        if (WriteFileBytes(dir + L"\\" + names[i], reinterpret_cast<const uint8_t*>(bytes.data()), bytes.size())) {
            written++;
        }
    }
    return written;
}

IDataObject* FilesData(const std::vector<std::wstring>& paths) {
    // the shell's own data object, with the files as Explorer hands them over (CF_HDROP)
    IDataObject* data = nullptr;
    if (FAILED(SHCreateDataObject(nullptr, 0, nullptr, nullptr, IID_PPV_ARGS(&data)))) {
        return nullptr;
    }
    FORMATETC format = {CF_HDROP, nullptr, DVASPECT_CONTENT, -1, TYMED_HGLOBAL};
    STGMEDIUM medium = {};
    medium.tymed = TYMED_HGLOBAL;
    medium.hGlobal = DropFiles(paths);
    if (!medium.hGlobal || FAILED(data->SetData(&format, &medium, TRUE))) {
        ReleaseStgMedium(&medium);
        data->Release();
        return nullptr;
    }
    return data;
}
