// The message list's rows in the Columns layout: three lines a message beside the reading pane. The same list view
// as the classic columns, its rows made tall by an image list of their height and drawn whole here in its custom draw:
// who and when, the subject and the marks, the first words of the message and a conversation's + or - box. Everything
// shown is what the core decoded; the snippet is the sender's text, drawn as text only.
#include "app.h"
#include "icons.h"

namespace {

// the geometry of a row, at 96 DPI: the room above and below its three lines, between two lines, its text's right
// margin, and its gutter for the unread dot
constexpr int kRowPadding = 5;
constexpr int kLineGap = 2;
constexpr int kRowMargin = 8;
constexpr int kGutter = 14;
// the sender's picture: its side, and the room between it and the text
constexpr int kPicture = 32;
constexpr int kPictureGap = 10;

// a colour `part` of the way from `from` to `to`, out of 255
COLORREF Mix(COLORREF from, COLORREF to, int part) {
    auto channel = [&](int a, int b) { return static_cast<BYTE>(a + (b - a) * part / 255); };
    return RGB(channel(GetRValue(from), GetRValue(to)), channel(GetGValue(from), GetGValue(to)),
               channel(GetBValue(from), GetBValue(to)));
}

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

// a date in the user's format: `flags` of GetDateFormatEx, or the `picture`
std::wstring DatePart(const SYSTEMTIME& time, DWORD flags, const wchar_t* picture) {
    wchar_t text[96] = L"";
    GetDateFormatEx(LOCALE_NAME_USER_DEFAULT, flags, &time, picture, text, 96, nullptr);
    return text;
}

// a date as the Columns list writes it (pe_date_style), seen at `now` in a zone `offset` seconds east of UTC: today's
// time, the weekday this week, the day and month this year, the whole date before
std::wstring ShortDate(int64_t seconds, int64_t now, int64_t offset) {
    SYSTEMTIME local;
    if (!UnixToSystemTime(seconds, true, local)) {
        return {};
    }
    switch (pe_date_style(seconds, now, offset)) {
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
        return FormatDay(local);
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
};

// how wide `text` is in `font`
int Width(HDC dc, HFONT font, const std::wstring& text) {
    HGDIOBJ old = SelectObject(dc, font);
    SIZE size = {};
    GetTextExtentPoint32W(dc, text.c_str(), static_cast<int>(text.size()), &size);
    SelectObject(dc, old);
    return size.cx;
}

// one line of text from `left` to `right` on line `n` (0 to 2) in `font`, cut short with an ellipsis; aligned right
// with `flush`
void DrawLine(const RowPaint& paint, int n, int left, int right, const std::wstring& text, HFONT font, COLORREF color,
              bool flush = false) {
    if (text.empty() || right <= left) {
        return;
    }
    HGDIOBJ old = SelectObject(paint.dc, font);
    SetTextColor(paint.dc, color);
    RECT place = {left, paint.top + n * paint.line, right, paint.top + (n + 1) * paint.line};
    UINT flags = DT_SINGLELINE | DT_NOPREFIX | DT_END_ELLIPSIS | DT_VCENTER | (flush ? DT_RIGHT : DT_LEFT);
    DrawTextW(paint.dc, text.c_str(), static_cast<int>(text.size()), &place, flags);
    SelectObject(paint.dc, old);
}

// `text` at the right end of line `n`, ending at `right`, at most `widest` wide; how wide it took
int DrawRight(const RowPaint& paint, int n, int right, int widest, const std::wstring& text, HFONT font, COLORREF color) {
    if (text.empty()) {
        return 0;
    }
    int width = std::min(Width(paint.dc, font, text), std::max(0, widest));
    DrawLine(paint, n, right - width, right, text, font, color, true);
    return width;
}

// the unread dot in the gutter, centred on `x`, `y`, in the device context's own brush and pen
void DrawDot(HDC dc, int x, int y, int size, COLORREF color) {
    HGDIOBJ oldBrush = SelectObject(dc, GetStockObject(DC_BRUSH));
    HGDIOBJ oldPen = SelectObject(dc, GetStockObject(DC_PEN));
    SetDCBrushColor(dc, color);
    SetDCPenColor(dc, color);
    Ellipse(dc, x - size / 2, y - size / 2, x - size / 2 + size, y - size / 2 + size);
    SelectObject(dc, oldPen);
    SelectObject(dc, oldBrush);
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
            DrawFlagMark(paint.dc, x, top, iconSize, selected, row.flag_color);
        }
        x -= gap;
    }
    return icons.empty() ? 0 : paint.right - x - gap;
}

// the items of View > Sort By and the fields they sort by, Date for the dates
constexpr std::pair<WORD, PeSortField> kSortItems[] = {
    {IDM_SORT_DATE, PE_SORT_FIELD_DATE},
    {IDM_SORT_FROM, PE_SORT_FIELD_FROM},
    {IDM_SORT_SUBJECT, PE_SORT_FIELD_SUBJECT},
    {IDM_SORT_SIZE, PE_SORT_FIELD_SIZE},
};

}  // namespace

PeSortField SortFieldOfItem(WORD id) {
    for (const auto& [item, field] : kSortItems) {
        if (item == id) {
            return field;
        }
    }
    return PE_SORT_FIELD_DATE;
}

WORD SortItemOf(PeSortField field) {
    for (const auto& [item, sorted] : kSortItems) {
        if (sorted == field) {
            return item;
        }
    }
    return IDM_SORT_DATE;
}

int Mailbox::ColumnsRowHeight() const {
    HDC dc = GetDC(list_);
    HGDIOBJ old = SelectObject(dc, bold_);
    TEXTMETRICW metrics = {};
    GetTextMetricsW(dc, &metrics);
    SelectObject(dc, old);
    ReleaseDC(list_, dc);
    return 3 * (metrics.tmHeight + Scale(kLineGap)) + 2 * Scale(kRowPadding);
}

void Mailbox::ColumnsPaintStarts() {
    paintNow_ = UnixNow();
    paintOffset_ = LocalOffset();
}

RECT Mailbox::ColumnsRowRect(int index) const {
    RECT area = {LVIR_BOUNDS};
    SendMessageW(list_, LVM_GETITEMRECT, index, reinterpret_cast<LPARAM>(&area));
    RECT client;
    GetClientRect(list_, &client);
    // the whole width: the columns under it are only for the list's own hit testing
    area.left = client.left;
    area.right = client.right;
    return area;
}

RECT Mailbox::ColumnsThreadBox(const RECT& row) {
    // odd, so that the + and - are in its middle; in the middle of the third line, at the right
    int size = Scale(9) | 1, line = (row.bottom - row.top - 2 * Scale(kRowPadding)) / 3;
    int right = row.right - Scale(kRowMargin), middle = row.top + Scale(kRowPadding) + 2 * line + line / 2;
    return {right - size, middle - size / 2, right, middle - size / 2 + size};
}

std::wstring Mailbox::RowPerson(const PeMessage& row) const {
    return recipientsColumn_ ? core::T(PE_TEXT_UI_COL_TO) + L": " + Text(row.recipients) : Text(row.from);
}

std::wstring Mailbox::ColumnsRowText(const PeMessage& row) const {
    std::vector<std::wstring> parts;
    if (row.bold) {
        parts.push_back(core::T(PE_TEXT_UI_ROW_UNREAD));
    }
    parts.push_back(RowPerson(row));
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
    RECT area = ColumnsRowRect(index);
    bool selected = (ListView_GetItemState(list_, index, LVIS_SELECTED) & LVIS_SELECTED) != 0;
    bool active = GetFocus() == list_;
    COLORREF fore = GetSysColor(RowTextColor(index, &row));
    COLORREF faint = selected ? fore : GetSysColor(COLOR_GRAYTEXT);
    FillRect(dc, &area, GetSysColorBrush(selected ? SelectionColor() : COLOR_WINDOW));
    // a hairline between the rows, which are tall
    RECT rule = {area.left, area.bottom - 1, area.right, area.bottom};
    FillRect(dc, &rule, GetSysColorBrush(COLOR_BTNFACE));
    SetBkMode(dc, TRANSPARENT);
    int line = (area.bottom - area.top - 2 * Scale(kRowPadding)) / 3;
    // a conversation's other messages under its first, indented; the sender's picture before the text
    int left = area.left + Scale(kGutter) + (row.thread_depth > 0 ? Scale(16) : 0);
    if (listPictures_) {
        int size = Scale(kPicture), top = area.top + (area.bottom - area.top - size) / 2;
        DrawRowPicture(dc, {left, top, left + size, top + size}, row, selected);
        left += size + Scale(kPictureGap);
    }
    RowPaint paint = {dc, left, area.right - Scale(kRowMargin), area.top + Scale(kRowPadding), line};
    if (row.bold) {
        DrawDot(dc, area.left + Scale(kGutter) / 2, paint.top + line / 2, Scale(7), selected ? fore : GetSysColor(COLOR_HOTLIGHT));
    }
    HFONT font = RowFont(row);
    // who and when
    std::wstring date = row.has_date ? ShortDate(row.date, paintNow_, paintOffset_) : L"";
    int dateWidth = DrawRight(paint, 0, paint.right, paint.right - paint.left, date, normal_, faint);
    DrawLine(paint, 0, paint.left, paint.right - dateWidth - Scale(10), RowPerson(row), font, fore);
    // the subject, the marks at the right (the folder before them in a list of several folders)
    int marks = DrawMarks(paint, row, selected, listIcons_, iconSize_);
    int folderRight = paint.right - marks - (marks ? Scale(6) : 0);
    int folderWidth = SeveralFolders()
                          ? DrawRight(paint, 1, folderRight, (folderRight - paint.left) * 2 / 5, RowFolder(row.folder), normal_, faint)
                          : 0;
    DrawLine(paint, 1, paint.left, folderRight - folderWidth - (folderWidth ? Scale(10) : 0), Text(row.subject), font, fore);
    // the first words, and a conversation's count and box
    int threadRight = paint.right;
    if (row.thread_opens) {
        RECT box = ColumnsThreadBox(area);
        DrawThreadBox(dc, box, row.thread_collapsed);
        int count = DrawRight(paint, 2, box.left - Scale(4), box.left - paint.left, std::to_wstring(row.thread_count), normal_, faint);
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
    // from the top: a scroll position of the other rows' height would leave the list part of a row down
    ListView_EnsureVisible(list_, 0, FALSE);
    // the rows as tall as the small image list makes them
    if (on && !rowSpacer_) {
        rowSpacer_ = ImageList_Create(1, ColumnsRowHeight(), ILC_COLOR, 1, 0);
    }
    ListView_SetImageList(list_, on ? rowSpacer_ : listIcons_, LVSIL_SMALL);
    // no headings in Columns ("Sorted by" says the order): the style, and the header window itself hidden, as the
    // classic list view otherwise keeps the header's room above its first row; done with drawing on, so the list
    // takes the change in at once
    LONG_PTR style = GetWindowLongPtrW(list_, GWL_STYLE);
    SetWindowLongPtrW(list_, GWL_STYLE, on ? style | LVS_NOCOLUMNHEADER : style & ~static_cast<LONG_PTR>(LVS_NOCOLUMNHEADER));
    if (HWND header = ListView_GetHeader(list_)) {
        ShowWindow(header, on ? SW_HIDE : SW_SHOW);
    }
    SetWindowPos(list_, nullptr, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE | SWP_FRAMECHANGED);
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
    UpdateSortButton();
}

void Mailbox::UpdateSortButton() {
    // its words are also its name for screen readers
    SetWindowTextW(sortButton_, SortedByText().c_str());
    RECT now;
    GetWindowRect(sortButton_, &now);
    int width = std::min(SortButtonWidth(), static_cast<int>(listArea_.right - listArea_.left));
    SetWindowPos(sortButton_, nullptr, 0, 0, width, now.bottom - now.top, SWP_NOMOVE | SWP_NOZORDER | SWP_NOACTIVATE);
    InvalidateRect(sortButton_, nullptr, TRUE);
}

int Mailbox::SortButtonWidth() const {
    HDC dc = GetDC(sortButton_);
    int width = Width(dc, normal_, SortedByText());
    ReleaseDC(sortButton_, dc);
    // the words, their margin and the arrow after them
    return width + Scale(30);
}

std::wstring Mailbox::SortedByText() const {
    PeText field = CommandText(static_cast<PeCommandId>(SortItemOf(sort_)));
    return core::T(PE_TEXT_UI_SORTED_BY, {{"field", core::Plain(field)}});
}

HMENU Mailbox::SortMenu() {
    HMENU menu = CreatePopupMenu();
    for (const auto& item : kSortItems) {
        AppendMenuW(menu, MF_STRING, item.first, MenuItem(CommandText(static_cast<PeCommandId>(item.first))).c_str());
    }
    AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(menu, MF_STRING, IDM_SORT_ASCENDING, MenuItem(PE_TEXT_CMD_SORT_ASCENDING).c_str());
    AppendMenuW(menu, MF_STRING, IDM_SORT_DESCENDING, MenuItem(PE_TEXT_CMD_SORT_DESCENDING).c_str());
    return menu;
}

void Mailbox::UpdateSortMenu(HMENU menu) const {
    CheckMenuRadioItem(menu, IDM_SORT_DATE, IDM_SORT_SIZE, SortItemOf(sort_), MF_BYCOMMAND);
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

// ---- the senders' pictures ----

void Mailbox::DrawRowPicture(HDC dc, const RECT& box, const PeMessage& row, bool selected) {
    int size = box.right - box.left;
    if (HBITMAP bitmap = pictures_.Get(row.picture, size)) {
        // the logo's own transparency kept, over the row, through the one memory DC of the list's pictures
        if (!pictureDc_) {
            pictureDc_ = CreateCompatibleDC(dc);
        }
        DrawPremultiplied(dc, box.left, box.top, bitmap, size, pictureDc_);
        // a hairline in the initials' grey, so a logo on white keeps its square's edge on a white row
        FrameRect(dc, &box, GetSysColorBrush(COLOR_BTNFACE));
        return;
    }
    // the initials, quiet: one grey for everyone, on a square a shade off the row's background
    COLORREF back = GetSysColor(selected ? SelectionColor() : COLOR_WINDOW);
    COLORREF ink = GetSysColor(!selected ? COLOR_GRAYTEXT : GetFocus() == list_ ? COLOR_HIGHLIGHTTEXT : COLOR_BTNTEXT);
    SetDCBrushColor(dc, Mix(back, selected ? ink : GetSysColor(COLOR_BTNFACE), selected ? 40 : 255));
    RECT square = box;
    FillRect(dc, &square, static_cast<HBRUSH>(GetStockObject(DC_BRUSH)));
    std::wstring initials = Text(row.initials);
    if (initials.empty()) {
        return;
    }
    HGDIOBJ old = SelectObject(dc, bold_);
    SetTextColor(dc, ink);
    DrawTextW(dc, initials.c_str(), static_cast<int>(initials.size()), &square, DT_CENTER | DT_VCENTER | DT_SINGLELINE | DT_NOPREFIX);
    SelectObject(dc, old);
}

void Mailbox::PictureReady(uint64_t request) {
    uint64_t key = pictures_.Ready(request);
    if (!key || !columns_ || !listPictures_) {
        return;
    }
    // only the rows shown with that picture
    int top = ListView_GetTopIndex(list_), shown = ListView_GetCountPerPage(list_) + 1;
    for (int index = top; index < top + shown; index++) {
        const PeMessage* row = Row(index);
        if (row && row->picture == key) {
            ListView_RedrawItems(list_, index, index);
        }
    }
}

int Mailbox::TestListTop() const {
    RECT row = {};
    int top = ListView_GetTopIndex(list_);
    if (ListView_GetItemCount(list_) == 0 || !ListView_GetItemRect(list_, top, &row, LVIR_BOUNDS)) {
        return 0;
    }
    return 1000 + row.top;
}

int Mailbox::TestRowPicture(const std::wstring& subject) {
    int count = ListView_GetItemCount(list_);
    for (int index = 0; index < count; index++) {
        const PeMessage* row = Row(index);
        if (!row || Text(row->subject) != subject) {
            continue;
        }
        if (!columns_ || !listPictures_) {
            return 10;
        }
        if (!pictures_.Get(row->picture, Scale(kPicture))) {
            return 11;
        }
        return row->picture_kind == PE_PICTURE_KIND_CONTACT ? 13 : 12;
    }
    return 0;
}
