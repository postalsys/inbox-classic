// The reading pane's stack of a message or a conversation (stack.h): its rows and headers drawn here, its buttons push
// buttons, each open message's body a WebView2 of its own in a window of its own, moved as the stack scrolls. The
// wheel over a body scrolls the stack (a body is as tall as its document): WebView2 keeps the wheel for itself, so a
// low-level mouse hook, set while a stack with bodies is shown, hands the wheel over the stack to it instead (and tells
// it of a click in a body, which may open a folded "..." and so change the body's height).
#include "stack.h"

#include <windowsx.h>

#include "app.h"

#include <algorithm>
#include <cmath>

namespace {

constexpr wchar_t kClass[] = L"InboxClassicStack";
// the geometry at 96 DPI: the margins, the room between the items, a row's height, a frame's header (without and with
// the line saying where it is filed), the gap's row
constexpr int kMargin = 8;
constexpr int kSpacing = 6;
constexpr int kRow = 28;
constexpr int kHeader = 44;
constexpr int kFoundIn = 18;
constexpr int kGapRow = 22;
constexpr int kArrow = 20;
constexpr int kRowPicture = 20;
constexpr int kFramePicture = 32;
constexpr int kButtonHeight = 23;
// a body before it was measured
constexpr int kBodyDefault = 120;
// the stack's own messages: the wheel the hook took (wParam the delta), a click the hook saw (lParam the window under
// it), the layout for the heights measured in one tick; and the measuring timer
constexpr UINT kWheel = WM_APP + 41;
constexpr UINT kClicked = WM_APP + 42;
constexpr UINT kPlace = WM_APP + 43;
constexpr UINT_PTR kMeasureTimer = 1;
// a body measured every tick (400 ms) while its pictures arrive, then every 5th; settled after 5 slow readings in a row
// found the same height, or after a minute of them in any case
constexpr int kFastTicks = 15;
constexpr int kSlowEvery = 5;
constexpr int kSteadyReadings = 5;
constexpr int kGiveUpTicks = kFastTicks + kSlowEvery * 30;

// the stacks shown, for the wheel hook
std::vector<HWND> g_stacks;
HHOOK g_hook = nullptr;

void DrawLine(HDC dc, const std::wstring& text, RECT box, UINT format) {
    DrawTextW(dc, text.c_str(), static_cast<int>(text.size()), &box, format | DT_SINGLELINE | DT_NOPREFIX | DT_VCENTER);
}

int LineWidth(HDC dc, HFONT font, const std::wstring& text) {
    return static_cast<int>(Measure(dc, font, text, 0, DT_NOPREFIX).cx);
}

}  // namespace

ConversationStack::ConversationStack() : pictures_(std::make_unique<ListPictures>()) {}

ConversationStack::~ConversationStack() = default;

ConversationStack::Entry ConversationStack::Copy(const PeConversationEntry& e) {
    Entry entry;
    entry.folder = e.folder;
    entry.uid = e.uid;
    entry.index = e.index;
    entry.from = Text(e.from);
    entry.when = Text(e.when);
    entry.words = Text(e.words);
    entry.to = Text(e.to);
    entry.inFolder = Text(e.in_folder);
    entry.foundIn = Text(e.found_in);
    entry.note = Text(e.note);
    entry.reactions = Text(e.reactions);
    entry.initials = Text(e.initials);
    entry.hiddenText = Text(e.hidden_text);
    entry.date = e.date;
    entry.draft = e.draft;
    entry.unread = e.unread;
    entry.open = e.open;
    entry.selected = e.selected;
    entry.attachments = e.attachments;
    entry.picture = e.picture;
    entry.hiddenBefore = e.hidden_before;
    return entry;
}

void ConversationStack::Create(HWND parent, PeCore* core, Hooks hooks) {
    core_ = core;
    hooks_ = std::move(hooks);
    pictures_->Init(core);
    static bool registered = false;
    if (!registered) {
        WNDCLASSW type = {};
        type.lpfnWndProc = Proc;
        type.hInstance = GetModuleHandleW(nullptr);
        type.hCursor = LoadCursorW(nullptr, IDC_ARROW);
        type.lpszClassName = kClass;
        type.style = CS_DBLCLKS;
        RegisterClassW(&type);
        registered = true;
    }
    hwnd_ = CreateWindowExW(WS_EX_CONTROLPARENT, kClass, L"", WS_CHILD | WS_VSCROLL | WS_TABSTOP | WS_CLIPCHILDREN | WS_CLIPSIBLINGS, 0, 0,
                            0, 0, parent, nullptr, GetModuleHandleW(nullptr), this);
    LOGFONTW font = {};
    GetObjectW(UiFont(), sizeof(font), &font);
    font.lfWeight = FW_BOLD;
    bold_ = CreateFontIndirectW(&font);
    font.lfHeight = font.lfHeight * 5 / 4;
    title_ = CreateFontIndirectW(&font);
}

void ConversationStack::Destroy() {
    // the hook let go with the frames
    Clear();
    if (pictureDc_) {
        DeleteDC(pictureDc_);
        pictureDc_ = nullptr;
    }
    pictures_->Clear();
    DeleteObject(bold_);
    DeleteObject(title_);
    bold_ = title_ = nullptr;
}

void ConversationStack::Show(PeMessageView* view, bool pictures, bool start) {
    view_ = view;
    const PeMessageInfo* info = pe_message_view_info(view);
    if (!info) {
        Clear();
        return;
    }
    conversation_ = info->conversation_count > 0;
    subject_ = Text(conversation_ ? info->conversation_subject : info->subject);
    summary_ = Text(info->conversation_line);
    // the frames of messages no longer open let go (after the new ones are in); their buttons made again for each one
    std::map<Key, Frame> kept;
    for (auto& [key, frame] : frames_) {
        for (auto& [button, command] : frame.buttons) {
            DestroyWindow(button);
        }
        frame.buttons.clear();
    }
    std::vector<Row> rows;
    std::vector<Gap> gaps;
    std::vector<Item> items;
    // a message alone too is the core's one entry, its key 0, 0
    for (size_t place = 0; place < info->conversation_entry_count; place++) {
        const PeConversationEntry* given = pe_conversation_entry(view, place);
        if (!given) {
            continue;
        }
        Entry entry = Copy(*given);
        if (entry.hiddenBefore > 0) {
            gaps.push_back({entry.index, entry.hiddenText, {}});
            items.push_back({Item::GapItem, {0, 0}, gaps.size() - 1});
        }
        if (!entry.open) {
            rows.push_back({entry, {}});
            items.push_back({Item::RowItem, {0, 0}, rows.size() - 1});
            continue;
        }
        Key key{entry.folder, entry.uid};
        Frame frame;
        if (auto found = frames_.find(key); found != frames_.end()) {
            frame = std::move(found->second);
            frames_.erase(found);
        }
        PeMessageView* own = const_cast<PeMessageView*>(pe_conversation_entry_view(view, place));
        const PeMessageInfo* shown = pe_message_view_info(own);
        std::wstring document = shown ? Text(shown->document) : L"";
        std::wstring token = shown && shown->preview_token ? Text(shown->preview_token) : L"";
        bool allowed = entry.selected && pictures;
        // another document (the next message alone, its pictures now, built again, its previews under the new view's
        // token): loaded into the WebView2 there
        bool changed = document != frame.document || token != frame.token || allowed != frame.pictures;
        frame.entry = entry;
        frame.view = own;
        frame.document = std::move(document);
        frame.token = std::move(token);
        frame.pictures = allowed;
        if (frame.body && changed && shown) {
            LoadBody(frame, shown);
        }
        // a frame not selected names its files under its body; a click selects it, and its strip offers them
        frame.files.clear();
        for (size_t i = 0; !entry.selected && entry.attachments && shown && i < shown->attachment_count; i++) {
            if (const PeAttachment* file = pe_message_view_attachment(own, i)) {
                frame.files += (frame.files.empty() ? L"" : L", ") + Text(file->filename);
            }
        }
        // its buttons: Reply, Reply All, Forward and More; a draft's Edit and More
        std::vector<std::pair<std::wstring, WORD>> buttons;
        if (entry.draft) {
            buttons.push_back({core::T(PE_TEXT_UI_CONVERSATION_EDIT), WORD{0}});
        } else {
            buttons.push_back({core::T(PE_TEXT_UI_TB_REPLY), WORD{IDM_REPLY}});
            buttons.push_back({core::T(PE_TEXT_UI_TB_REPLY_ALL), WORD{IDM_REPLY_ALL}});
            buttons.push_back({core::T(PE_TEXT_UI_TB_FORWARD), WORD{IDM_FORWARD}});
        }
        buttons.push_back({core::T(PE_TEXT_UI_CONVERSATION_MORE) + L" \x25BE", WORD{1}});
        for (auto& [label, command] : buttons) {
            HWND button = CreateChild(hwnd_, L"BUTTON", label.c_str(), WS_TABSTOP | BS_PUSHBUTTON, nextId_, {});
            frame.buttons.push_back({button, command});
            nextId_ = nextId_ >= 30000 ? 100 : nextId_ + 1;
        }
        kept.emplace(key, std::move(frame));
        items.push_back({Item::FrameItem, key, 0});
    }
    // what is shown taken in at once, so nothing drawn or laid out meanwhile finds a frame missing; the frames no
    // longer open let go after
    std::swap(frames_, kept);
    rows_ = std::move(rows);
    gaps_ = std::move(gaps);
    items_ = std::move(items);
    hot_ = -1;
    for (auto& [key, frame] : kept) {
        LetGo(frame);
    }
    if (start) {
        scroll_ = 0;
    }
    Layout();
    if (start) {
        if (Frame* selected = SelectedFrame()) {
            ScrollTo(selected->rect.top - Scale(kMargin));
        }
    }
    Live();
    InvalidateRect(hwnd_, nullptr, FALSE);
    if (std::find(g_stacks.begin(), g_stacks.end(), hwnd_) == g_stacks.end()) {
        g_stacks.push_back(hwnd_);
    }
    if (!g_hook) {
        g_hook = SetWindowsHookExW(WH_MOUSE_LL, MouseHook, GetModuleHandleW(nullptr), 0);
    }
}

void ConversationStack::Clear() {
    KillTimer(hwnd_, kMeasureTimer);
    for (auto& [key, frame] : frames_) {
        LetGo(frame);
        for (auto& [button, command] : frame.buttons) {
            DestroyWindow(button);
        }
    }
    frames_.clear();
    rows_.clear();
    gaps_.clear();
    items_.clear();
    view_ = nullptr;
    conversation_ = false;
    scroll_ = 0;
    std::erase(g_stacks, hwnd_);
    if (g_stacks.empty() && g_hook) {
        UnhookWindowsHookEx(g_hook);
        g_hook = nullptr;
    }
}

void ConversationStack::Move(const RECT& bounds) {
    MoveWindow(hwnd_, bounds.left, bounds.top, bounds.right - bounds.left, bounds.bottom - bounds.top, TRUE);
}

void ConversationStack::SetVisible(bool visible) {
    ShowWindow(hwnd_, visible ? SW_SHOW : SW_HIDE);
}

ConversationStack::Frame* ConversationStack::SelectedFrame() {
    for (auto& [key, frame] : frames_) {
        if (frame.entry.selected) {
            return &frame;
        }
    }
    return nullptr;
}

int64_t ConversationStack::TestPreviews(const std::wstring& query) {
    Frame* frame = SelectedFrame();
    if (!frame || !frame->body) {
        return -1;
    }
    int bodyTop = frame->rect.top + frame->bodyTop;
    if (query == L"scroll" || query.starts_with(L"scroll:")) {
        if (query.size() > 7) {
            ScrollTo(bodyTop + _wtoi(query.c_str() + 7));
        }
        return std::max(0, scroll_ - bodyTop) + 1;
    }
    int64_t answer = frame->body->TestPreviews(query);
    bool point = answer > 0 && query != L"state" && query != L"overflow" && query != L"tiles" && query != L"inline" &&
                 !query.starts_with(L"text:") && !query.starts_with(L"part:") && !query.starts_with(L"partframe:") && query != L"menu";
    if (point) {
        RECT client;
        GetClientRect(hwnd_, &client);
        POINT origin = {0, 0};
        ClientToScreen(hwnd_, &origin);
        int y = static_cast<int>(answer % 100000) - origin.y;
        if (y < Scale(8) || y > client.bottom - Scale(8)) {
            ScrollTo(scroll_ + y - (client.bottom - client.top) / 2);
            return -1;
        }
    }
    return answer;
}

Preview* ConversationStack::SelectedBody() {
    Frame* frame = SelectedFrame();
    return frame ? frame->body.get() : nullptr;
}

void ConversationStack::Layout() {
    RECT client;
    GetClientRect(hwnd_, &client);
    int width = client.right - client.left;
    int left = Scale(kMargin), inner = std::max(0, width - 2 * Scale(kMargin));
    int y = Scale(kMargin);
    // the title: the subject, and under it how many messages and who wrote
    HDC dc = GetDC(hwnd_);
    HGDIOBJ old = SelectObject(dc, title_);
    TEXTMETRICW metrics = {};
    GetTextMetricsW(dc, &metrics);
    int titleLine = metrics.tmHeight;
    SelectObject(dc, UiFont());
    GetTextMetricsW(dc, &metrics);
    SelectObject(dc, old);
    ReleaseDC(hwnd_, dc);
    titleHeight_ = titleLine + (summary_.empty() ? 0 : metrics.tmHeight + Scale(2));
    y += titleHeight_ + Scale(kSpacing + 2);
    for (const Item& item : items_) {
        switch (item.kind) {
        case Item::GapItem: {
            Gap& gap = gaps_[item.place];
            gap.rect = {left, y, left + inner, y + Scale(kGapRow)};
            y = gap.rect.bottom + Scale(kSpacing);
            break;
        }
        case Item::RowItem: {
            Row& row = rows_[item.place];
            row.rect = {left, y, left + inner, y + Scale(kRow)};
            // rows next to each other touch: one box, a line between them
            y = row.rect.bottom;
            bool nextIsRow = &item != &items_.back() && (&item + 1)->kind == Item::RowItem;
            if (!nextIsRow) {
                y += Scale(kSpacing);
            }
            break;
        }
        case Item::FrameItem: {
            auto found = frames_.find(item.key);
            if (found == frames_.end()) {
                break;
            }
            Frame& frame = found->second;
            frame.header = Scale(kHeader) + (frame.entry.foundIn.empty() ? 0 : Scale(kFoundIn));
            int top = y;
            int inside = top + frame.header;
            // its buttons at the right of its header
            int right = left + inner - Scale(6);
            int buttonTop = top + frame.header - Scale(kHeader) + (Scale(kHeader) - Scale(kButtonHeight)) / 2 - scroll_;
            for (auto it = frame.buttons.rbegin(); it != frame.buttons.rend(); ++it) {
                int buttonWidth = ButtonWidth({GetWindowString(it->first)}, Scale(56));
                right -= buttonWidth;
                MoveWindow(it->first, right, buttonTop, buttonWidth, Scale(kButtonHeight), TRUE);
                right -= Scale(4);
            }
            // the selected one's paper clip left of its buttons
            if (frame.entry.selected && hooks_.placeClip) {
                if (int clip = hooks_.placeClip(right, buttonTop + Scale(kButtonHeight) / 2); clip > 0) {
                    right -= clip + Scale(4);
                }
            }
            // the selected one's Reactions line under its header
            if (frame.entry.selected && hooks_.placeReactions) {
                inside += hooks_.placeReactions(left + Scale(kArrow + kFramePicture + 10), inside - scroll_, inner - Scale(kArrow + kFramePicture + 16));
            }
            // its files under its header, before its body, as Tab reaches them
            if (frame.entry.selected && hooks_.placeFiles) {
                int files = hooks_.placeFiles(left + Scale(4), inside - scroll_ + Scale(2), inner - Scale(8));
                if (files > 0) {
                    inside += files + Scale(4);
                }
            }
            frame.bodyTop = inside - top;
            int body = frame.height > 0 ? frame.height : Scale(kBodyDefault);
            if (frame.host) {
                MoveWindow(frame.host, left + Scale(4), inside - scroll_, std::max(0, inner - Scale(8)), body, TRUE);
                RECT hostClient;
                GetClientRect(frame.host, &hostClient);
                if (frame.body) {
                    frame.body->Resize(hostClient);
                }
            }
            inside += body + Scale(4);
            frame.rect = {left, top, left + inner, inside};
            y = inside + Scale(kSpacing);
            break;
        }
        }
    }
    total_ = y + Scale(kMargin);
    SCROLLINFO scroll = {sizeof(scroll), SIF_RANGE | SIF_PAGE | SIF_POS};
    scroll.nMin = 0;
    scroll.nMax = std::max(0, total_ - 1);
    scroll.nPage = static_cast<UINT>(std::max(0L, client.bottom - client.top));
    scroll_ = std::clamp(scroll_, 0, std::max(0, total_ - static_cast<int>(scroll.nPage)));
    scroll.nPos = scroll_;
    SetScrollInfo(hwnd_, SB_VERT, &scroll, TRUE);
}

void ConversationStack::PlaceChildren() {
    Layout();
    // the frames and their buttons drawn again together, so nothing is left where a button was before (the bodies'
    // WebView2 windows are not touched: they draw themselves)
    InvalidateRect(hwnd_, nullptr, FALSE);
    for (auto& [key, frame] : frames_) {
        for (auto& [button, command] : frame.buttons) {
            InvalidateRect(button, nullptr, TRUE);
        }
    }
}

void ConversationStack::ScrollTo(int y) {
    RECT client;
    GetClientRect(hwnd_, &client);
    int most = std::max(0, total_ - static_cast<int>(client.bottom - client.top));
    int to = std::clamp(y, 0, most);
    if (to == scroll_) {
        return;
    }
    scroll_ = to;
    PlaceChildren();
    Live();
    UpdateWindow(hwnd_);
}

void ConversationStack::Live() {
    RECT client;
    GetClientRect(hwnd_, &client);
    int page = std::max(400, static_cast<int>(client.bottom - client.top));
    int top = scroll_ - 2 * page, bottom = scroll_ + 3 * page;
    bool made = false;
    for (auto& [key, frame] : frames_) {
        bool soon = frame.entry.selected || (frame.rect.bottom >= top && frame.rect.top <= bottom);
        if (soon && !frame.body) {
            MakeBody(frame);
            made = true;
        } else if (!soon && frame.body) {
            LetGo(frame);
        }
    }
    if (made) {
        Layout();
    }
}

void ConversationStack::MakeBody(Frame& frame) {
    const PeMessageInfo* info = pe_message_view_info(frame.view);
    if (!info) {
        return;
    }
    frame.host = CreateChild(hwnd_, L"STATIC", nullptr, WS_CLIPCHILDREN | WS_CLIPSIBLINGS, 0, {});
    frame.body = std::make_unique<Preview>();
    frame.body->ServePreviews(core_);
    // Alt and a letter from the message reach its window's buttons (the security bar's Details), as from the pane's
    frame.body->TakeMnemonics();
    HWND host = frame.host;
    frame.body->Create(host, [host](const std::wstring& error) { SetWindowTextW(host, error.c_str()); }, GetAncestor(hwnd_, GA_ROOT),
                       hooks_.findTimer);
    if (hooks_.links) {
        frame.body->SetLinks(hooks_.links);
    }
    if (hooks_.keys) {
        frame.body->SetKeys(hooks_.keys);
    }
    // a click in the body (it takes the keyboard): its message selected
    Key key{frame.entry.folder, frame.entry.uid};
    frame.body->OnFocus([this, key]() {
        auto found = frames_.find(key);
        if (found != frames_.end() && !found->second.entry.selected && hooks_.click) {
            size_t index = found->second.entry.index;
            // after the WebView2's event
            PostMessageW(hwnd_, WM_COMMAND, MAKEWPARAM(0, 0), static_cast<LPARAM>(index) + 1);
        }
    });
    // View > Text Size: its height changes with it
    frame.body->OnZoom([this, key]() {
        if (auto found = frames_.find(key); found != frames_.end()) {
            Unsettle(found->second);
        }
    });
    LoadBody(frame, info);
}

void ConversationStack::LoadBody(Frame& frame, const PeMessageInfo* info) {
    std::vector<std::string> parts;
    for (size_t i = 0; i < info->part_count; i++) {
        const char* part = pe_message_view_part(frame.view, i);
        parts.emplace_back(part ? part : "");
    }
    frame.body->Show(frame.document, frame.pictures || info->pictures_loaded, std::move(parts), info->preview_token);
    Unsettle(frame);
}

void ConversationStack::Unsettle(Frame& frame) {
    frame.measured = 0;
    frame.steady = 0;
    frame.settled = false;
    SetTimer(hwnd_, kMeasureTimer, 400, nullptr);
}

void ConversationStack::LetGo(Frame& frame) {
    if (frame.body) {
        frame.body->Close();
        frame.body.reset();
    }
    if (frame.host) {
        DestroyWindow(frame.host);
        frame.host = nullptr;
    }
}

void ConversationStack::MeasureBodies() {
    bool measuring = false;
    for (auto& [key, frame] : frames_) {
        if (!frame.body || frame.settled) {
            continue;
        }
        // every tick while its pictures arrive, then every 5th, until its height stays the same a while (a body whose
        // readings never come, its WebView2 not made, given up after a minute)
        int tick = frame.measured++;
        if (tick >= kGiveUpTicks) {
            frame.settled = true;
            continue;
        }
        measuring = true;
        bool slow = tick >= kFastTicks;
        if (slow && tick % kSlowEvery != 0) {
            continue;
        }
        Key at = key;
        frame.body->MeasureHeight([this, at, slow](int pixels) {
            auto found = frames_.find(at);
            if (found == frames_.end()) {
                return;
            }
            Frame& measured = found->second;
            int height = std::max(Scale(48), pixels);
            if (std::abs(height - measured.height) < 2) {
                measured.settled = slow && ++measured.steady >= kSteadyReadings;
                return;
            }
            measured.steady = 0;
            measured.height = height;
            // the heights read in one tick laid out once
            if (!std::exchange(placePosted_, true)) {
                PostMessageW(hwnd_, kPlace, 0, 0);
            }
        });
    }
    if (!measuring) {
        KillTimer(hwnd_, kMeasureTimer);
    }
}

const ConversationStack::Entry* ConversationStack::Hit(POINT point, bool* arrow, bool* gap) {
    int y = point.y + scroll_;
    if (arrow) {
        *arrow = false;
    }
    if (gap) {
        *gap = false;
    }
    for (const Gap& g : gaps_) {
        if (y >= g.rect.top && y < g.rect.bottom) {
            if (gap) {
                *gap = true;
            }
            static Entry entry;
            entry.index = g.index;
            return &entry;
        }
    }
    for (const Row& row : rows_) {
        if (y >= row.rect.top && y < row.rect.bottom && point.x >= row.rect.left && point.x < row.rect.right) {
            if (arrow) {
                *arrow = point.x < row.rect.left + Scale(kArrow + 4);
            }
            return &row.entry;
        }
    }
    for (const auto& [key, frame] : frames_) {
        if (y >= frame.rect.top && y < frame.rect.bottom && point.x >= frame.rect.left && point.x < frame.rect.right) {
            int header = frame.rect.top + frame.header;
            if (arrow) {
                *arrow = y < header && point.x < frame.rect.left + Scale(kArrow + 4);
            }
            return &frame.entry;
        }
    }
    return nullptr;
}

void ConversationStack::Click(POINT point, bool twice) {
    bool arrow = false, gap = false;
    const Entry* entry = Hit(point, &arrow, &gap);
    if (!entry || !hooks_.click) {
        return;
    }
    if (gap) {
        hooks_.click(PE_CONVERSATION_CLICK_SHOW_MIDDLE, entry->index);
        return;
    }
    if (twice && hooks_.openWindow) {
        hooks_.openWindow(entry->folder, entry->uid);
        return;
    }
    // a message alone has no arrow
    if (arrow && conversation_) {
        hooks_.click(PE_CONVERSATION_CLICK_TOGGLE, entry->index);
    } else if (!entry->selected && conversation_) {
        hooks_.click(PE_CONVERSATION_CLICK_SELECT, entry->index);
    }
}

void ConversationStack::SetSelectedPicture(HBITMAP bitmap, int size) {
    selectedPicture_ = bitmap;
    selectedPictureSize_ = size;
    InvalidateRect(hwnd_, nullptr, FALSE);
}

void ConversationStack::InvalidateRow(int row) {
    if (row < 0 || static_cast<size_t>(row) >= rows_.size()) {
        return;
    }
    RECT box = rows_[row].rect;
    OffsetRect(&box, 0, -scroll_);
    InvalidateRect(hwnd_, &box, FALSE);
}

void ConversationStack::PaintPicture(HDC dc, const RECT& box, const Entry& entry) {
    int size = box.right - box.left;
    if (entry.selected && selectedPicture_ && selectedPictureSize_ > 0) {
        if (!pictureDc_) {
            pictureDc_ = CreateCompatibleDC(dc);
        }
        HGDIOBJ old = SelectObject(pictureDc_, selectedPicture_);
        BLENDFUNCTION blend = {AC_SRC_OVER, 0, 255, AC_SRC_ALPHA};
        AlphaBlend(dc, box.left, box.top, size, size, pictureDc_, 0, 0, selectedPictureSize_, selectedPictureSize_, blend);
        SelectObject(pictureDc_, old);
        return;
    }
    // else its picture, or the initials, quiet, on a square a shade off the background, as the list draws them
    DrawSenderPicture(dc, box, pictures_->Get(entry.picture, size), pictureDc_, entry.initials, bold_,
                      MixColors(GetSysColor(COLOR_WINDOW), GetSysColor(COLOR_BTNFACE), 255), GetSysColor(COLOR_GRAYTEXT));
}

void ConversationStack::PaintRow(HDC dc, const Row& row, int offset, bool first, bool last) {
    RECT box = row.rect;
    OffsetRect(&box, 0, -offset);
    bool hot = hot_ >= 0 && static_cast<size_t>(hot_) < rows_.size() && &rows_[hot_] == &row;
    SetDCBrushColor(dc, hot ? MixColors(GetSysColor(COLOR_WINDOW), GetSysColor(COLOR_HIGHLIGHT), 24) : GetSysColor(COLOR_WINDOW));
    FillRect(dc, &box, static_cast<HBRUSH>(GetStockObject(DC_BRUSH)));
    // one box for the rows next to each other, a line between them
    HBRUSH edge = GetSysColorBrush(COLOR_BTNSHADOW);
    RECT side = {box.left, box.top, box.left + 1, box.bottom};
    FillRect(dc, &side, edge);
    side = {box.right - 1, box.top, box.right, box.bottom};
    FillRect(dc, &side, edge);
    RECT line = {box.left, box.top, box.right, box.top + 1};
    FillRect(dc, &line, first ? edge : GetSysColorBrush(COLOR_BTNFACE));
    if (last) {
        line = {box.left, box.bottom - 1, box.right, box.bottom};
        FillRect(dc, &line, edge);
    }
    const Entry& entry = row.entry;
    int x = box.left + Scale(4);
    // the arrow: folded
    DrawMarlettGlyph(dc, {x, box.top, x + Scale(kArrow), box.bottom}, L'4', Scale(12), GetSysColor(COLOR_GRAYTEXT));
    x += Scale(kArrow + 2);
    int picture = Scale(kRowPicture);
    PaintPicture(dc, {x, box.top + (box.bottom - box.top - picture) / 2, x + picture, box.top + (box.bottom - box.top - picture) / 2 + picture},
                 entry);
    x += picture + Scale(8);
    // the date at the right
    std::wstring date = entry.date > 0 ? ListDate(entry.date) : L"";
    HGDIOBJ old = SelectObject(dc, UiFont());
    int dateWidth = LineWidth(dc, UiFont(), date);
    int right = box.right - Scale(8) - dateWidth;
    SetTextColor(dc, GetSysColor(COLOR_GRAYTEXT));
    DrawLine(dc, date, {right, box.top, box.right - Scale(8), box.bottom}, DT_LEFT);
    right -= Scale(10);
    // the paper clip and the reactions before the date
    if (!entry.reactions.empty()) {
        int reactionsWidth = LineWidth(dc, UiFont(), entry.reactions);
        DrawLine(dc, entry.reactions, {right - reactionsWidth, box.top, right, box.bottom}, DT_LEFT);
        right -= reactionsWidth + Scale(8);
    }
    if (entry.attachments) {
        std::wstring clip = L"\U0001F4CE";
        int clipWidth = LineWidth(dc, UiFont(), clip);
        DrawLine(dc, clip, {right - clipWidth, box.top, right, box.bottom}, DT_LEFT);
        right -= clipWidth + Scale(8);
    }
    // the sender, bold while unread; where it is filed and its state; its first words
    HFONT nameFont = entry.unread ? bold_ : UiFont();
    SelectObject(dc, nameFont);
    SetTextColor(dc, GetSysColor(COLOR_WINDOWTEXT));
    int nameWidth = std::min(LineWidth(dc, nameFont, entry.from), std::max(0, (right - x) / 2));
    DrawLine(dc, entry.from, {x, box.top, x + nameWidth, box.bottom}, DT_LEFT | DT_END_ELLIPSIS);
    x += nameWidth + Scale(10);
    SelectObject(dc, UiFont());
    SetTextColor(dc, GetSysColor(COLOR_GRAYTEXT));
    for (const std::wstring& chip : {entry.inFolder, entry.note}) {
        if (chip.empty() || x >= right) {
            continue;
        }
        std::wstring words = L"[" + chip + L"]";
        int chipWidth = std::min(LineWidth(dc, UiFont(), words), right - x);
        DrawLine(dc, words, {x, box.top, x + chipWidth, box.bottom}, DT_LEFT | DT_END_ELLIPSIS);
        x += chipWidth + Scale(8);
    }
    if (x < right) {
        DrawLine(dc, entry.words, {x, box.top, right, box.bottom}, DT_LEFT | DT_END_ELLIPSIS);
    }
    SelectObject(dc, old);
}

void ConversationStack::PaintFrame(HDC dc, const Frame& frame, int offset) {
    RECT box = frame.rect;
    OffsetRect(&box, 0, -offset);
    bool selected = frame.entry.selected;
    SetDCBrushColor(dc, GetSysColor(COLOR_WINDOW));
    FillRect(dc, &box, static_cast<HBRUSH>(GetStockObject(DC_BRUSH)));
    // the classic look, no accent: the header of the selected message (and of a message alone) a gray bar as Outlook
    // Express's preview header, the others on white; a message of a conversation in a thin sunken box
    RECT header = {box.left, box.top, box.right, box.top + frame.header};
    if (selected || !conversation_) {
        FillRect(dc, &header, GetSysColorBrush(COLOR_BTNFACE));
    }
    if (conversation_ && selected) {
        DrawEdge(dc, &box, BDR_SUNKENOUTER, BF_RECT);
    } else if (conversation_) {
        FrameRect(dc, &box, GetSysColorBrush(COLOR_BTNSHADOW));
    }
    RECT line = {box.left + (conversation_ ? 1 : 0), header.bottom - 1, box.right - (conversation_ ? 1 : 0), header.bottom};
    FillRect(dc, &line, GetSysColorBrush(selected || !conversation_ ? COLOR_BTNSHADOW : COLOR_BTNFACE));
    const Entry& entry = frame.entry;
    int top = box.top;
    HGDIOBJ old = SelectObject(dc, UiFont());
    SetBkMode(dc, TRANSPARENT);
    if (!entry.foundIn.empty()) {
        SetTextColor(dc, GetSysColor(COLOR_GRAYTEXT));
        DrawLine(dc, entry.foundIn, {box.left + Scale(12), top + Scale(2), box.right - Scale(8), top + Scale(kFoundIn)}, DT_LEFT | DT_END_ELLIPSIS);
        top += Scale(kFoundIn);
    }
    int x = box.left + Scale(6);
    if (conversation_) {
        DrawMarlettGlyph(dc, {x, top, x + Scale(kArrow), top + Scale(kHeader)}, L'6', Scale(12), GetSysColor(COLOR_GRAYTEXT));
    }
    x += Scale(kArrow + 2);
    int picture = Scale(kFramePicture);
    int pictureTop = top + (Scale(kHeader) - picture) / 2;
    PaintPicture(dc, {x, pictureTop, x + picture, pictureTop + picture}, entry);
    x += picture + Scale(10);
    // the room left of its buttons
    int right = box.right - Scale(8);
    for (const auto& [button, command] : frame.buttons) {
        RECT place;
        GetWindowRect(button, &place);
        MapWindowPoints(nullptr, hwnd_, reinterpret_cast<POINT*>(&place), 2);
        right = std::min(right, static_cast<int>(place.left) - Scale(8));
    }
    int lineHeight = Scale(kHeader) / 2 - Scale(4);
    SelectObject(dc, bold_);
    SetTextColor(dc, GetSysColor(COLOR_WINDOWTEXT));
    DrawLine(dc, entry.from, {x, top + Scale(4), right, top + Scale(4) + lineHeight}, DT_LEFT | DT_END_ELLIPSIS);
    SelectObject(dc, UiFont());
    SetTextColor(dc, GetSysColor(COLOR_GRAYTEXT));
    std::wstring detail = entry.to;
    if (!entry.when.empty()) {
        detail += (detail.empty() ? L"" : L" \x00B7 ") + entry.when;
    }
    DrawLine(dc, detail, {x, top + Scale(4) + lineHeight, right, top + Scale(4) + 2 * lineHeight + Scale(2)}, DT_LEFT | DT_END_ELLIPSIS);
    // a frame not selected names its files under its body; a click selects it, and its strip offers them
    if (!selected && !frame.files.empty()) {
        DrawLine(dc, L"\U0001F4CE " + frame.files, {box.left + Scale(10), box.bottom - Scale(22), box.right - Scale(8), box.bottom - Scale(4)},
                 DT_LEFT | DT_END_ELLIPSIS);
    }
    SelectObject(dc, old);
}

void ConversationStack::Paint(HDC target, const RECT& dirty) {
    RECT client;
    GetClientRect(hwnd_, &client);
    // drawn off screen first, so scrolling does not flicker
    HDC dc = CreateCompatibleDC(target);
    HBITMAP bitmap = CreateCompatibleBitmap(target, client.right, client.bottom);
    HGDIOBJ oldBitmap = SelectObject(dc, bitmap);
    FillRect(dc, &client, GetSysColorBrush(COLOR_WINDOW));
    SetBkMode(dc, TRANSPARENT);
    int left = Scale(kMargin), right = client.right - Scale(kMargin);
    int y = Scale(kMargin) - scroll_;
    HGDIOBJ old = SelectObject(dc, title_);
    SetTextColor(dc, GetSysColor(COLOR_WINDOWTEXT));
    TEXTMETRICW metrics = {};
    GetTextMetricsW(dc, &metrics);
    DrawLine(dc, subject_, {left, y, right, y + metrics.tmHeight}, DT_LEFT | DT_END_ELLIPSIS);
    y += metrics.tmHeight + Scale(2);
    SelectObject(dc, UiFont());
    GetTextMetricsW(dc, &metrics);
    SetTextColor(dc, GetSysColor(COLOR_GRAYTEXT));
    DrawLine(dc, summary_, {left, y, right, y + metrics.tmHeight}, DT_LEFT | DT_END_ELLIPSIS);
    for (size_t i = 0; i < items_.size(); i++) {
        const Item& item = items_[i];
        switch (item.kind) {
        case Item::GapItem: {
            const Gap& gap = gaps_[item.place];
            RECT box = gap.rect;
            OffsetRect(&box, 0, -scroll_);
            SetTextColor(dc, GetSysColor(COLOR_HOTLIGHT));
            DrawLine(dc, gap.words, box, DT_CENTER);
            int words = LineWidth(dc, UiFont(), gap.words);
            int middle = (box.top + box.bottom) / 2;
            RECT before = {box.left, middle, (box.left + box.right - words) / 2 - Scale(8), middle + 1};
            RECT after = {(box.left + box.right + words) / 2 + Scale(8), middle, box.right, middle + 1};
            FillRect(dc, &before, GetSysColorBrush(COLOR_BTNFACE));
            FillRect(dc, &after, GetSysColorBrush(COLOR_BTNFACE));
            break;
        }
        case Item::RowItem: {
            bool first = i == 0 || items_[i - 1].kind != Item::RowItem;
            bool last = i + 1 == items_.size() || items_[i + 1].kind != Item::RowItem;
            PaintRow(dc, rows_[item.place], scroll_, first, last);
            break;
        }
        case Item::FrameItem:
            if (auto found = frames_.find(item.key); found != frames_.end()) {
                PaintFrame(dc, found->second, scroll_);
            }
            break;
        }
    }
    SelectObject(dc, old);
    BitBlt(target, dirty.left, dirty.top, dirty.right - dirty.left, dirty.bottom - dirty.top, dc, dirty.left, dirty.top, SRCCOPY);
    SelectObject(dc, oldBitmap);
    DeleteObject(bitmap);
    DeleteDC(dc);
}

void ConversationStack::PictureReady(uint64_t request) {
    if (pictures_->Ready(request)) {
        InvalidateRect(hwnd_, nullptr, FALSE);
    }
}

LRESULT CALLBACK ConversationStack::MouseHook(int code, WPARAM wParam, LPARAM lParam) {
    if (code == HC_ACTION && (wParam == WM_MOUSEWHEEL || wParam == WM_LBUTTONUP)) {
        const auto* mouse = reinterpret_cast<const MSLLHOOKSTRUCT*>(lParam);
        for (HWND stack : g_stacks) {
            if (!IsWindowVisible(stack) || GetForegroundWindow() != GetAncestor(stack, GA_ROOT)) {
                continue;
            }
            RECT place;
            GetWindowRect(stack, &place);
            HWND under = WindowFromPoint(mouse->pt);
            if (!PtInRect(&place, mouse->pt) || !under || (under != stack && !IsChild(stack, under))) {
                continue;
            }
            // a click: the body under it measured again, the click its own
            if (wParam == WM_LBUTTONUP) {
                PostMessageW(stack, kClicked, 0, reinterpret_cast<LPARAM>(under));
                break;
            }
            // over the stack, its bodies too (WebView2's windows are its children): the stack scrolls, not a body
            if (GetAsyncKeyState(VK_CONTROL) >= 0) {
                PostMessageW(stack, kWheel, static_cast<WPARAM>(static_cast<short>(HIWORD(mouse->mouseData))), 0);
                return 1;
            }
            break;
        }
    }
    return CallNextHookEx(g_hook, code, wParam, lParam);
}

LRESULT CALLBACK ConversationStack::Proc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {
    ConversationStack* stack = reinterpret_cast<ConversationStack*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
    if (message == WM_NCCREATE) {
        stack = static_cast<ConversationStack*>(reinterpret_cast<CREATESTRUCTW*>(lParam)->lpCreateParams);
        SetWindowLongPtrW(hwnd, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(stack));
        stack->hwnd_ = hwnd;
    }
    return stack ? stack->Handle(message, wParam, lParam) : DefWindowProcW(hwnd, message, wParam, lParam);
}

LRESULT ConversationStack::Handle(UINT message, WPARAM wParam, LPARAM lParam) {
    switch (message) {
    case WM_PAINT: {
        PAINTSTRUCT paint;
        HDC dc = BeginPaint(hwnd_, &paint);
        Paint(dc, paint.rcPaint);
        EndPaint(hwnd_, &paint);
        return 0;
    }
    case WM_ERASEBKGND:
        return 1;
    case WM_SIZE:
        PlaceChildren();
        Live();
        // the bodies as wide as the stack: their heights change with it
        if (int width = LOWORD(lParam); width != width_) {
            width_ = width;
            for (auto& [key, frame] : frames_) {
                if (frame.body) {
                    Unsettle(frame);
                }
            }
        }
        return 0;
    case WM_VSCROLL: {
        SCROLLINFO info = {sizeof(info), SIF_ALL};
        GetScrollInfo(hwnd_, SB_VERT, &info);
        int line = Scale(kRow), page = static_cast<int>(info.nPage);
        int to = scroll_;
        switch (LOWORD(wParam)) {
        case SB_LINEUP: to -= line; break;
        case SB_LINEDOWN: to += line; break;
        case SB_PAGEUP: to -= page; break;
        case SB_PAGEDOWN: to += page; break;
        case SB_THUMBTRACK:
        case SB_THUMBPOSITION: to = info.nTrackPos; break;
        case SB_TOP: to = 0; break;
        case SB_BOTTOM: to = total_; break;
        default: break;
        }
        ScrollTo(to);
        return 0;
    }
    case WM_MOUSEWHEEL:
    case kWheel: {
        int delta = message == kWheel ? static_cast<int>(static_cast<short>(wParam)) : GET_WHEEL_DELTA_WPARAM(wParam);
        UINT lines = 3;
        SystemParametersInfoW(SPI_GETWHEELSCROLLLINES, 0, &lines, 0);
        ScrollTo(scroll_ - delta * static_cast<int>(lines) * Scale(16) / WHEEL_DELTA);
        return 0;
    }
    case WM_LBUTTONDOWN:
        SetFocus(hwnd_);
        Click({GET_X_LPARAM(lParam), GET_Y_LPARAM(lParam)}, false);
        return 0;
    case WM_LBUTTONDBLCLK:
        Click({GET_X_LPARAM(lParam), GET_Y_LPARAM(lParam)}, true);
        return 0;
    case WM_MOUSEMOVE: {
        int y = GET_Y_LPARAM(lParam) + scroll_, hot = -1;
        for (size_t i = 0; i < rows_.size(); i++) {
            if (y >= rows_[i].rect.top && y < rows_[i].rect.bottom) {
                hot = static_cast<int>(i);
            }
        }
        if (hot != hot_) {
            InvalidateRow(std::exchange(hot_, hot));
            InvalidateRow(hot_);
            TRACKMOUSEEVENT track = {sizeof(track), TME_LEAVE, hwnd_, 0};
            TrackMouseEvent(&track);
        }
        return 0;
    }
    case WM_MOUSELEAVE:
        InvalidateRow(std::exchange(hot_, -1));
        return 0;
    case WM_GETDLGCODE:
        return DLGC_WANTARROWS;
    case WM_KEYDOWN:
        // Left and Right: every message folded but the selected one, or every one open, as Left and Right close and
        // open a conversation's row in the list; Up, Down, Page Up and Down, Home and End scroll
        if (hooks_.click && (wParam == VK_LEFT || wParam == VK_RIGHT)) {
            hooks_.click(wParam == VK_LEFT ? PE_CONVERSATION_CLICK_FOLD_ALL : PE_CONVERSATION_CLICK_OPEN_ALL, 0);
            return 0;
        }
        switch (wParam) {
        case VK_UP: return Handle(WM_VSCROLL, SB_LINEUP, 0);
        case VK_DOWN: return Handle(WM_VSCROLL, SB_LINEDOWN, 0);
        case VK_PRIOR: return Handle(WM_VSCROLL, SB_PAGEUP, 0);
        case VK_NEXT: return Handle(WM_VSCROLL, SB_PAGEDOWN, 0);
        case VK_HOME: return Handle(WM_VSCROLL, SB_TOP, 0);
        case VK_END: return Handle(WM_VSCROLL, SB_BOTTOM, 0);
        default: break;
        }
        if (hooks_.keys && hooks_.keys(static_cast<UINT>(wParam))) {
            return 0;
        }
        break;
    case WM_TIMER:
        if (wParam == kMeasureTimer) {
            MeasureBodies();
        }
        return 0;
    case kPlace:
        placePosted_ = false;
        PlaceChildren();
        return 0;
    case kClicked:
        // a click in a body may have opened or closed a folded "..."
        for (auto& [key, frame] : frames_) {
            HWND under = reinterpret_cast<HWND>(lParam);
            if (frame.body && frame.host && (under == frame.host || IsChild(frame.host, under))) {
                Unsettle(frame);
            }
        }
        return 0;
    case WM_COMMAND: {
        // a body took the keyboard (MakeBody posts it): its message selected
        if (LOWORD(wParam) == 0 && lParam > 0 && hooks_.click) {
            hooks_.click(PE_CONVERSATION_CLICK_SELECT, static_cast<size_t>(lParam - 1));
            return 0;
        }
        // a frame's button
        HWND from = reinterpret_cast<HWND>(lParam);
        for (auto& [key, frame] : frames_) {
            for (auto& [button, command] : frame.buttons) {
                if (button != from) {
                    continue;
                }
                const Entry& entry = frame.entry;
                if (command == 1 && hooks_.more) {
                    RECT place;
                    GetWindowRect(button, &place);
                    hooks_.more(entry.folder, entry.uid, {place.left, place.bottom});
                } else if (command == 0 && hooks_.edit) {
                    hooks_.edit(entry.folder, entry.uid);
                } else if (hooks_.command) {
                    hooks_.command(command, entry.folder, entry.uid);
                }
                return 0;
            }
        }
        // the selected frame's own (the strip, the Reactions line): to the window the reader is in
        return SendMessageW(GetParent(hwnd_), message, wParam, lParam);
    }
    case WM_NOTIFY:
    case WM_DRAWITEM:
    case WM_CTLCOLORSTATIC:
    case WM_CTLCOLORBTN:
    case WM_CONTEXTMENU:
        // the selected frame's own controls (the strip, the Reactions line): handled by the window the reader is in
        return SendMessageW(GetParent(hwnd_), message, wParam, lParam);
    default:
        break;
    }
    return DefWindowProcW(hwnd_, message, wParam, lParam);
}

int64_t ConversationStack::Test(const std::wstring& ask) {
    // the frames and rows in the stack's order, and the counts the UI test reads: frames, rows, bodies made, the selected
    // frame's place among the frames, whether every frame was measured (as tall as its document)
    std::vector<const Entry*> order;
    int64_t frames = 0, rows = 0, live = 0, selected = 0;
    bool tall = true;
    for (const Item& item : items_) {
        if (item.kind == Item::RowItem) {
            order.push_back(&rows_[item.place].entry);
            rows++;
            continue;
        }
        auto found = item.kind == Item::FrameItem ? frames_.find(item.key) : frames_.end();
        if (found == frames_.end()) {
            continue;
        }
        const Frame& frame = found->second;
        order.push_back(&frame.entry);
        frames++;
        live += frame.body ? 1 : 0;
        selected = frame.entry.selected ? frames : selected;
        tall = tall && frame.height > 0;
    }
    if (ask == L"shown") {
        return (tall && frames > 0 ? 1000 : 0) + frames * 100 + rows * 10 + selected;
    }
    if (ask == L"picture") {
        // whether the selected frame shows its message's own drawn picture (a brand's logo, a contact's picture)
        return selectedPicture_ && SelectedFrame() ? 1 : 0;
    }
    if (ask == L"frames" || ask == L"rows" || ask == L"gaps" || ask == L"live" || ask == L"selected") {
        return ask == L"frames" ? frames : ask == L"rows" ? rows : ask == L"gaps" ? static_cast<int64_t>(gaps_.size()) : ask == L"live" ? live : selected;
    }
    if (ask == L"middle") {
        if (gaps_.empty() || !hooks_.click) {
            return -1;
        }
        hooks_.click(PE_CONVERSATION_CLICK_SHOW_MIDDLE, gaps_.front().index);
        return 1;
    }
    // "<verb> <n>[ <rest>]"
    size_t space = ask.find(L' ');
    if (space == std::wstring::npos) {
        return -1;
    }
    std::wstring verb = ask.substr(0, space);
    std::wstring rest = ask.substr(space + 1);
    size_t number = static_cast<size_t>(_wtoi(rest.c_str()));
    size_t after = rest.find(L' ');
    std::wstring tail = after == std::wstring::npos ? L"" : rest.substr(after + 1);
    if (number >= order.size()) {
        return -1;
    }
    const Entry& entry = *order[number];
    if (verb == L"select" && hooks_.click) {
        hooks_.click(PE_CONVERSATION_CLICK_SELECT, entry.index);
        return 1;
    }
    if (verb == L"toggle" && hooks_.click) {
        hooks_.click(PE_CONVERSATION_CLICK_TOGGLE, entry.index);
        return 1;
    }
    if (verb == L"text") {
        auto found = frames_.find({entry.folder, entry.uid});
        return found != frames_.end() && found->second.document.find(tail) != std::wstring::npos ? 1 : 0;
    }
    if (verb == L"button") {
        auto found = frames_.find({entry.folder, entry.uid});
        if (found == frames_.end()) {
            return -1;
        }
        WORD wanted = tail == L"reply" ? IDM_REPLY : tail == L"replyall" ? IDM_REPLY_ALL : tail == L"forward" ? IDM_FORWARD : tail == L"edit" ? 0 : 1;
        for (auto& [button, command] : found->second.buttons) {
            if (command == wanted) {
                SendMessageW(button, BM_CLICK, 0, 0);
                return 1;
            }
        }
        return -1;
    }
    return -1;
}
