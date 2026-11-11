// The compose window's editor. Unlike the preview this WebView2 runs a script, the page's own (see editor.h); the
// rest is locked down the same way: no network, no navigation, no dev tools, no host objects, and none of the browser
// keys that could reload the page and lose what was written.
#include "editor.h"

#include "core.h"
#include "webview.h"

using Microsoft::WRL::Callback;
using Microsoft::WRL::ComPtr;

namespace {

const wchar_t* kHostClass = L"InboxClassicEditor";
// the right-click menu, shown after WebView2's event asked for it
constexpr UINT WM_EDITOR_MENU = WM_APP + 40;
// where the page is served from memory (webview.h); .invalid never resolves, nothing else is served for it
const wchar_t* kPageUrl = L"https://compose.inboxclassic.invalid/";

// `value` as a JavaScript string literal: everything but plain letters and digits escaped, so no value can end the
// string
std::wstring JsString(const std::wstring& value) {
    std::wstring out = L"'";
    for (wchar_t c : value) {
        if ((c >= L'a' && c <= L'z') || (c >= L'A' && c <= L'Z') || (c >= L'0' && c <= L'9') || c == L' ') {
            out += c;
        } else {
            wchar_t escaped[8];
            swprintf_s(escaped, L"\\u%04x", static_cast<unsigned>(c));
            out += escaped;
        }
    }
    return out + L"'";
}

}  // namespace

LRESULT CALLBACK Editor::HostProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {
    auto* editor = reinterpret_cast<Editor*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
    if (message == WM_SETFOCUS && editor) {
        // Tab from the fields lands on the host: the editor takes it
        editor->Focus();
        return 0;
    }
    // the keys are the editor's once it is there; before (or when WebView2 could not start) Tab and Esc are the window's
    if (message == WM_GETDLGCODE && editor && editor->controller_) {
        return DLGC_WANTALLKEYS;
    }
    if (message == WM_EDITOR_MENU && editor) {
        editor->ShowMenu();
        return 0;
    }
    return DefWindowProcW(hwnd, message, wParam, lParam);
}

HWND Editor::Create(HWND parent, int id, const std::wstring& document, Handlers handlers) {
    static bool registered = false;
    if (!registered) {
        WNDCLASSEXW windowClass = {sizeof(windowClass)};
        windowClass.lpfnWndProc = HostProc;
        windowClass.hInstance = GetModuleHandleW(nullptr);
        windowClass.hCursor = LoadCursorW(nullptr, IDC_IBEAM);
        windowClass.hbrBackground = reinterpret_cast<HBRUSH>(COLOR_WINDOW + 1);
        windowClass.lpszClassName = kHostClass;
        RegisterClassExW(&windowClass);
        registered = true;
    }
    document_ = document;
    handlers_ = std::move(handlers);
    host_ = CreateWindowExW(WS_EX_CLIENTEDGE, kHostClass, nullptr, WS_CHILD | WS_VISIBLE | WS_TABSTOP | WS_CLIPCHILDREN, 0, 0, 0, 0,
                            parent, reinterpret_cast<HMENU>(static_cast<INT_PTR>(id)), GetModuleHandleW(nullptr), nullptr);
    SetWindowLongPtrW(host_, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(this));
    webview::Create(
        host_,
        [this](ICoreWebView2Environment* environment, ICoreWebView2Controller* controller) {
            environment_ = environment;
            controller_ = controller;
            controller_->get_CoreWebView2(&view_);
            Configure();
        },
        [this](const std::wstring& error) { handlers_.error(error + L" " + core::T(PE_TEXT_WIN_EDITOR_FAILED)); });
    return host_;
}

void Editor::Configure() {
    // its own script; cut, copy, paste and the spelling suggestions stay in the context menu
    webview::LockDown(view_.Get(), true);

    // the page from memory, nothing from the network, pasted pictures from the web included
    webview::FilterRequests(
        view_.Get(), environment_.Get(), kPageUrl, [this]() -> const std::wstring& { return document_; },
        [](const wchar_t*, COREWEBVIEW2_WEB_RESOURCE_CONTEXT) { return false; });

    // the page is all there is; links are not followed while writing
    webview::StayOnPage(view_.Get(), kPageUrl);

    view_->add_WebMessageReceived(
        Callback<ICoreWebView2WebMessageReceivedEventHandler>([this](ICoreWebView2*, ICoreWebView2WebMessageReceivedEventArgs* args) {
            LPWSTR text = nullptr;
            if (FAILED(args->TryGetWebMessageAsString(&text)) || !text) {
                return S_OK;
            }
            std::wstring message = text;
            CoTaskMemFree(text);
            if (message.rfind(L"html:", 0) == 0) {
                handlers_.html(message.substr(5), EditorQuote::Folded, L"");
            } else if (message.rfind(L"split:", 0) == 0) {
                // what was written, the separator, the quote: the first separator, as the quote may hold one
                size_t separator = message.find(L'\x1f', 6);
                if (separator == std::wstring::npos) {
                    handlers_.html(message.substr(6), EditorQuote::Removed, L"");
                } else {
                    handlers_.html(message.substr(6, separator - 6), EditorQuote::Edited, message.substr(separator + 1));
                }
            } else if (message.rfind(L"full:", 0) == 0) {
                handlers_.html(message.substr(5), EditorQuote::Removed, L"");
            } else if (message.rfind(L"state:", 0) == 0) {
                handlers_.state(message.substr(6));
            } else if (message == L"dirty") {
                handlers_.dirty();
            } else if (message == L"drop") {
                handlers_.dropped(DroppedFiles(args));
            } else if (message.rfind(L"caret:", 0) == 0 || message.rfind(L"hover:", 0) == 0) {
                (message[0] == L'c' ? caretLink_ : hoverLink_) = message.substr(6);
                handlers_.link(hoverLink_.empty() ? caretLink_ : hoverLink_);
            } else if (message.rfind(L"open:", 0) == 0) {
                webview::OpenExternally(message.c_str() + 5);
            }
            return S_OK;
        }).Get(),
        nullptr);

    controller_->add_AcceleratorKeyPressed(
        Callback<ICoreWebView2AcceleratorKeyPressedEventHandler>([this](ICoreWebView2Controller*, ICoreWebView2AcceleratorKeyPressedEventArgs* args) {
            COREWEBVIEW2_KEY_EVENT_KIND kind;
            UINT key = 0;
            args->get_KeyEventKind(&kind);
            args->get_VirtualKey(&key);
            bool control = GetKeyState(VK_CONTROL) & 0x8000;
            if (kind == COREWEBVIEW2_KEY_EVENT_KIND_KEY_DOWN && control && key == VK_RETURN) {
                args->put_Handled(TRUE);
                handlers_.send();
            } else if (kind == COREWEBVIEW2_KEY_EVENT_KIND_KEY_DOWN && control && key == 'S') {
                args->put_Handled(TRUE);
                handlers_.save();
            } else if (kind == COREWEBVIEW2_KEY_EVENT_KIND_KEY_DOWN && control && key == 'K') {
                args->put_Handled(TRUE);
                handlers_.editLink();
            }
            return S_OK;
        }).Get(),
        nullptr);

    LinkMenu();

    RECT bounds;
    GetClientRect(host_, &bounds);
    controller_->put_Bounds(bounds);
    controller_->put_IsVisible(TRUE);
    view_->Navigate(kPageUrl);
    if (focusWhenReady_) {
        Focus();
    }
}

void Editor::LinkMenu() {
    // the right-click menu is the app's own, as the rest of the window's: WebView2's would bring its own look, words
    // and browser items. The menu shows once the event is done with (WM_EDITOR_MENU), not inside WebView2's call
    Microsoft::WRL::ComPtr<ICoreWebView2_11> view;
    if (FAILED(view_.As(&view))) {
        return;
    }
    view->add_ContextMenuRequested(
        Callback<ICoreWebView2ContextMenuRequestedEventHandler>([this](ICoreWebView2*, ICoreWebView2ContextMenuRequestedEventArgs* args) {
            Microsoft::WRL::ComPtr<ICoreWebView2Deferral> deferral;
            if (menuArgs_ || FAILED(args->GetDeferral(&deferral))) {
                return S_OK;
            }
            args->put_Handled(TRUE);
            menuArgs_ = args;
            menuDeferral_ = deferral;
            PostMessageW(host_, WM_EDITOR_MENU, 0, 0);
            return S_OK;
        }).Get(),
        nullptr);
}

namespace {

enum MenuId : UINT { MENU_OPEN_LINK = 1, MENU_EDIT_LINK, MENU_REMOVE_LINK, MENU_FIRST_PAGE_ITEM = 100 };

// WebView2's own items the menu keeps, by their names: the spelling suggestions, then the editing commands in the
// app's words
struct PageItem {
    INT32 id;
    std::wstring label;
    bool enabled;
};

std::wstring EditLabel(const std::wstring& name) {
    if (name == L"cut") {
        return core::T(PE_TEXT_MAC_CUT);
    }
    if (name == L"copy") {
        return core::T(PE_TEXT_UI_BUTTON_COPY);
    }
    if (name == L"paste") {
        return core::T(PE_TEXT_MAC_PASTE);
    }
    if (name == L"selectAll") {
        return core::T(PE_TEXT_CMD_SELECT_ALL);
    }
    return L"";
}

void PageItems(ICoreWebView2ContextMenuItemCollection* items, std::vector<PageItem>& spelling, std::vector<PageItem>& editing) {
    UINT32 count = 0;
    items->get_Count(&count);
    for (UINT32 i = 0; i < count; i++) {
        Microsoft::WRL::ComPtr<ICoreWebView2ContextMenuItem> item;
        LPWSTR name = nullptr;
        if (FAILED(items->GetValueAtIndex(i, &item)) || FAILED(item->get_Name(&name)) || !name) {
            continue;
        }
        std::wstring kind = name;
        CoTaskMemFree(name);
        PageItem page = {};
        BOOL enabled = FALSE;
        item->get_CommandId(&page.id);
        item->get_IsEnabled(&enabled);
        page.enabled = enabled != FALSE;
        if (kind == L"spellCheck") {
            LPWSTR label = nullptr;
            if (SUCCEEDED(item->get_Label(&label)) && label) {
                page.label = label;
                CoTaskMemFree(label);
                spelling.push_back(page);
            }
        } else if (page.label = EditLabel(kind); !page.label.empty()) {
            editing.push_back(page);
        }
    }
}

void AppendPageItems(HMENU menu, const std::vector<PageItem>& items, std::vector<INT32>& ids) {
    for (const PageItem& item : items) {
        UINT id = MENU_FIRST_PAGE_ITEM + static_cast<UINT>(ids.size());
        AppendMenuW(menu, MF_STRING | (item.enabled ? 0 : MF_GRAYED), id, item.label.c_str());
        ids.push_back(item.id);
    }
}

}  // namespace

void Editor::ShowMenu() {
    Microsoft::WRL::ComPtr<ICoreWebView2ContextMenuRequestedEventArgs> args = std::move(menuArgs_);
    Microsoft::WRL::ComPtr<ICoreWebView2Deferral> deferral = std::move(menuDeferral_);
    if (!args || !deferral) {
        return;
    }
    Microsoft::WRL::ComPtr<ICoreWebView2ContextMenuItemCollection> items;
    std::vector<PageItem> spelling, editing;
    if (SUCCEEDED(args->get_MenuItems(&items)) && items) {
        PageItems(items.Get(), spelling, editing);
    }
    // on a link Open Link, Edit Link and Remove Link first
    Microsoft::WRL::ComPtr<ICoreWebView2ContextMenuTarget> target;
    BOOL onLink = FALSE;
    std::wstring link;
    if (SUCCEEDED(args->get_ContextMenuTarget(&target)) && SUCCEEDED(target->get_HasLinkUri(&onLink)) && onLink) {
        LPWSTR uri = nullptr;
        target->get_LinkUri(&uri);
        link = uri ? uri : L"";
        CoTaskMemFree(uri);
    }
    HMENU menu = CreatePopupMenu();
    if (onLink) {
        AppendMenuW(menu, MF_STRING, MENU_OPEN_LINK, core::T(PE_TEXT_UI_OPEN_LINK).c_str());
        AppendMenuW(menu, MF_STRING, MENU_EDIT_LINK, core::T(PE_TEXT_UI_EDIT_LINK).c_str());
        AppendMenuW(menu, MF_STRING, MENU_REMOVE_LINK, core::T(PE_TEXT_UI_REMOVE_LINK).c_str());
    }
    std::vector<INT32> ids;
    for (const std::vector<PageItem>* group : {&spelling, &editing}) {
        if (!group->empty() && GetMenuItemCount(menu) > 0) {
            AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
        }
        AppendPageItems(menu, *group, ids);
    }
    POINT at = {};
    args->get_Location(&at);
    ClientToScreen(host_, &at);
    UINT chosen = GetMenuItemCount(menu) > 0
                      ? TrackPopupMenu(menu, TPM_RETURNCMD | TPM_RIGHTBUTTON, at.x, at.y, 0, GetAncestor(host_, GA_ROOT), nullptr)
                      : 0;
    DestroyMenu(menu);
    if (chosen >= MENU_FIRST_PAGE_ITEM && chosen - MENU_FIRST_PAGE_ITEM < ids.size()) {
        args->put_SelectedCommandId(ids[chosen - MENU_FIRST_PAGE_ITEM]);
    }
    deferral->Complete();
    if (chosen == MENU_OPEN_LINK) {
        webview::OpenExternally(link.c_str());
    } else if (chosen == MENU_EDIT_LINK) {
        handlers_.editLink();
    } else if (chosen == MENU_REMOVE_LINK) {
        Link(L"");
    }
}

std::vector<std::wstring> Editor::DroppedFiles(ICoreWebView2WebMessageReceivedEventArgs* args) {
    // the File objects of the page's message: the paths of the files dropped, nothing of their content
    std::vector<std::wstring> paths;
    Microsoft::WRL::ComPtr<ICoreWebView2WebMessageReceivedEventArgs2> withObjects;
    Microsoft::WRL::ComPtr<ICoreWebView2ObjectCollectionView> objects;
    UINT32 count = 0;
    if (FAILED(args->QueryInterface(IID_PPV_ARGS(&withObjects))) || FAILED(withObjects->get_AdditionalObjects(&objects)) || !objects ||
        FAILED(objects->get_Count(&count))) {
        return paths;
    }
    for (UINT32 i = 0; i < count; i++) {
        Microsoft::WRL::ComPtr<IUnknown> object;
        Microsoft::WRL::ComPtr<ICoreWebView2File> file;
        LPWSTR path = nullptr;
        if (SUCCEEDED(objects->GetValueAtIndex(i, &object)) && object && SUCCEEDED(object.As(&file)) && SUCCEEDED(file->get_Path(&path)) && path) {
            paths.emplace_back(path);
            CoTaskMemFree(path);
        }
    }
    return paths;
}

void Editor::Script(const std::wstring& code) {
    if (view_) {
        view_->ExecuteScript(code.c_str(), nullptr);
    }
}

void Editor::Exec(const wchar_t* command, const std::wstring& value) {
    Script(L"pe.exec(" + JsString(command) + L"," + JsString(value) + L")");
}

void Editor::Link(const std::wstring& url) {
    Script(L"pe.link(" + JsString(url) + L")");
}

void Editor::Signature(const std::wstring& block) {
    Script(L"pe.signature(" + JsString(block) + L")");
}

void Editor::Html() {
    Script(L"pe.send()");
}

void Editor::Clean() {
    Script(L"pe.clean()");
}

void Editor::Focus() {
    if (!controller_) {
        focusWhenReady_ = true;
        return;
    }
    controller_->MoveFocus(COREWEBVIEW2_MOVE_FOCUS_REASON_PROGRAMMATIC);
    Script(L"window.pe && pe.focus()");
}

void Editor::Resize(const RECT& bounds) {
    MoveWindow(host_, bounds.left, bounds.top, bounds.right - bounds.left, bounds.bottom - bounds.top, TRUE);
    if (controller_) {
        RECT inner;
        GetClientRect(host_, &inner);
        controller_->put_Bounds(inner);
    }
}

void Editor::Close() {
    if (controller_) {
        controller_->Close();
    }
    view_.Reset();
    controller_.Reset();
    environment_.Reset();
}
