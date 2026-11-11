// The Address Book as Outlook Express has it: Tools > Address Book with the groups on the left and the people on the
// right, Contact Properties and Group Properties, Select Recipients behind the To, Cc and Bcc buttons of a compose
// window, and vCard and CSV files in and out. The book is the core's (pe_cards, pe_groups): it finds, checks, saves,
// reads and writes the files; these windows show its rows and hand back what was typed.
#include "app.h"
#include "icons.h"

#include <shlwapi.h>
#include <windowsx.h>

#include <algorithm>
#include <memory>
#include <tuple>

namespace {

const wchar_t* kBookClass = L"InboxClassicAddressBook";
const wchar_t* kContactClass = L"InboxClassicContact";
const wchar_t* kGroupClass = L"InboxClassicGroup";
const wchar_t* kPickClass = L"InboxClassicPick";

// the Address Book window while it is open
HWND g_book = nullptr;

// a row of the book's lists: a person, a group, or someone in a group
struct Entry {
    bool group = false;
    // the card or the group; 0 for an address typed into a group that is no card
    int64_t id = 0;
    // as the Name column shows it (the core's: the address of someone without a name)
    std::wstring name;
    std::wstring address;
    std::wstring phone;
    // how many are in a group
    size_t members = 0;
    // as it goes in an address field (the core's), empty for a person without an address
    std::wstring label;
};

// rows of the core's list of people: the book's (pe_cards) or a group's (pe_group_people)
std::vector<Entry> People(PeCardList* list) {
    std::vector<Entry> entries;
    for (size_t i = 0, count = pe_card_list_count(list); i < count; i++) {
        const PeCardRow* row = pe_card_list_get(list, i);
        Entry entry;
        entry.id = row->id;
        entry.name = Text(row->name);
        entry.address = Text(row->address);
        entry.phone = Text(row->phone);
        entry.label = Text(row->label);
        entries.push_back(std::move(entry));
    }
    return entries;
}

std::vector<Entry> Cards(PeCore* core, const std::wstring& filter) {
    core::CardList list(pe_cards(core, core::Narrow(filter).c_str()));
    return People(list.get());
}

std::vector<Entry> GroupPeople(PeCore* core, int64_t group, const std::wstring& filter) {
    core::CardList list(pe_group_people(core, group, core::Narrow(filter).c_str()));
    return People(list.get());
}

std::vector<Entry> Groups(PeCore* core, const std::wstring& filter = L"") {
    std::vector<Entry> entries;
    core::GroupList list(pe_groups(core, core::Narrow(filter).c_str()));
    for (size_t i = 0, count = pe_group_list_count(list.get()); i < count; i++) {
        const PeGroupRow* row = pe_group_list_get(list.get(), i);
        Entry entry;
        entry.group = true;
        entry.id = row->id;
        entry.name = Text(row->name);
        entry.members = row->member_count;
        entry.label = Text(row->label);
        entries.push_back(std::move(entry));
    }
    return entries;
}

// the members of group `id` as Group Properties edits them, and its name in `name`
std::vector<Entry> Members(PeCore* core, int64_t id, std::wstring& name) {
    std::vector<Entry> entries;
    core::GroupView view(pe_group(core, id));
    const PeGroup* group = view ? pe_group_info(view.get()) : nullptr;
    if (!group) {
        return entries;
    }
    name = Text(group->name);
    for (size_t i = 0; i < group->member_count; i++) {
        const PeMember& member = group->members[i];
        Entry entry;
        entry.id = member.card;
        entry.name = Text(member.name);
        entry.address = Text(member.address);
        entry.label = Text(member.label);
        entries.push_back(std::move(entry));
    }
    return entries;
}

// the rows of a report list: Name, E-mail (a group: how many are in it) and, when it has the column, Phone
void FillList(HWND list, const std::vector<Entry>& entries) {
    SendMessageW(list, WM_SETREDRAW, FALSE, 0);
    ListView_DeleteAllItems(list);
    bool phone = Header_GetItemCount(ListView_GetHeader(list)) > 2;
    for (size_t i = 0; i < entries.size(); i++) {
        const Entry& entry = entries[i];
        int row = AddRow(list, static_cast<int>(i), entry.name);
        SetCell(list, row, 1,
                entry.group ? core::T(PE_TEXT_UI_GROUP_MEMBERS_COUNT, {{"count", std::to_wstring(entry.members)}}) : entry.address);
        if (phone) {
            SetCell(list, row, 2, entry.phone);
        }
    }
    SendMessageW(list, WM_SETREDRAW, TRUE, 0);
    InvalidateRect(list, nullptr, TRUE);
}

// the lines of a list box, `select` selected
void FillListBox(HWND list, const std::vector<std::wstring>& lines, int select) {
    SendMessageW(list, LB_RESETCONTENT, 0, 0);
    for (const std::wstring& line : lines) {
        SendMessageW(list, LB_ADDSTRING, 0, reinterpret_cast<LPARAM>(line.c_str()));
    }
    if (!lines.empty()) {
        SendMessageW(list, LB_SETCURSEL, std::clamp(select, 0, static_cast<int>(lines.size()) - 1), 0);
    }
}

std::vector<int> SelectedIndexes(HWND list) {
    std::vector<int> rows;
    for (int i = ListView_GetNextItem(list, -1, LVNI_SELECTED); i >= 0; i = ListView_GetNextItem(list, i, LVNI_SELECTED)) {
        rows.push_back(i);
    }
    return rows;
}

void Warn(HWND owner, const std::wstring& text) {
    MessageBoxW(owner, text.c_str(), L"Inbox Classic", MB_OK | MB_ICONWARNING);
}

std::wstring Trimmed(const std::wstring& text) {
    size_t start = text.find_first_not_of(L" \t\r\n");
    if (start == std::wstring::npos) {
        return L"";
    }
    return text.substr(start, text.find_last_not_of(L" \t\r\n") - start + 1);
}

std::wstring ItemText(HWND dialog, int id) {
    return Trimmed(GetWindowString(GetDlgItem(dialog, id)));
}

// the address typed in box `id` of `dialog` into `typed` (empty when nothing is); false when it is not an e-mail
// address alone, as the core keeps them, which was said
bool TypedAddress(HWND dialog, int id, std::wstring& typed) {
    typed = ItemText(dialog, id);
    if (typed.empty() || pe_address_is_mailbox(core::Narrow(typed).c_str())) {
        return true;
    }
    Warn(dialog, core::T(PE_TEXT_UI_CONTACT_ADDRESS_INVALID, {{"address", typed}}));
    SetFocus(GetDlgItem(dialog, id));
    return false;
}

// the labels of `entries` for an address field, separated by commas, each address once (the core's)
std::wstring FieldText(const std::wstring& field, const std::vector<Entry>& entries) {
    std::wstring added;
    for (const Entry& entry : entries) {
        if (!entry.label.empty()) {
            added += (added.empty() ? L"" : L", ") + entry.label;
        }
    }
    if (added.empty()) {
        return field;
    }
    core::String text(pe_address_field_add(core::Narrow(field).c_str(), core::Narrow(added).c_str()));
    return text ? Text(text.get()) : field;
}

// a button of a dialog, 25 high at 96 DPI
HWND MakeButton(HWND dialog, PeText text, int id, int left, int top, int width, bool plain = false) {
    std::wstring label = plain ? core::Plain(text) : core::T(text);
    return CreateChild(dialog, L"BUTTON", label.c_str(), WS_TABSTOP, id, {left, top, left + width, top + Scale(25)});
}

HWND MakeLabel(HWND dialog, const std::wstring& text, const RECT& bounds) {
    return CreateChild(dialog, L"STATIC", text.c_str(), SS_LEFT | SS_NOPREFIX, 0, bounds);
}

HWND MakeEdit(HWND dialog, int id, const std::wstring& text, const RECT& bounds, DWORD style = ES_AUTOHSCROLL) {
    return CreateChild(dialog, L"EDIT", text.c_str(), WS_TABSTOP | style, id, bounds, WS_EX_CLIENTEDGE);
}

HWND MakeListBox(HWND dialog, int id, const RECT& bounds) {
    return CreateChild(dialog, L"LISTBOX", L"", WS_TABSTOP | WS_VSCROLL | LBS_NOTIFY | LBS_NOINTEGRALHEIGHT | LBS_WANTKEYBOARDINPUT, id,
                       bounds, WS_EX_CLIENTEDGE);
}

// OK and Cancel at the bottom right of a dialog `width` wide, their top at `top`
void OkCancel(HWND dialog, int width, int top) {
    std::wstring ok = core::T(PE_TEXT_UI_OK), cancel = core::T(PE_TEXT_UI_CANCEL);
    int pad = Scale(10), buttonWidth = ButtonWidth({ok, cancel});
    CreateChild(dialog, L"BUTTON", ok.c_str(), WS_TABSTOP | BS_DEFPUSHBUTTON, IDOK,
                {width - pad - 2 * buttonWidth - Scale(6), top, width - pad - buttonWidth - Scale(6), top + Scale(25)});
    CreateChild(dialog, L"BUTTON", cancel.c_str(), WS_TABSTOP, IDCANCEL, {width - pad - buttonWidth, top, width - pad, top + Scale(25)});
}

// what the book's dialogs share: their buttons, OK, Cancel and the boxes' changes to `command`, Delete in a list box
// to `remove` (true when it took it), the colors of their words, and closing. `State` has `done`.
template <typename State>
LRESULT DialogProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam, void (*command)(HWND, State&, WORD id, WORD code),
                   bool (*remove)(HWND, State&, HWND list)) {
    auto* state = reinterpret_cast<State*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
    if (!state) {
        return DefWindowProcW(hwnd, message, wParam, lParam);
    }
    switch (message) {
    case WM_COMMAND: {
        WORD id = LOWORD(wParam), code = HIWORD(wParam);
        if (code == BN_CLICKED || code == EN_CHANGE || id == IDOK || id == IDCANCEL) {
            command(hwnd, *state, id, code);
        }
        return 0;
    }
    case WM_VKEYTOITEM:
        return LOWORD(wParam) == VK_DELETE && remove(hwnd, *state, reinterpret_cast<HWND>(lParam)) ? -2 : -1;
    case WM_CTLCOLORSTATIC:
        return ButtonFaceColor(reinterpret_cast<HDC>(wParam));
    case WM_CLOSE:
        state->done = true;
        return 0;
    }
    return DefWindowProcW(hwnd, message, wParam, lParam);
}

// ---- Select Recipients, Select Group Members ----

enum class PickMode { Recipients, Members };

struct PickState {
    PeCore* core = nullptr;
    PickMode mode = PickMode::Recipients;
    HWND find = nullptr;
    HWND list = nullptr;
    std::vector<Entry> shown;
    // To, Cc and Bcc, or the members alone
    int targets = 3;
    HWND lists[3] = {};
    std::vector<Entry> chosen[3];
    bool done = false;
    bool accepted = false;
};

// the groups the core finds for the words (Select Recipients only), then the people
void FillPick(PickState& state) {
    std::wstring filter = Trimmed(GetWindowString(state.find));
    state.shown = state.mode == PickMode::Recipients ? Groups(state.core, filter) : std::vector<Entry>();
    for (Entry& card : Cards(state.core, filter)) {
        state.shown.push_back(std::move(card));
    }
    FillList(state.list, state.shown);
    if (!state.shown.empty()) {
        ListView_SetItemState(state.list, 0, LVIS_FOCUSED, LVIS_FOCUSED);
    }
}

// the rows selected in the book into list `target`, each once
void AddPicked(HWND dialog, PickState& state, int target) {
    for (int index : SelectedIndexes(state.list)) {
        if (index < 0 || static_cast<size_t>(index) >= state.shown.size()) {
            continue;
        }
        const Entry& entry = state.shown[index];
        // a recipient needs an address; a member of a group may be a card without one
        if (state.mode == PickMode::Recipients && entry.label.empty()) {
            Warn(dialog, core::T(PE_TEXT_UI_BOOK_NO_ADDRESS, {{"name", entry.name}}));
            continue;
        }
        std::vector<Entry>& chosen = state.chosen[target];
        if (std::any_of(chosen.begin(), chosen.end(), [&](const Entry& e) { return e.group == entry.group && e.id == entry.id; })) {
            continue;
        }
        chosen.push_back(entry);
        SendMessageW(state.lists[target], LB_ADDSTRING, 0, reinterpret_cast<LPARAM>(entry.name.c_str()));
    }
}

bool RemovePicked(HWND, PickState& state, HWND list) {
    for (int target = 0; target < state.targets; target++) {
        if (list != state.lists[target]) {
            continue;
        }
        int index = static_cast<int>(SendMessageW(list, LB_GETCURSEL, 0, 0));
        if (index >= 0 && static_cast<size_t>(index) < state.chosen[target].size()) {
            state.chosen[target].erase(state.chosen[target].begin() + index);
            SendMessageW(list, LB_DELETESTRING, index, 0);
            int count = static_cast<int>(state.chosen[target].size());
            if (count > 0) {
                SendMessageW(list, LB_SETCURSEL, std::min(index, count - 1), 0);
            }
        }
        return true;
    }
    return false;
}

void OnPickCommand(HWND dialog, PickState& state, WORD id, WORD code) {
    if (id == IDOK || id == IDCANCEL) {
        state.accepted = id == IDOK;
        state.done = true;
    } else if (id >= IDC_PICK_TO && id < IDC_PICK_TO + state.targets) {
        AddPicked(dialog, state, id - IDC_PICK_TO);
    } else if (id == IDC_PICK_FIND && code == EN_CHANGE) {
        FillPick(state);
    }
}

LRESULT CALLBACK PickProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {
    auto* state = reinterpret_cast<PickState*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
    // a double-click puts the person in the first list (To), as in Outlook Express
    if (state && message == WM_NOTIFY) {
        auto* header = reinterpret_cast<NMHDR*>(lParam);
        if (header->hwndFrom == state->list && header->code == NM_DBLCLK) {
            AddPicked(hwnd, *state, 0);
        }
        return 0;
    }
    return DialogProc<PickState>(hwnd, message, wParam, lParam, OnPickCommand, RemovePicked);
}

// the picker until OK (true) or Cancel; what was chosen in `state.chosen`
bool RunPick(HWND owner, PickState& state) {
    RegisterDialogClass(kPickClass, PickProc);
    bool recipients = state.mode == PickMode::Recipients;
    state.targets = recipients ? 3 : 1;
    int pad = Scale(10), gap = Scale(6), rowHeight = Scale(22), labelHeight = Scale(18);
    int width = Scale(640), height = Scale(420);
    std::wstring title = core::Plain(recipients ? PE_TEXT_UI_SELECT_RECIPIENTS : PE_TEXT_UI_SELECT_MEMBERS);
    HWND dialog = CreateModalWindow(owner, kPickClass, title.c_str(), width, height);
    SetWindowLongPtrW(dialog, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(&state));

    int bottom = height - pad - Scale(25) - pad;
    int leftWidth = Scale(300);
    MakeLabel(dialog, core::T(PE_TEXT_UI_PICK_INTRO), {pad, pad, pad + leftWidth, pad + labelHeight});
    state.find = MakeEdit(dialog, IDC_PICK_FIND, L"", {pad, pad + labelHeight, pad + leftWidth, pad + labelHeight + rowHeight});
    int listTop = pad + labelHeight + rowHeight + gap;
    state.list = CreateChild(dialog, WC_LISTVIEWW, nullptr, WS_TABSTOP | LVS_REPORT | LVS_SHOWSELALWAYS | LVS_NOSORTHEADER, IDC_PICK_LIST,
                             {pad, listTop, pad + leftWidth, bottom}, WS_EX_CLIENTEDGE);
    ListView_SetExtendedListViewStyle(state.list, LVS_EX_FULLROWSELECT);
    AddColumn(state.list, 0, core::T(PE_TEXT_UI_COL_NAME).c_str(), 140);
    AddColumn(state.list, 1, core::T(PE_TEXT_UI_COL_EMAIL).c_str(), 140);
    ListView_SetColumnWidth(state.list, 1, LVSCW_AUTOSIZE_USEHEADER);

    std::vector<std::wstring> labels;
    PeText buttons[] = {PE_TEXT_UI_PICK_TO, PE_TEXT_UI_PICK_CC, PE_TEXT_UI_PICK_BCC};
    if (!recipients) {
        buttons[0] = PE_TEXT_UI_PICK_ADD;
    }
    for (int i = 0; i < state.targets; i++) {
        labels.push_back(core::T(buttons[i]));
    }
    int buttonWidth = ButtonWidth(labels, 76);
    int buttonLeft = pad + leftWidth + Scale(12);
    int listLeft = buttonLeft + buttonWidth + Scale(8);
    MakeLabel(dialog, core::T(recipients ? PE_TEXT_UI_PICK_RECIPIENTS : PE_TEXT_UI_PICK_MEMBERS), {listLeft, pad, width - pad, pad + labelHeight});
    // the lists share the height beside the book, a button at the top of each
    int top = pad + labelHeight, each = (bottom - top - (state.targets - 1) * gap) / state.targets;
    for (int i = 0; i < state.targets; i++) {
        int y = top + i * (each + gap);
        MakeButton(dialog, buttons[i], IDC_PICK_TO + i, buttonLeft, y, buttonWidth);
        state.lists[i] = MakeListBox(dialog, IDC_PICK_TO_LIST + i, {listLeft, y, width - pad, y + each});
    }
    OkCancel(dialog, width, height - pad - Scale(25));
    FillPick(state);
    RunModal(dialog, state.find, state.done);
    return state.accepted;
}

// Select Group Members: the people chosen
std::vector<Entry> PickMembers(HWND owner, PeCore* core) {
    PickState state;
    state.core = core;
    state.mode = PickMode::Members;
    return RunPick(owner, state) ? state.chosen[0] : std::vector<Entry>();
}

// ---- Contact Properties ----

// the kinds of phone numbers in the order of the list
const std::pair<PePhoneKind, PeText> kPhoneKinds[] = {
    {PE_PHONE_KIND_HOME, PE_TEXT_UI_PHONE_HOME},
    {PE_PHONE_KIND_WORK, PE_TEXT_UI_PHONE_WORK},
    {PE_PHONE_KIND_MOBILE, PE_TEXT_UI_PHONE_MOBILE},
    {PE_PHONE_KIND_OTHER, PE_TEXT_UI_PHONE_OTHER},
};

std::wstring PhoneKindName(PePhoneKind kind) {
    for (const auto& [value, text] : kPhoneKinds) {
        if (value == kind) {
            return core::T(text);
        }
    }
    return core::T(PE_TEXT_UI_PHONE_OTHER);
}

struct ContactState {
    PeCore* core = nullptr;
    int64_t id = 0;
    // the boxes as the card has them
    std::wstring first, last, display, nickname, company, notes;
    // the default first
    std::vector<std::wstring> addresses;
    struct Phone {
        PePhoneKind kind;
        std::wstring number;
    };
    std::vector<Phone> phones;
    // the display name was typed (or the card has one of its own): it no longer follows the first and last name
    bool displayTyped = false;
    // the display name is being set to follow them: not the user typing
    bool following = false;
    int64_t saved = 0;
    bool done = false;
};

// the display name made of `first` and `last` (the core's)
std::wstring DisplayName(const std::wstring& first, const std::wstring& last) {
    core::String name(pe_book_display_name(core::Narrow(first).c_str(), core::Narrow(last).c_str()));
    return name ? Text(name.get()) : L"";
}

// card `id` into `state`; its id left 0 when there is none
void LoadContact(PeCore* core, int64_t id, ContactState& state) {
    state.core = core;
    core::CardView view(id ? pe_card(core, id) : nullptr);
    const PeCard* card = view ? pe_card_info(view.get()) : nullptr;
    if (!card) {
        return;
    }
    state.id = id;
    state.first = Text(card->first);
    state.last = Text(card->last);
    state.display = Text(card->name);
    state.nickname = Text(card->nickname);
    state.company = Text(card->company);
    state.notes = WithCrlf(Text(card->notes));
    for (size_t i = 0; i < card->address_count; i++) {
        state.addresses.push_back(Text(card->addresses[i]));
    }
    for (size_t i = 0; i < card->phone_count; i++) {
        state.phones.push_back({card->phones[i].kind, Text(card->phones[i].number)});
    }
    state.displayTyped = !state.display.empty() && state.display != DisplayName(state.first, state.last);
}

void ShowAddresses(HWND dialog, const ContactState& state, int select) {
    std::vector<std::wstring> lines = state.addresses;
    if (!lines.empty()) {
        lines[0] = core::T(PE_TEXT_UI_CONTACT_DEFAULT, {{"address", lines[0]}});
    }
    FillListBox(GetDlgItem(dialog, IDC_CONTACT_ADDRESSES), lines, select);
}

void ShowPhones(HWND dialog, const ContactState& state, int select) {
    HWND list = GetDlgItem(dialog, IDC_CONTACT_PHONES);
    ListView_DeleteAllItems(list);
    for (size_t i = 0; i < state.phones.size(); i++) {
        int row = AddRow(list, static_cast<int>(i), PhoneKindName(state.phones[i].kind));
        SetCell(list, row, 1, state.phones[i].number);
    }
    SelectRow(list, select);
}

// the address typed (if any) into the list; false when it is not an address, which was said
bool AddAddress(HWND dialog, ContactState& state) {
    std::wstring typed;
    if (!TypedAddress(dialog, IDC_CONTACT_ADDRESS, typed)) {
        return false;
    }
    if (typed.empty()) {
        return true;
    }
    if (std::none_of(state.addresses.begin(), state.addresses.end(), [&](const std::wstring& a) {
            return CompareStringOrdinal(a.c_str(), -1, typed.c_str(), -1, TRUE) == CSTR_EQUAL;
        })) {
        state.addresses.push_back(typed);
    }
    SetDlgItemTextW(dialog, IDC_CONTACT_ADDRESS, L"");
    ShowAddresses(dialog, state, static_cast<int>(state.addresses.size()) - 1);
    return true;
}

void AddPhone(HWND dialog, ContactState& state) {
    std::wstring number = ItemText(dialog, IDC_CONTACT_PHONE);
    if (number.empty()) {
        return;
    }
    LRESULT kind = SendDlgItemMessageW(dialog, IDC_CONTACT_PHONE_KIND, CB_GETCURSEL, 0, 0);
    PePhoneKind chosen = kind >= 0 && static_cast<size_t>(kind) < std::size(kPhoneKinds) ? kPhoneKinds[kind].first : PE_PHONE_KIND_OTHER;
    state.phones.push_back({chosen, number});
    SetDlgItemTextW(dialog, IDC_CONTACT_PHONE, L"");
    ShowPhones(dialog, state, static_cast<int>(state.phones.size()) - 1);
}

// the notes as the core keeps them, lines ending in LF
std::wstring WithoutCr(std::wstring text) {
    std::erase(text, L'\r');
    return text;
}

// the card as typed, saved in the core; false when it could not be, which was said (the core says why)
bool SaveContact(HWND dialog, ContactState& state) {
    if (!AddAddress(dialog, state)) {
        return false;
    }
    AddPhone(dialog, state);
    std::string name = core::Narrow(ItemText(dialog, IDC_CONTACT_DISPLAY));
    std::string first = core::Narrow(ItemText(dialog, IDC_CONTACT_FIRST));
    std::string last = core::Narrow(ItemText(dialog, IDC_CONTACT_LAST));
    std::string nickname = core::Narrow(ItemText(dialog, IDC_CONTACT_NICKNAME));
    std::string company = core::Narrow(ItemText(dialog, IDC_CONTACT_COMPANY));
    std::string notes = core::Narrow(WithoutCr(GetWindowString(GetDlgItem(dialog, IDC_CONTACT_NOTES))));
    // the strings first, then the pointers into them, which a growing vector would move
    std::vector<std::string> addresses, numbers;
    addresses.reserve(state.addresses.size());
    numbers.reserve(state.phones.size());
    for (const std::wstring& address : state.addresses) {
        addresses.push_back(core::Narrow(address));
    }
    for (const ContactState::Phone& phone : state.phones) {
        numbers.push_back(core::Narrow(phone.number));
    }
    std::vector<const char*> addressPointers;
    std::vector<PePhone> phones;
    addressPointers.reserve(addresses.size());
    phones.reserve(numbers.size());
    for (const std::string& address : addresses) {
        addressPointers.push_back(address.c_str());
    }
    for (size_t i = 0; i < numbers.size(); i++) {
        phones.push_back({state.phones[i].kind, numbers[i].c_str()});
    }
    PeCard card = {};
    card.id = state.id;
    card.name = name.c_str();
    card.first = first.c_str();
    card.last = last.c_str();
    card.nickname = nickname.c_str();
    card.company = company.c_str();
    card.notes = notes.c_str();
    card.addresses = addressPointers.data();
    card.address_count = addressPointers.size();
    card.phones = phones.data();
    card.phone_count = phones.size();
    char* error = nullptr;
    int64_t saved = pe_card_save(state.core, &card, &error);
    if (!saved) {
        Warn(dialog, core::T(PE_TEXT_UI_CONTACT_NOT_SAVED, {{"reason", ReasonText(error, PE_TEXT_UI_UNKNOWN_REASON)}}));
        return false;
    }
    core::String unused(error);
    state.saved = saved;
    return true;
}

// the display name follows the first and last name until the user types one of their own
void OnNameChanged(HWND dialog, ContactState& state, WORD id) {
    if (state.following) {
        return;
    }
    if (id == IDC_CONTACT_DISPLAY) {
        state.displayTyped = !ItemText(dialog, IDC_CONTACT_DISPLAY).empty();
        return;
    }
    if (!state.displayTyped) {
        state.following = true;
        SetDlgItemTextW(dialog, IDC_CONTACT_DISPLAY, DisplayName(ItemText(dialog, IDC_CONTACT_FIRST), ItemText(dialog, IDC_CONTACT_LAST)).c_str());
        state.following = false;
    }
}

void OnContactCommand(HWND dialog, ContactState& state, WORD id, WORD code) {
    if (code == EN_CHANGE) {
        if (id == IDC_CONTACT_FIRST || id == IDC_CONTACT_LAST || id == IDC_CONTACT_DISPLAY) {
            OnNameChanged(dialog, state, id);
        }
        return;
    }
    int address = static_cast<int>(SendDlgItemMessageW(dialog, IDC_CONTACT_ADDRESSES, LB_GETCURSEL, 0, 0));
    bool hasAddress = address >= 0 && static_cast<size_t>(address) < state.addresses.size();
    switch (id) {
    case IDOK: {
        // Enter in the address or phone box adds what was typed there; elsewhere it saves the card
        HWND focus = GetFocus();
        if (focus == GetDlgItem(dialog, IDC_CONTACT_ADDRESS) && !ItemText(dialog, IDC_CONTACT_ADDRESS).empty()) {
            AddAddress(dialog, state);
        } else if (focus == GetDlgItem(dialog, IDC_CONTACT_PHONE) && !ItemText(dialog, IDC_CONTACT_PHONE).empty()) {
            AddPhone(dialog, state);
        } else if (SaveContact(dialog, state)) {
            state.done = true;
        }
        return;
    }
    case IDCANCEL:
        state.done = true;
        return;
    case IDC_CONTACT_ADD:
        AddAddress(dialog, state);
        return;
    case IDC_CONTACT_DEFAULT:
        if (hasAddress && address > 0) {
            std::rotate(state.addresses.begin(), state.addresses.begin() + address, state.addresses.begin() + address + 1);
            ShowAddresses(dialog, state, 0);
        }
        return;
    case IDC_CONTACT_REMOVE:
        if (hasAddress) {
            state.addresses.erase(state.addresses.begin() + address);
            ShowAddresses(dialog, state, address);
        }
        return;
    case IDC_CONTACT_PHONE_ADD:
        AddPhone(dialog, state);
        return;
    case IDC_CONTACT_PHONE_REMOVE: {
        int phone = ListView_GetNextItem(GetDlgItem(dialog, IDC_CONTACT_PHONES), -1, LVNI_SELECTED);
        if (phone >= 0 && static_cast<size_t>(phone) < state.phones.size()) {
            state.phones.erase(state.phones.begin() + phone);
            ShowPhones(dialog, state, phone);
        }
        return;
    }
    }
}

// Delete in the addresses takes the selected one out
bool RemoveContactItem(HWND dialog, ContactState& state, HWND list) {
    if (list != GetDlgItem(dialog, IDC_CONTACT_ADDRESSES)) {
        return false;
    }
    OnContactCommand(dialog, state, IDC_CONTACT_REMOVE, BN_CLICKED);
    return true;
}

LRESULT CALLBACK ContactProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {
    return DialogProc<ContactState>(hwnd, message, wParam, lParam, OnContactCommand, RemoveContactItem);
}

// how Contact Properties is laid out, at the DPI
struct ContactLayout {
    int width = Scale(470);
    int pad = Scale(10);
    int gap = Scale(6);
    int row = Scale(22);
    int label = Scale(18);
    int button = Scale(25);
    int addresses = Scale(64);
    int phones = Scale(56);
    int notes = Scale(56);
    int buttonWidth = ButtonWidth({core::T(PE_TEXT_UI_CONTACT_ADD), core::T(PE_TEXT_UI_CONTACT_SET_DEFAULT), core::T(PE_TEXT_UI_REMOVE)}, 90);
    int buttonLeft() const { return width - pad - buttonWidth; }
    int addressesBlock() const { return std::max(addresses, 2 * button + gap); }
    int height() const {
        return pad + 5 * (row + gap) + label + (row + gap) + addressesBlock() + gap + label + (row + gap) + phones + gap + label + notes + pad +
               button + pad;
    }
};

// the names, nickname and company, a label and a box each; the top of what follows
int BuildNames(HWND dialog, const ContactState& state, const ContactLayout& at, int y) {
    int labelWidth = LabelWidth({core::T(PE_TEXT_UI_CONTACT_FIRST), core::T(PE_TEXT_UI_CONTACT_LAST), core::T(PE_TEXT_UI_CONTACT_DISPLAY),
                                 core::T(PE_TEXT_UI_CONTACT_NICKNAME), core::T(PE_TEXT_UI_CONTACT_COMPANY)},
                                100);
    const std::tuple<PeText, int, const std::wstring*> fields[] = {
        {PE_TEXT_UI_CONTACT_FIRST, IDC_CONTACT_FIRST, &state.first},       {PE_TEXT_UI_CONTACT_LAST, IDC_CONTACT_LAST, &state.last},
        {PE_TEXT_UI_CONTACT_DISPLAY, IDC_CONTACT_DISPLAY, &state.display}, {PE_TEXT_UI_CONTACT_NICKNAME, IDC_CONTACT_NICKNAME, &state.nickname},
        {PE_TEXT_UI_CONTACT_COMPANY, IDC_CONTACT_COMPANY, &state.company},
    };
    for (const auto& [label, id, value] : fields) {
        MakeLabel(dialog, core::T(label), {at.pad, y + Scale(3), at.pad + labelWidth, y + at.row});
        MakeEdit(dialog, id, *value, {at.pad + labelWidth, y, at.width - at.pad, y + at.row});
        y += at.row + at.gap;
    }
    return y;
}

// the addresses: one typed and added, the list with the default first, and what can be done to the selected one
int BuildAddresses(HWND dialog, const ContactLayout& at, int y) {
    int left = at.buttonLeft();
    MakeLabel(dialog, core::T(PE_TEXT_UI_CONTACT_ADDRESSES), {at.pad, y, at.width - at.pad, y + at.label});
    y += at.label;
    HWND address = MakeEdit(dialog, IDC_CONTACT_ADDRESS, L"", {at.pad, y, left - at.gap, y + at.row});
    SetAccessibleDescription(address, core::T(PE_TEXT_UI_CONTACT_ADDRESS_HINT));
    MakeButton(dialog, PE_TEXT_UI_CONTACT_ADD, IDC_CONTACT_ADD, left, y - Scale(1), at.buttonWidth);
    y += at.row + at.gap;
    MakeListBox(dialog, IDC_CONTACT_ADDRESSES, {at.pad, y, left - at.gap, y + at.addresses});
    MakeButton(dialog, PE_TEXT_UI_CONTACT_SET_DEFAULT, IDC_CONTACT_DEFAULT, left, y, at.buttonWidth);
    MakeButton(dialog, PE_TEXT_UI_REMOVE, IDC_CONTACT_REMOVE, left, y + at.button + at.gap, at.buttonWidth);
    return y + at.addressesBlock() + at.gap;
}

// the phone numbers: a kind and a number added, the list of them (the buttons' letters are the addresses')
int BuildPhones(HWND dialog, const ContactLayout& at, int y) {
    int left = at.buttonLeft();
    MakeLabel(dialog, core::T(PE_TEXT_UI_CONTACT_PHONES), {at.pad, y, at.width - at.pad, y + at.label});
    y += at.label;
    int kindWidth = Scale(100);
    HWND kinds = CreateChild(dialog, WC_COMBOBOXW, L"", WS_TABSTOP | WS_VSCROLL | CBS_DROPDOWNLIST, IDC_CONTACT_PHONE_KIND,
                             {at.pad, y, at.pad + kindWidth, y + Scale(140)});
    for (const auto& kind : kPhoneKinds) {
        SendMessageW(kinds, CB_ADDSTRING, 0, reinterpret_cast<LPARAM>(core::T(kind.second).c_str()));
    }
    SendMessageW(kinds, CB_SETCURSEL, 0, 0);
    MakeEdit(dialog, IDC_CONTACT_PHONE, L"", {at.pad + kindWidth + at.gap, y, left - at.gap, y + at.row});
    MakeButton(dialog, PE_TEXT_UI_CONTACT_ADD, IDC_CONTACT_PHONE_ADD, left, y - Scale(1), at.buttonWidth, true);
    y += at.row + at.gap;
    HWND phones = CreateChild(dialog, WC_LISTVIEWW, nullptr,
                              WS_TABSTOP | LVS_REPORT | LVS_SINGLESEL | LVS_SHOWSELALWAYS | LVS_NOCOLUMNHEADER, IDC_CONTACT_PHONES,
                              {at.pad, y, left - at.gap, y + at.phones}, WS_EX_CLIENTEDGE);
    ListView_SetExtendedListViewStyle(phones, LVS_EX_FULLROWSELECT);
    AddColumn(phones, 0, L"", 100);
    AddColumn(phones, 1, L"", 100);
    ListView_SetColumnWidth(phones, 1, LVSCW_AUTOSIZE_USEHEADER);
    MakeButton(dialog, PE_TEXT_UI_REMOVE, IDC_CONTACT_PHONE_REMOVE, left, y, at.buttonWidth, true);
    return y + at.phones + at.gap;
}

void BuildNotes(HWND dialog, const ContactState& state, const ContactLayout& at, int y) {
    MakeLabel(dialog, core::T(PE_TEXT_UI_CONTACT_NOTES), {at.pad, y, at.width - at.pad, y + at.label});
    y += at.label;
    MakeEdit(dialog, IDC_CONTACT_NOTES, state.notes, {at.pad, y, at.width - at.pad, y + at.notes},
             ES_MULTILINE | ES_WANTRETURN | ES_AUTOVSCROLL | WS_VSCROLL);
}

// Contact Properties of card `id`, a new one for 0: the id of the card saved, 0 when cancelled
int64_t ContactProperties(HWND owner, PeCore* core, int64_t id) {
    RegisterDialogClass(kContactClass, ContactProc);
    ContactState state;
    LoadContact(core, id, state);
    ContactLayout at;
    int height = at.height();
    std::wstring title = state.id ? core::T(PE_TEXT_UI_CONTACT_TITLE, {{"name", state.display}}) : core::Plain(PE_TEXT_UI_NEW_CONTACT_TITLE);
    HWND dialog = CreateModalWindow(owner, kContactClass, title.c_str(), at.width, height);
    // the boxes are filled as they are made, before their changes reach the window
    int y = BuildNames(dialog, state, at, at.pad);
    y = BuildAddresses(dialog, at, y);
    y = BuildPhones(dialog, at, y);
    BuildNotes(dialog, state, at, y);
    OkCancel(dialog, at.width, height - at.pad - at.button);
    SetWindowLongPtrW(dialog, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(&state));
    ShowAddresses(dialog, state, 0);
    ShowPhones(dialog, state, 0);
    RunModal(dialog, GetDlgItem(dialog, IDC_CONTACT_FIRST), state.done);
    return state.saved;
}

// ---- Group Properties ----

struct GroupState {
    PeCore* core = nullptr;
    int64_t id = 0;
    std::vector<Entry> members;
    int64_t saved = 0;
    bool done = false;
};

void ShowMembers(HWND dialog, const GroupState& state, int select) {
    std::vector<std::wstring> lines;
    for (const Entry& member : state.members) {
        lines.push_back(member.label.empty() ? (member.name.empty() ? member.address : member.name) : member.label);
    }
    FillListBox(GetDlgItem(dialog, IDC_GROUP_MEMBERS), lines, select);
    SetDlgItemTextW(dialog, IDC_GROUP_COUNT,
                    core::T(PE_TEXT_UI_GROUP_MEMBERS_COUNT, {{"count", std::to_wstring(state.members.size())}}).c_str());
}

// members as the core reads them; the strings they point to in `strings`, which must not move meanwhile
std::vector<PeMember> AsMembers(const std::vector<Entry>& entries, std::vector<std::pair<std::string, std::string>>& strings) {
    strings.clear();
    strings.reserve(entries.size());
    for (const Entry& entry : entries) {
        strings.emplace_back(core::Narrow(entry.name), core::Narrow(entry.address));
    }
    std::vector<PeMember> members;
    members.reserve(entries.size());
    for (size_t i = 0; i < entries.size(); i++) {
        members.push_back({entries[i].id, strings[i].first.c_str(), strings[i].second.c_str(), nullptr});
    }
    return members;
}

// `added` into the group, those in it already left out (the core decides who is)
void AddMembers(GroupState& state, const std::vector<Entry>& added) {
    if (added.empty()) {
        return;
    }
    std::vector<std::pair<std::string, std::string>> knownStrings, addedStrings;
    std::vector<PeMember> known = AsMembers(state.members, knownStrings);
    std::vector<PeMember> adding = AsMembers(added, addedStrings);
    std::unique_ptr<bool[]> keep(new bool[added.size()]());
    pe_book_members_add(known.data(), known.size(), adding.data(), adding.size(), keep.get());
    for (size_t i = 0; i < added.size(); i++) {
        if (keep[i]) {
            state.members.push_back(added[i]);
        }
    }
}

// the address typed (if any) into the group; false when it is not an address, which was said
bool AddTypedMember(HWND dialog, GroupState& state) {
    std::wstring typed;
    if (!TypedAddress(dialog, IDC_GROUP_ADDRESS, typed)) {
        return false;
    }
    if (typed.empty()) {
        return true;
    }
    Entry member;
    member.address = typed;
    member.label = typed;
    AddMembers(state, {member});
    SetDlgItemTextW(dialog, IDC_GROUP_ADDRESS, L"");
    ShowMembers(dialog, state, static_cast<int>(state.members.size()) - 1);
    return true;
}

bool SaveGroup(HWND dialog, GroupState& state) {
    if (!AddTypedMember(dialog, state)) {
        return false;
    }
    std::wstring name = ItemText(dialog, IDC_GROUP_NAME);
    if (name.empty()) {
        Warn(dialog, core::T(PE_TEXT_UI_GROUP_NAME_NEEDED));
        SetFocus(GetDlgItem(dialog, IDC_GROUP_NAME));
        return false;
    }
    std::string name8 = core::Narrow(name);
    std::vector<std::pair<std::string, std::string>> strings;
    std::vector<PeMember> members = AsMembers(state.members, strings);
    PeGroup group = {state.id, name8.c_str(), members.data(), members.size()};
    char* error = nullptr;
    int64_t saved = pe_group_save(state.core, &group, &error);
    if (!saved) {
        Warn(dialog, core::T(PE_TEXT_UI_GROUP_NOT_SAVED, {{"reason", ReasonText(error, PE_TEXT_UI_UNKNOWN_REASON)}}));
        return false;
    }
    core::String unused(error);
    state.saved = saved;
    return true;
}

void OnGroupCommand(HWND dialog, GroupState& state, WORD id, WORD) {
    switch (id) {
    case IDOK:
        // Enter in the address box adds it; elsewhere it saves the group
        if (GetFocus() == GetDlgItem(dialog, IDC_GROUP_ADDRESS) && !ItemText(dialog, IDC_GROUP_ADDRESS).empty()) {
            AddTypedMember(dialog, state);
        } else if (SaveGroup(dialog, state)) {
            state.done = true;
        }
        return;
    case IDCANCEL:
        state.done = true;
        return;
    case IDC_GROUP_ADD:
        AddTypedMember(dialog, state);
        return;
    case IDC_GROUP_SELECT: {
        size_t before = state.members.size();
        AddMembers(state, PickMembers(dialog, state.core));
        ShowMembers(dialog, state, static_cast<int>(before));
        return;
    }
    case IDC_GROUP_REMOVE: {
        int index = static_cast<int>(SendDlgItemMessageW(dialog, IDC_GROUP_MEMBERS, LB_GETCURSEL, 0, 0));
        if (index >= 0 && static_cast<size_t>(index) < state.members.size()) {
            state.members.erase(state.members.begin() + index);
            ShowMembers(dialog, state, index);
        }
        return;
    }
    }
}

// Delete in the members takes the selected one out
bool RemoveGroupItem(HWND dialog, GroupState& state, HWND list) {
    if (list != GetDlgItem(dialog, IDC_GROUP_MEMBERS)) {
        return false;
    }
    OnGroupCommand(dialog, state, IDC_GROUP_REMOVE, BN_CLICKED);
    return true;
}

LRESULT CALLBACK GroupProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {
    return DialogProc<GroupState>(hwnd, message, wParam, lParam, OnGroupCommand, RemoveGroupItem);
}

// Group Properties of group `id`, a new one for 0: the id of the group saved, 0 when cancelled
int64_t GroupProperties(HWND owner, PeCore* core, int64_t id) {
    RegisterDialogClass(kGroupClass, GroupProc);
    GroupState state;
    state.core = core;
    std::wstring name;
    if (id) {
        state.members = Members(core, id, name);
        state.id = name.empty() ? 0 : id;
    }
    int pad = Scale(10), gap = Scale(6), rowHeight = Scale(22), labelHeight = Scale(18), buttonHeight = Scale(25);
    int width = Scale(440), membersHeight = Scale(150);
    std::wstring newMember = core::T(PE_TEXT_UI_GROUP_NEW_MEMBER);
    int newMemberHeight = static_cast<int>(MeasureText(newMember, width - 2 * pad).cy) + Scale(4);
    int height = pad + rowHeight + gap + labelHeight + membersHeight + gap + newMemberHeight + rowHeight + pad + buttonHeight + pad;
    std::wstring title = state.id ? core::T(PE_TEXT_UI_GROUP_TITLE, {{"name", name}}) : core::Plain(PE_TEXT_UI_NEW_GROUP_TITLE);
    HWND dialog = CreateModalWindow(owner, kGroupClass, title.c_str(), width, height);
    SetWindowLongPtrW(dialog, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(&state));

    int y = pad;
    std::wstring nameLabel = core::T(PE_TEXT_UI_GROUP_NAME);
    int labelWidth = LabelWidth({nameLabel}, 80);
    MakeLabel(dialog, nameLabel, {pad, y + Scale(3), pad + labelWidth, y + rowHeight});
    MakeEdit(dialog, IDC_GROUP_NAME, name, {pad + labelWidth, y, width - pad, y + rowHeight});
    y += rowHeight + gap;

    int buttonWidth = ButtonWidth({core::T(PE_TEXT_UI_GROUP_SELECT_MEMBERS), core::T(PE_TEXT_UI_REMOVE), core::T(PE_TEXT_UI_CONTACT_ADD)}, 90);
    int buttonLeft = width - pad - buttonWidth;
    std::wstring membersLabel = core::T(PE_TEXT_UI_GROUP_MEMBERS);
    int membersLabelWidth = LabelWidth({membersLabel}, 40);
    MakeLabel(dialog, membersLabel, {pad, y, pad + membersLabelWidth, y + labelHeight});
    // how many, beside the label
    CreateChild(dialog, L"STATIC", L"", SS_LEFT | SS_NOPREFIX, IDC_GROUP_COUNT, {pad + membersLabelWidth, y, buttonLeft - gap, y + labelHeight});
    y += labelHeight;
    MakeListBox(dialog, IDC_GROUP_MEMBERS, {pad, y, buttonLeft - gap, y + membersHeight});
    MakeButton(dialog, PE_TEXT_UI_GROUP_SELECT_MEMBERS, IDC_GROUP_SELECT, buttonLeft, y, buttonWidth);
    MakeButton(dialog, PE_TEXT_UI_REMOVE, IDC_GROUP_REMOVE, buttonLeft, y + buttonHeight + gap, buttonWidth);
    y += membersHeight + gap;

    MakeLabel(dialog, newMember, {pad, y, width - pad, y + newMemberHeight});
    y += newMemberHeight;
    MakeEdit(dialog, IDC_GROUP_ADDRESS, L"", {pad, y, buttonLeft - gap, y + rowHeight});
    MakeButton(dialog, PE_TEXT_UI_CONTACT_ADD, IDC_GROUP_ADD, buttonLeft, y - Scale(1), buttonWidth);
    OkCancel(dialog, width, height - pad - buttonHeight);

    ShowMembers(dialog, state, 0);
    RunModal(dialog, GetDlgItem(dialog, IDC_GROUP_NAME), state.done);
    return state.saved;
}

// ---- the Address Book window ----

struct Book {
    PeCore* core = nullptr;
    HWND hwnd = nullptr;
    HWND toolbar = nullptr;
    HWND findLabel = nullptr;
    HWND find = nullptr;
    HWND tree = nullptr;
    HWND list = nullptr;
    HTREEITEM all = nullptr;
    // the groups of the tree, as Reload read them
    std::vector<Entry> groups;
    // the group shown, 0 for All Contacts, its name and its members as they go in an address field
    int64_t group = 0;
    std::wstring groupName;
    std::wstring groupLabel;
    std::vector<Entry> rows;
    // the control that had the keyboard when the window went to the background
    HWND lastFocus = nullptr;
    // the tree is being filled: its selection changes are not the user's
    bool filling = false;
};

Book* BookOf(HWND hwnd) {
    return reinterpret_cast<Book*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
}

// whether Properties, Delete and Write To have something to work on: a person selected, or a group shown
bool HasTarget(const Book* book) {
    return ListView_GetSelectedCount(book->list) > 0 || book->group != 0;
}

void UpdateButtons(Book* book) {
    bool any = HasTarget(book);
    for (int id : {IDC_BOOK_PROPERTIES, IDC_BOOK_DELETE, IDC_BOOK_WRITE_TO}) {
        SendMessageW(book->toolbar, TB_ENABLEBUTTON, id, MAKELONG(any ? TRUE : FALSE, 0));
    }
}

// the people of the group shown, or of the book, that the find box finds; `select` (a card) selected when it is there
void FillPeople(Book* book, int64_t select = 0) {
    std::wstring filter = Trimmed(GetWindowString(book->find));
    book->rows = book->group ? GroupPeople(book->core, book->group, filter) : Cards(book->core, filter);
    FillList(book->list, book->rows);
    for (size_t i = 0; select && i < book->rows.size(); i++) {
        if (book->rows[i].id == select) {
            SelectRow(book->list, static_cast<int>(i));
            ListView_EnsureVisible(book->list, static_cast<int>(i), FALSE);
        }
    }
    UpdateButtons(book);
}

// group `id` (of those Reload read) is the one shown, 0 for All Contacts
void ShowGroup(Book* book, int64_t id) {
    book->group = 0;
    book->groupName.clear();
    book->groupLabel.clear();
    for (const Entry& entry : book->groups) {
        if (entry.id == id) {
            book->group = id;
            book->groupName = entry.name;
            book->groupLabel = entry.label;
        }
    }
}

// the groups again, `group` selected (All Contacts for 0), and its people
void Reload(Book* book, int64_t group, int64_t selectCard = 0) {
    book->filling = true;
    TreeView_DeleteAllItems(book->tree);
    book->all = InsertItem(book->tree, TVI_ROOT, core::T(PE_TEXT_UI_BOOK_ALL_CONTACTS), 0, false, FOLDER_MAILBOX);
    HTREEITEM chosen = book->all;
    book->groups = Groups(book->core);
    for (const Entry& entry : book->groups) {
        HTREEITEM item = InsertItem(book->tree, TVI_ROOT, entry.name, static_cast<LPARAM>(entry.id), false, FOLDER_MAIL_MULTIPLE);
        if (entry.id == group) {
            chosen = item;
        }
    }
    ShowGroup(book, chosen == book->all ? 0 : group);
    TreeView_SelectItem(book->tree, chosen);
    book->filling = false;
    FillPeople(book, selectCard);
}

// what an action works on: the group selected in the tree when the tree has the keyboard or no person is selected
bool OnGroup(const Book* book) {
    return book->group != 0 && (GetFocus() == book->tree || ListView_GetSelectedCount(book->list) == 0);
}

std::vector<Entry> SelectedPeople(const Book* book) {
    std::vector<Entry> people;
    for (int index : SelectedIndexes(book->list)) {
        if (index >= 0 && static_cast<size_t>(index) < book->rows.size()) {
            people.push_back(book->rows[index]);
        }
    }
    return people;
}

void Properties(Book* book) {
    if (!OnGroup(book)) {
        std::vector<Entry> people = SelectedPeople(book);
        if (!people.empty() && people.front().id) {
            if (int64_t saved = ContactProperties(book->hwnd, book->core, people.front().id)) {
                Reload(book, book->group, saved);
            }
            return;
        }
    }
    // a group, or an address typed into it: the group's Properties
    if (book->group && GroupProperties(book->hwnd, book->core, book->group)) {
        Reload(book, book->group);
    }
}

void Delete(Book* book) {
    const wchar_t* title = L"Inbox Classic";
    if (OnGroup(book)) {
        std::wstring ask = core::T(PE_TEXT_UI_GROUP_DELETE_ASK, {{"name", book->groupName}});
        if (MessageBoxW(book->hwnd, ask.c_str(), title, MB_YESNO | MB_ICONWARNING | MB_DEFBUTTON2) == IDYES) {
            pe_group_delete(book->core, book->group);
            Reload(book, 0);
        }
        return;
    }
    // cards out of the book; addresses typed into the group shown out of the group
    std::vector<int64_t> ids;
    std::vector<std::string> addresses;
    for (const Entry& person : SelectedPeople(book)) {
        if (person.id) {
            ids.push_back(person.id);
        } else {
            addresses.push_back(core::Narrow(person.address));
        }
    }
    size_t count = ids.size() + addresses.size();
    if (count == 0) {
        return;
    }
    std::wstring ask = core::T(PE_TEXT_UI_BOOK_DELETE_ASK, {{"count", std::to_wstring(count)}});
    if (MessageBoxW(book->hwnd, ask.c_str(), title, MB_YESNO | MB_ICONWARNING | MB_DEFBUTTON2) == IDYES) {
        std::vector<const char*> typed;
        for (const std::string& address : addresses) {
            typed.push_back(address.c_str());
        }
        int first = ListView_GetNextItem(book->list, -1, LVNI_SELECTED);
        pe_book_delete(book->core, book->group, ids.data(), ids.size(), typed.data(), typed.size());
        Reload(book, book->group);
        SelectRow(book->list, first);
    }
}

void WriteToSelected(Book* book) {
    std::vector<Entry> recipients;
    if (OnGroup(book)) {
        Entry group;
        group.label = book->groupLabel;
        recipients.push_back(group);
    } else {
        for (const Entry& person : SelectedPeople(book)) {
            if (person.label.empty()) {
                Warn(book->hwnd, core::T(PE_TEXT_UI_BOOK_NO_ADDRESS, {{"name", person.name}}));
            } else {
                recipients.push_back(person);
            }
        }
    }
    std::wstring to = FieldText(L"", recipients);
    if (!to.empty()) {
        WriteTo(to);
    }
}

void OnBookCommand(Book* book, WORD id) {
    switch (id) {
    case IDC_BOOK_NEW_CONTACT:
        if (int64_t saved = ContactProperties(book->hwnd, book->core, 0)) {
            // the find box would hide the new one
            SetWindowTextW(book->find, L"");
            Reload(book, 0, saved);
        }
        return;
    case IDC_BOOK_NEW_GROUP:
        if (int64_t saved = GroupProperties(book->hwnd, book->core, 0)) {
            Reload(book, saved);
        }
        return;
    case IDC_BOOK_PROPERTIES:
        Properties(book);
        return;
    case IDC_BOOK_DELETE:
        Delete(book);
        return;
    case IDC_BOOK_WRITE_TO:
        WriteToSelected(book);
        return;
    case IDOK:
        // Enter on a person or a group opens its Properties
        if (GetFocus() == book->list ? ListView_GetSelectedCount(book->list) > 0 : GetFocus() == book->tree && book->group) {
            Properties(book);
        }
        return;
    case IDCANCEL:
        // Esc closes it
        DestroyWindow(book->hwnd);
        return;
    }
}

// the right-click menu of the people or the groups at `screen` ((-1, -1): the menu key, at the window's corner)
void BookMenu(Book* book, POINT screen) {
    if (screen.x == -1 && screen.y == -1) {
        RECT rect;
        GetWindowRect(GetFocus() == book->tree ? book->tree : book->list, &rect);
        screen = {rect.left + Scale(16), rect.top + Scale(16)};
    }
    UINT on = HasTarget(book) ? MF_ENABLED : MF_GRAYED;
    HMENU menu = CreatePopupMenu();
    AppendMenuW(menu, MF_STRING | on, IDC_BOOK_WRITE_TO, MenuItem(PE_TEXT_UI_MENU_WRITE_TO).c_str());
    AppendMenuW(menu, MF_STRING | on, IDC_BOOK_PROPERTIES, DialogMenuItem(PE_TEXT_UI_PROPERTIES).c_str());
    AppendMenuW(menu, MF_STRING | on, IDC_BOOK_DELETE, MenuItem(PE_TEXT_UI_MENU_DELETE).c_str());
    AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(menu, MF_STRING, IDC_BOOK_NEW_CONTACT, MenuItem(PE_TEXT_UI_MENU_NEW_CONTACT).c_str());
    AppendMenuW(menu, MF_STRING, IDC_BOOK_NEW_GROUP, MenuItem(PE_TEXT_UI_MENU_NEW_GROUP).c_str());
    SetMenuDefaultItem(menu, IDC_BOOK_PROPERTIES, FALSE);
    int chosen = TrackPopupMenu(menu, TPM_RIGHTBUTTON | TPM_RETURNCMD, screen.x, screen.y, 0, book->hwnd, nullptr);
    DestroyMenu(menu);
    if (chosen) {
        OnBookCommand(book, static_cast<WORD>(chosen));
    }
}

// in the middle of the list while it has no one: an empty book, or nothing found for the words
void DrawEmptyBook(const Book* book, HDC dc) {
    std::wstring words = Trimmed(GetWindowString(book->find));
    if (book->group && words.empty()) {
        return;
    }
    std::wstring text = words.empty() ? core::T(PE_TEXT_UI_BOOK_EMPTY) : core::T(PE_TEXT_UI_BOOK_NO_MATCH, {{"words", words}});
    RECT area;
    GetClientRect(book->list, &area);
    RECT header;
    GetWindowRect(ListView_GetHeader(book->list), &header);
    area.top += (header.bottom - header.top) + Scale(24);
    int width = std::min<int>(area.right - area.left - Scale(32), Scale(360));
    area.left = (area.left + area.right - width) / 2;
    area.right = area.left + width;
    HGDIOBJ old = SelectObject(dc, reinterpret_cast<HFONT>(SendMessageW(book->list, WM_GETFONT, 0, 0)));
    SetTextColor(dc, GetSysColor(COLOR_GRAYTEXT));
    SetBkMode(dc, TRANSPARENT);
    DrawTextW(dc, text.c_str(), -1, &area, DT_CENTER | DT_WORDBREAK | DT_NOPREFIX);
    SelectObject(dc, old);
}

bool OnBookNotify(Book* book, NMHDR* header, LRESULT& result) {
    if (header->hwndFrom == book->list) {
        switch (header->code) {
        case NM_CUSTOMDRAW: {
            auto* draw = reinterpret_cast<NMLVCUSTOMDRAW*>(header);
            result = CDRF_DODEFAULT;
            if (draw->nmcd.dwDrawStage == CDDS_PREPAINT) {
                result = CDRF_NOTIFYPOSTPAINT;
            } else if (draw->nmcd.dwDrawStage == CDDS_POSTPAINT && ListView_GetItemCount(book->list) == 0) {
                DrawEmptyBook(book, draw->nmcd.hdc);
            }
            return true;
        }
        case NM_DBLCLK:
        case NM_RETURN:
            if (ListView_GetSelectedCount(book->list) > 0) {
                Properties(book);
            }
            return true;
        case LVN_ITEMCHANGED:
            UpdateButtons(book);
            return true;
        case LVN_KEYDOWN:
            if (reinterpret_cast<NMLVKEYDOWN*>(header)->wVKey == VK_DELETE) {
                Delete(book);
            }
            return true;
        }
    } else if (header->hwndFrom == book->tree) {
        switch (header->code) {
        case TVN_SELCHANGEDW:
            if (!book->filling) {
                auto* change = reinterpret_cast<NMTREEVIEWW*>(header);
                ShowGroup(book, change->itemNew.hItem == book->all ? 0 : static_cast<int64_t>(change->itemNew.lParam));
                FillPeople(book);
            }
            return true;
        case TVN_KEYDOWN:
            if (reinterpret_cast<NMTVKEYDOWN*>(header)->wVKey == VK_DELETE && book->group) {
                Delete(book);
            }
            return true;
        case NM_DBLCLK:
            if (book->group) {
                Properties(book);
            }
            return true;
        }
    }
    return false;
}

void LayoutBook(Book* book) {
    RECT client;
    GetClientRect(book->hwnd, &client);
    SendMessageW(book->toolbar, TB_AUTOSIZE, 0, 0);
    RECT bar;
    GetWindowRect(book->toolbar, &bar);
    int pad = Scale(6), rowHeight = Scale(22);
    int y = bar.bottom - bar.top + pad;
    int labelWidth = TextWidth(book->findLabel, nullptr) + Scale(6);
    MoveWindow(book->findLabel, pad, y + Scale(3), labelWidth, rowHeight, TRUE);
    int findWidth = std::clamp(static_cast<int>(client.right) - 2 * pad - labelWidth, Scale(80), Scale(260));
    MoveWindow(book->find, pad + labelWidth, y, findWidth, rowHeight, TRUE);
    y += rowHeight + pad;
    int treeWidth = Scale(170);
    int bottom = std::max(y, static_cast<int>(client.bottom) - pad);
    MoveWindow(book->tree, pad, y, treeWidth, bottom - y, TRUE);
    int listLeft = pad + treeWidth + Scale(4);
    MoveWindow(book->list, listLeft, y, std::max(0, static_cast<int>(client.right) - pad - listLeft), bottom - y, TRUE);
}

void CreateBook(Book* book) {
    HWND hwnd = book->hwnd;
    // big icons with their words under them, as the main window's toolbar has them
    book->toolbar = CreateBar(hwnd, CCS_TOP | CCS_NODIVIDER, IDC_BOOK_TOOLBAR, BarIcons::Big);
    AddButton(book->toolbar, IDC_BOOK_NEW_CONTACT, core::T(PE_TEXT_UI_TB_NEW_CONTACT).c_str(), BTNS_BUTTON, ICON_PERSON_ADD);
    AddButton(book->toolbar, IDC_BOOK_NEW_GROUP, core::T(PE_TEXT_UI_TB_NEW_GROUP).c_str(), BTNS_BUTTON, ICON_PEOPLE_ADD);
    AddButton(book->toolbar, 0, nullptr);
    AddButton(book->toolbar, IDC_BOOK_PROPERTIES, core::T(PE_TEXT_UI_TB_PROPERTIES).c_str(), BTNS_BUTTON, ICON_CONTACT_CARD);
    AddButton(book->toolbar, IDC_BOOK_DELETE, core::T(PE_TEXT_UI_TB_DELETE).c_str(), BTNS_BUTTON, ICON_DELETE);
    AddButton(book->toolbar, 0, nullptr);
    AddButton(book->toolbar, IDC_BOOK_WRITE_TO, core::T(PE_TEXT_UI_TB_WRITE_TO).c_str(), BTNS_BUTTON, ICON_MAIL_EDIT);
    book->findLabel = CreateChild(hwnd, L"STATIC", core::T(PE_TEXT_UI_BOOK_FIND_HINT).c_str(), SS_LEFT | SS_NOPREFIX, 0, {});
    book->find = CreateChild(hwnd, L"EDIT", L"", WS_TABSTOP | ES_AUTOHSCROLL, IDC_BOOK_FIND, {}, WS_EX_CLIENTEDGE);
    book->tree = CreateChild(hwnd, WC_TREEVIEWW, nullptr, WS_TABSTOP | TVS_SHOWSELALWAYS, IDC_BOOK_TREE, {}, WS_EX_CLIENTEDGE);
    TreeView_SetImageList(book->tree, IconList(IconSet::Folders), TVSIL_NORMAL);
    book->list = CreateChild(hwnd, WC_LISTVIEWW, nullptr, WS_TABSTOP | LVS_REPORT | LVS_SHOWSELALWAYS, IDC_BOOK_LIST, {}, WS_EX_CLIENTEDGE);
    ListView_SetExtendedListViewStyle(book->list, LVS_EX_FULLROWSELECT);
    AddColumn(book->list, 0, core::T(PE_TEXT_UI_COL_NAME).c_str(), 180);
    AddColumn(book->list, 1, core::T(PE_TEXT_UI_COL_EMAIL).c_str(), 200);
    AddColumn(book->list, 2, core::T(PE_TEXT_UI_COL_PHONE).c_str(), 120);
}

LRESULT CALLBACK BookProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {
    Book* book = BookOf(hwnd);
    if (!book) {
        return DefWindowProcW(hwnd, message, wParam, lParam);
    }
    switch (message) {
    case WM_SIZE:
        LayoutBook(book);
        return 0;
    case WM_GETMINMAXINFO: {
        auto* info = reinterpret_cast<MINMAXINFO*>(lParam);
        info->ptMinTrackSize = {Scale(480), Scale(300)};
        return 0;
    }
    case WM_COMMAND:
        if (LOWORD(wParam) == IDC_BOOK_FIND) {
            // what is typed is found among the people shown: the book's, or the group's
            if (HIWORD(wParam) == EN_CHANGE) {
                FillPeople(book);
            }
            return 0;
        }
        OnBookCommand(book, LOWORD(wParam));
        return 0;
    case WM_NOTIFY: {
        LRESULT result = 0;
        if (OnBookNotify(book, reinterpret_cast<NMHDR*>(lParam), result)) {
            return result;
        }
        break;
    }
    case WM_CONTEXTMENU:
        if (reinterpret_cast<HWND>(wParam) == book->list || reinterpret_cast<HWND>(wParam) == book->tree) {
            BookMenu(book, {GET_X_LPARAM(lParam), GET_Y_LPARAM(lParam)});
            return 0;
        }
        break;
    case WM_ACTIVATE:
        // the keyboard where it was when the window comes back
        if (LOWORD(wParam) == WA_INACTIVE) {
            book->lastFocus = GetFocus();
        } else {
            SetFocus(book->lastFocus && IsChild(hwnd, book->lastFocus) ? book->lastFocus : book->list);
        }
        return 0;
    case WM_CTLCOLORSTATIC:
        return ButtonFaceColor(reinterpret_cast<HDC>(wParam));
    case WM_NCDESTROY:
        delete book;
        SetWindowLongPtrW(hwnd, GWLP_USERDATA, 0);
        g_book = nullptr;
        break;
    }
    return DefWindowProcW(hwnd, message, wParam, lParam);
}

}  // namespace

void OpenAddressBook(PeCore* core) {
    if (g_book) {
        if (IsIconic(g_book)) {
            ShowWindow(g_book, SW_RESTORE);
        }
        SetForegroundWindow(g_book);
        return;
    }
    static bool registered = false;
    if (!registered) {
        WNDCLASSEXW windowClass = {sizeof(windowClass)};
        windowClass.lpfnWndProc = BookProc;
        windowClass.hInstance = GetModuleHandleW(nullptr);
        windowClass.hCursor = LoadCursorW(nullptr, IDC_ARROW);
        SetAppIcons(windowClass);
        windowClass.hbrBackground = reinterpret_cast<HBRUSH>(COLOR_BTNFACE + 1);
        windowClass.lpszClassName = kBookClass;
        RegisterClassExW(&windowClass);
        registered = true;
    }
    // a window of its own on the taskbar, as the message windows are
    HWND hwnd = CreateWindowExW(WS_EX_CONTROLPARENT | WS_EX_APPWINDOW, kBookClass, core::Title(PE_TEXT_CMD_ADDRESS_BOOK).c_str(),
                                WS_OVERLAPPEDWINDOW | WS_CLIPCHILDREN, CW_USEDEFAULT, CW_USEDEFAULT, Scale(720), Scale(460), nullptr,
                                nullptr, GetModuleHandleW(nullptr), nullptr);
    if (!hwnd) {
        return;
    }
    auto* book = new Book{core, hwnd};
    SetWindowLongPtrW(hwnd, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(book));
    g_book = hwnd;
    CreateBook(book);
    Reload(book, 0);
    LayoutBook(book);
    ShowWindow(hwnd, SW_SHOW);
    SetFocus(book->list);
}

void AddressBookChanged() {
    if (Book* book = g_book ? BookOf(g_book) : nullptr) {
        Reload(book, book->group);
    }
}

void DestroyAddressBook() {
    if (g_book) {
        DestroyWindow(g_book);
    }
}

bool SelectRecipients(HWND owner, PeCore* core, std::wstring (&fields)[3]) {
    PickState state;
    state.core = core;
    state.mode = PickMode::Recipients;
    if (!RunPick(owner, state)) {
        return false;
    }
    for (int i = 0; i < 3; i++) {
        fields[i] = FieldText(fields[i], state.chosen[i]);
    }
    return true;
}

std::wstring ImportAddressBook(HWND owner, PeCore* core) {
    std::wstring title = core::Title(PE_TEXT_CMD_IMPORT_ADDRESS_BOOK);
    std::vector<std::wstring> files = OpenFilesDialog(
        owner, title.c_str(),
        FileFilter({{core::T(PE_TEXT_UI_FILTER_ADDRESS_BOOKS), L"*.vcf;*.vcard;*.csv"}, {core::T(PE_TEXT_UI_FILTER_ALL), L"*.*"}}).c_str());
    if (files.empty()) {
        return L"";
    }
    std::vector<std::string> paths;
    paths.reserve(files.size());
    for (const std::wstring& file : files) {
        paths.push_back(core::Narrow(file));
    }
    std::vector<const char*> pointers;
    for (const std::string& path : paths) {
        pointers.push_back(path.c_str());
    }
    uint64_t added = 0, skipped = 0;
    char* error = nullptr;
    // the files that could not be read are named in a message; the others are read all the same
    if (!pe_book_import(core, pointers.data(), pointers.size(), &added, &skipped, &error)) {
        std::wstring text = core::T(PE_TEXT_UI_BOOK_NOT_IMPORTED, {{"reason", ReasonText(error, PE_TEXT_UI_UNKNOWN_REASON)}});
        MessageBoxW(owner, text.c_str(), title.c_str(), MB_OK | MB_ICONWARNING);
    } else {
        core::String unused(error);
    }
    AddressBookChanged();
    return core::T(PE_TEXT_UI_BOOK_IMPORTED, {{"added", std::to_wstring(added)}, {"skipped", std::to_wstring(skipped)}});
}

std::wstring ExportAddressBook(HWND owner, PeCore* core) {
    std::wstring title = core::Title(PE_TEXT_CMD_EXPORT_ADDRESS_BOOK);
    std::wstring filter = FileFilter({{core::T(PE_TEXT_UI_FILTER_VCARD), L"*.vcf"}});
    std::wstring path = SaveFileDialog(owner, core::T(PE_TEXT_UI_BOOK_EXPORT_NAME) + L".vcf", title.c_str(), filter.c_str(), L"vcf");
    if (path.empty()) {
        return L"";
    }
    uint64_t written = 0;
    char* error = nullptr;
    if (!pe_book_export(core, nullptr, 0, core::Narrow(path).c_str(), &written, &error)) {
        std::wstring text = core::T(PE_TEXT_UI_BOOK_NOT_EXPORTED, {{"reason", ReasonText(error, PE_TEXT_UI_UNKNOWN_REASON)}});
        MessageBoxW(owner, text.c_str(), title.c_str(), MB_OK | MB_ICONWARNING);
        return L"";
    }
    core::String unused(error);
    return core::T(PE_TEXT_UI_BOOK_EXPORTED, {{"count", std::to_wstring(written)}, {"file", PathFindFileNameW(path.c_str())}});
}
