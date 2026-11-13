// The message list's rows in the Columns layout: three lines a message beside the reading pane. The same list view
// as the classic columns, its rows made tall by an image list of their height and drawn whole here in its custom draw:
// who and when, the subject and the marks, the first words of the message and a conversation's + or - box. Everything
// shown is what the core decoded; the snippet is the sender's text, drawn as text only.
#include "app.h"
#include "icons.h"

namespace {

// seconds east of UTC of the user's time zone, now
int64_t LocalOffset() {
    TIME_ZONE_INFORMATION zone = {};
    DWORD mode = GetTimeZoneInformation(&zone);
    LONG bias = zone.Bias;
    if (mode == TIME_ZONE_ID_DAYLIGHT) {
        bias += zone.DaylightBias;
    } else if (mode == TIME_ZONE_ID_STANDARD) {
        bias += zone.StandardBias;
    }
    return -static_cast<int64_t>(bias) * 60;
}

int64_t UnixNow() {
    FILETIME now;
    GetSystemTimeAsFileTime(&now);
    ULARGE_INTEGER ticks = {{now.dwLowDateTime, now.dwHighDateTime}};
    return static_cast<int64_t>(ticks.QuadPart / 10000000ULL) - 11644473600LL;
}

// a date in the user's format: `flags` of GetDateFormatEx, or the `picture`
std::wstring DatePart(const SYSTEMTIME& time, DWORD flags, const wchar_t* picture) {
    wchar_t text[96] = L"";
    GetDateFormatEx(LOCALE_NAME_USER_DEFAULT, flags, &time, picture, text, 96, nullptr);
    return text;
}

// a date as the Columns list writes it (pe_date_style): today's time, the weekday this week, the day and month this
// year, the whole date before
std::wstring ShortDate(int64_t seconds) {
    SYSTEMTIME local;
    if (!UnixToSystemTime(seconds, true, local)) {
        return {};
    }
    switch (pe_date_style(seconds, UnixNow(), LocalOffset())) {
    case PE_DATE_STYLE_TIME:
        return FormatTime(local);
    case PE_DATE_STYLE_WEEKDAY:
        return DatePart(local, 0, L"dddd");
    case PE_DATE_STYLE_DAY_MONTH:
#ifdef DATE_MONTHDAY
        return DatePart(local, DATE_MONTHDAY, nullptr);
#else
        return DatePart(local, 0, L"d MMM");
#endif
    default:
        return DatePart(local, DATE_SHORTDATE, nullptr);
    }
}

// what a row is painted with, and where its text goes
struct RowPaint {
    HDC dc;
    // the text's left and right edges, the first line's top and a line's height
    int left;
    int right;
    int top;
    int line;
    COLORREF fore;
    // the colour of what says less: the date, the folder, the snippet
    COLORREF faint;
};

// one line of text from `left` to `right` on line `n` (0 to 2) in `font`, cut short with an ellipsis; aligned right
// with `flush`. How wide it was drawn
int DrawLine(const RowPaint& paint, int n, int left, int right, const std::wstring& text, HFONT font, COLORREF color,
             bool flush = false) {
    if (text.empty() || right <= left) {
        return 0;
    }
    HGDIOBJ old = SelectObject(paint.dc, font);
    SetTextColor(paint.dc, color);
    RECT place = {left, paint.top + n * paint.line, right, paint.top + (n + 1) * paint.line};
    RECT measured = place;
    UINT flags = DT_SINGLELINE | DT_NOPREFIX | DT_END_ELLIPSIS | DT_VCENTER;
    DrawTextW(paint.dc, text.c_str(), static_cast<int>(text.size()), &measured, flags | DT_CALCRECT);
    DrawTextW(paint.dc, text.c_str(), static_cast<int>(text.size()), &place, flags | (flush ? DT_RIGHT : DT_LEFT));
    SelectObject(paint.dc, old);
    return std::min(static_cast<int>(measured.right - measured.left), right - left);
}

// how wide `text` is in `font`
int Width(HDC dc, HFONT font, const std::wstring& text) {
    HGDIOBJ old = SelectObject(dc, font);
    SIZE size = {};
    GetTextExtentPoint32W(dc, text.c_str(), static_cast<int>(text.size()), &size);
    SelectObject(dc, old);
    return size.cx;
}

// the unread dot in the gutter, centred on `x`, `y`
void DrawDot(HDC dc, int x, int y, int size, COLORREF color) {
    HBRUSH brush = CreateSolidBrush(color);
    HPEN pen = CreatePen(PS_SOLID, 1, color);
    HGDIOBJ oldBrush = SelectObject(dc, brush);
    HGDIOBJ oldPen = SelectObject(dc, pen);
    Ellipse(dc, x - size / 2, y - size / 2, x - size / 2 + size, y - size / 2 + size);
    SelectObject(dc, oldPen);
    SelectObject(dc, oldBrush);
    DeleteObject(pen);
    DeleteObject(brush);
}

// the marks of the second line from the right: the conversation's mark (watched or ignored), the flag in its colour,
// the paper clip or a bounce's mark. How wide they are together
int DrawMarks(const RowPaint& paint, const PeMessage& row, bool selected, HIMAGELIST strip, int iconSize) {
    std::vector<int> icons;
    if (row.mark == PE_THREAD_MARK_WATCH) {
        icons.push_back(LIST_GLASSES);
    } else if (row.mark == PE_THREAD_MARK_IGNORE) {
        icons.push_back(LIST_SPEAKER_MUTE);
    }
    if (row.flagged) {
        // the flag is drawn, not an icon of the strip
        icons.push_back(-1);
    }
    if (row.bounce) {
        icons.push_back(LIST_MAIL_ERROR);
    } else if (row.has_attachments) {
        icons.push_back(LIST_ATTACH);
    }
    int x = paint.right, gap = Scale(3);
    int top = paint.top + paint.line + (paint.line - iconSize) / 2;
    for (int icon : icons) {
        x -= iconSize;
        if (icon >= 0) {
            ImageList_Draw(strip, icon, paint.dc, x, top, ILD_TRANSPARENT);
        } else {
            if (selected) {
                // a plate of the list's own background under the flag, as the classic row has it
                HGDIOBJ oldBrush = SelectObject(paint.dc, GetSysColorBrush(COLOR_WINDOW));
                HGDIOBJ oldPen = SelectObject(paint.dc, GetStockObject(NULL_PEN));
                RoundRect(paint.dc, x, top, x + iconSize + 1, top + iconSize + 1, 4, 4);
                SelectObject(paint.dc, oldPen);
                SelectObject(paint.dc, oldBrush);
            }
            DrawFlag(paint.dc, x, top, iconSize, FlagRgb(row.flag_color ? row.flag_color : 1));
        }
        x -= gap;
    }
    return icons.empty() ? 0 : paint.right - x - gap;
}

}  // namespace

int Mailbox::ColumnsRowHeight() const {
    HDC dc = GetDC(list_);
    HGDIOBJ old = SelectObject(dc, bold_);
    TEXTMETRICW metrics = {};
    GetTextMetricsW(dc, &metrics);
    SelectObject(dc, old);
    ReleaseDC(list_, dc);
    return 3 * (metrics.tmHeight + Scale(2)) + Scale(10);
}

RECT Mailbox::ColumnsThreadBox(int index) const {
    RECT area = {LVIR_BOUNDS};
    SendMessageW(list_, LVM_GETITEMRECT, index, reinterpret_cast<LPARAM>(&area));
    RECT client;
    GetClientRect(list_, &client);
    // odd, so that the + and - are in its middle; in the middle of the third line, at the right
    int size = Scale(9) | 1, line = (area.bottom - area.top - Scale(10)) / 3;
    int right = client.right - Scale(8), middle = area.top + Scale(5) + 2 * line + line / 2;
    return {right - size, middle - size / 2, right, middle - size / 2 + size};
}

std::wstring Mailbox::ColumnsRowText(const PeMessage& row) const {
    std::vector<std::wstring> parts;
    if (row.bold) {
        parts.push_back(core::T(PE_TEXT_UI_ROW_UNREAD));
    }
    parts.push_back(recipientsColumn_ ? core::T(PE_TEXT_UI_COL_TO) + L": " + Text(row.recipients) : Text(row.from));
    parts.push_back(Text(row.subject));
    if (row.has_date) {
        parts.push_back(FormatDate(row.date));
    }
    if (row.flagged) {
        parts.push_back(core::T(PE_TEXT_UI_ROW_FLAGGED));
    }
    if (row.has_attachments) {
        parts.push_back(core::T(PE_TEXT_UI_ROW_ATTACHMENTS));
    }
    if (row.thread_opens) {
        parts.push_back(core::T(PE_TEXT_UI_ROW_MESSAGES, {{"count", std::to_wstring(row.thread_count)}}));
    }
    if (row.snippet && *row.snippet) {
        parts.push_back(Text(row.snippet));
    }
    std::wstring text;
    for (const std::wstring& part : parts) {
        text += (text.empty() ? L"" : L", ") + part;
    }
    return text;
}

void Mailbox::DrawColumnsRow(HDC dc, int index, const PeMessage& row) {
    RECT area = {LVIR_BOUNDS};
    SendMessageW(list_, LVM_GETITEMRECT, index, reinterpret_cast<LPARAM>(&area));
    RECT client;
    GetClientRect(list_, &client);
    area.left = client.left;
    area.right = client.right;
    bool selected = (ListView_GetItemState(list_, index, LVIS_SELECTED) & LVIS_SELECTED) != 0;
    bool active = GetFocus() == list_;
    COLORREF fore = GetSysColor(selected ? (active ? COLOR_HIGHLIGHTTEXT : COLOR_BTNTEXT) : row.dimmed ? COLOR_GRAYTEXT : COLOR_WINDOWTEXT);
    COLORREF faint = selected ? fore : GetSysColor(COLOR_GRAYTEXT);
    FillRect(dc, &area, GetSysColorBrush(selected ? SelectionColor() : COLOR_WINDOW));
    // a hairline between the rows, which are tall
    RECT rule = {area.left, area.bottom - 1, area.right, area.bottom};
    FillRect(dc, &rule, GetSysColorBrush(COLOR_BTNFACE));
    SetBkMode(dc, TRANSPARENT);
    int line = (area.bottom - area.top - Scale(10)) / 3;
    // a conversation's other messages under its first, indented; step 4 puts the sender's picture before the text
    int left = area.left + Scale(14) + (row.thread_depth > 0 ? Scale(16) : 0);
    RowPaint paint = {dc, left, area.right - Scale(8), area.top + Scale(5), line, fore, faint};
    if (row.bold) {
        DrawDot(dc, area.left + Scale(7), paint.top + line / 2, Scale(7), selected ? fore : GetSysColor(COLOR_HOTLIGHT));
    }
    HFONT font = RowFont(row);
    // who and when
    std::wstring date = row.has_date ? ShortDate(row.date) : L"";
    int dateWidth = DrawLine(paint, 0, paint.left, paint.right, date, normal_, faint, true);
    std::wstring who = recipientsColumn_ ? core::T(PE_TEXT_UI_COL_TO) + L": " + Text(row.recipients) : Text(row.from);
    DrawLine(paint, 0, paint.left, paint.right - dateWidth - Scale(10), who, font, fore);
    // the subject, the marks at the right (the folder before them in a list of several folders)
    int marks = DrawMarks(paint, row, selected, listIcons_, iconSize_);
    int folderRight = paint.right - marks - (marks ? Scale(6) : 0);
    int folderWidth = 0;
    if (SeveralFolders()) {
        std::wstring folder = RowFolder(row.folder);
        int widest = (folderRight - paint.left) * 2 / 5;
        int start = std::max(folderRight - Width(dc, normal_, folder), folderRight - widest);
        folderWidth = DrawLine(paint, 1, start, folderRight, folder, normal_, faint, true);
    }
    DrawLine(paint, 1, paint.left, folderRight - folderWidth - (folderWidth ? Scale(10) : 0), Text(row.subject), font, fore);
    // the first words, and a conversation's count and box
    int threadRight = paint.right;
    if (row.thread_opens) {
        RECT box = ColumnsThreadBox(index);
        DrawThreadBox(dc, box, row.thread_collapsed);
        int count = DrawLine(paint, 2, paint.left, box.left - Scale(4), std::to_wstring(row.thread_count), normal_, faint, true);
        threadRight = box.left - Scale(4) - count - Scale(8);
    }
    if (row.snippet && *row.snippet) {
        DrawLine(paint, 2, paint.left, threadRight, Text(row.snippet), normal_, faint);
    }
    if (selected && active && (ListView_GetItemState(list_, index, LVIS_FOCUSED) & LVIS_FOCUSED)) {
        RECT focus = area;
        InflateRect(&focus, -1, -1);
        DrawFocusRect(dc, &focus);
    }
}

// ---- the layout and the order ----

void Mailbox::SetColumns(bool on) {
    if (on == columns_) {
        return;
    }
    columns_ = on;
    int focused = ListView_GetNextItem(list_, -1, LVNI_FOCUSED);
    SendMessageW(list_, WM_SETREDRAW, FALSE, 0);
    // no headings in Columns ("Sorted by" says the order); the rows as tall as the small image list makes them
    LONG_PTR style = GetWindowLongPtrW(list_, GWL_STYLE);
    SetWindowLongPtrW(list_, GWL_STYLE, on ? style | LVS_NOCOLUMNHEADER : style & ~static_cast<LONG_PTR>(LVS_NOCOLUMNHEADER));
    if (on && !rowSpacer_) {
        rowSpacer_ = ImageList_Create(1, ColumnsRowHeight(), ILC_COLOR, 1, 0);
    }
    ListView_SetImageList(list_, on ? rowSpacer_ : listIcons_, LVSIL_SMALL);
    SetWindowPos(list_, nullptr, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE | SWP_FRAMECHANGED);
    SendMessageW(list_, WM_SETREDRAW, TRUE, 0);
    LayoutList();
    // the selected row stays in view; the selection and the open conversations are the view's, and stay
    if (focused >= 0) {
        ListView_EnsureVisible(list_, focused, FALSE);
    }
    InvalidateRect(list_, nullptr, TRUE);
}

void Mailbox::SortBy(PeSortField field) {
    if (field != sort_) {
        ascending_ = pe_sort_starts_ascending(field);
    }
    sort_ = field;
    ApplySort();
}

void Mailbox::SetAscending(bool ascending) {
    ascending_ = ascending;
    ApplySort();
}

void Mailbox::ApplySort() {
    pe_list_view_set_sort(view_.get(), sort_, ascending_);
    ReloadList(true);
    if (columns_) {
        LayoutList();
    }
}

namespace {

// the Sort By item of a field, Date for the dates
WORD SortItem(PeSortField field) {
    switch (field) {
    case PE_SORT_FIELD_FROM:
        return IDM_SORT_FROM;
    case PE_SORT_FIELD_SUBJECT:
        return IDM_SORT_SUBJECT;
    case PE_SORT_FIELD_SIZE:
        return IDM_SORT_SIZE;
    default:
        return IDM_SORT_DATE;
    }
}

}  // namespace

std::wstring Mailbox::SortedByText() const {
    PeText field = CommandText(static_cast<PeCommandId>(SortItem(sort_)));
    return core::T(PE_TEXT_UI_SORTED_BY, {{"field", core::Plain(field)}});
}

HMENU Mailbox::SortMenu() {
    HMENU menu = CreatePopupMenu();
    for (WORD id : {IDM_SORT_DATE, IDM_SORT_FROM, IDM_SORT_SUBJECT, IDM_SORT_SIZE}) {
        AppendMenuW(menu, MF_STRING, id, MenuItem(CommandText(static_cast<PeCommandId>(id))).c_str());
    }
    AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(menu, MF_STRING, IDM_SORT_ASCENDING, MenuItem(PE_TEXT_CMD_SORT_ASCENDING).c_str());
    AppendMenuW(menu, MF_STRING, IDM_SORT_DESCENDING, MenuItem(PE_TEXT_CMD_SORT_DESCENDING).c_str());
    return menu;
}

void Mailbox::UpdateSortMenu(HMENU menu) const {
    CheckMenuRadioItem(menu, IDM_SORT_DATE, IDM_SORT_SIZE, SortItem(sort_), MF_BYCOMMAND);
    CheckMenuRadioItem(menu, IDM_SORT_ASCENDING, IDM_SORT_DESCENDING, ascending_ ? IDM_SORT_ASCENDING : IDM_SORT_DESCENDING,
                       MF_BYCOMMAND);
}

void Mailbox::ShowSortMenu() {
    HMENU menu = SortMenu();
    UpdateSortMenu(menu);
    RECT button;
    GetWindowRect(sortButton_, &button);
    // its commands go to the main window, as the View menu's do
    TrackPopupMenu(menu, TPM_LEFTALIGN | TPM_TOPALIGN, button.left, button.bottom, 0, parent_, nullptr);
    DestroyMenu(menu);
}

// "Sorted by Date" flat on the window's face, the arrow of a menu after it, sunk while pressed
void Mailbox::DrawSortButton(const DRAWITEMSTRUCT& item) const {
    RECT face = item.rcItem;
    FillRect(item.hDC, &face, GetSysColorBrush(COLOR_BTNFACE));
    if (item.itemState & ODS_SELECTED) {
        DrawEdge(item.hDC, &face, BDR_SUNKENOUTER, BF_RECT);
        OffsetRect(&face, 1, 1);
    }
    std::wstring text = SortedByText();
    RECT words = face;
    words.left += Scale(4);
    words.right -= Scale(18);
    HGDIOBJ old = SelectObject(item.hDC, normal_);
    SetBkMode(item.hDC, TRANSPARENT);
    SetTextColor(item.hDC, GetSysColor(COLOR_BTNTEXT));
    RECT measured = words;
    DrawTextW(item.hDC, text.c_str(), static_cast<int>(text.size()), &measured, DT_SINGLELINE | DT_NOPREFIX | DT_CALCRECT);
    DrawTextW(item.hDC, text.c_str(), static_cast<int>(text.size()), &words, DT_LEFT | DT_VCENTER | DT_SINGLELINE | DT_NOPREFIX | DT_END_ELLIPSIS);
    SelectObject(item.hDC, old);
    RECT arrow = {std::min(measured.right, words.right) + Scale(2), face.top, 0, face.bottom};
    arrow.right = arrow.left + Scale(14);
    DrawMarlettGlyph(item.hDC, arrow, L'6', Scale(10), GetSysColor(COLOR_BTNTEXT));
    if (item.itemState & ODS_FOCUS) {
        RECT focus = item.rcItem;
        InflateRect(&focus, -2, -2);
        DrawFocusRect(item.hDC, &focus);
    }
}
