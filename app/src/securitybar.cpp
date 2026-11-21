// The security bar over a signed or encrypted message (reader.cpp places it) and its Details window. The bar's tone,
// words and Details text are the core's (PeMessageInfo.protection*); this file only draws them.
#include "app.h"
#include "icons.h"

#include <algorithm>

namespace {

// the colors of a tone, as the labels of the message's parts have them (pe-html secure.rs)
struct ToneLook {
    COLORREF frame;
    COLORREF fill;
    COLORREF words;
    IconSet icons;
    // its own picture, -1 for none (a part that is neither signed nor known: its words say so)
    int picture;
};

const ToneLook& ColorsOf(PeProtectionTone tone) {
    static const ToneLook verified = {RGB(0x2e, 0x7d, 0x32), RGB(0xe8, 0xf5, 0xe9), RGB(0x1b, 0x5e, 0x20), IconSet::SecureVerified,
                                        SECURE_SHIELD_CHECKMARK};
    static const ToneLook good = {RGB(0x1f, 0x5f, 0xae), RGB(0xe6, 0xee, 0xfa), RGB(0x17, 0x4a, 0x87), IconSet::SecureGood, SECURE_RIBBON};
    static const ToneLook warning = {RGB(0xb2, 0x6a, 0x00), RGB(0xff, 0xf4, 0xe0), RGB(0x7a, 0x48, 0x00), IconSet::SecureWarning,
                                       SECURE_WARNING};
    static const ToneLook neutral = {RGB(0x9e, 0x9e, 0x9e), RGB(0xf2, 0xf2, 0xf2), RGB(0x44, 0x44, 0x44), IconSet::SecureNeutral, -1};
    switch (tone) {
    case PE_PROTECTION_TONE_VERIFIED:
        return verified;
    case PE_PROTECTION_TONE_GOOD:
        return good;
    case PE_PROTECTION_TONE_WARNING:
        return warning;
    default:
        return neutral;
    }
}

// the pictures of a state, left to right: the lock of an encrypted message, then the tone's own
std::vector<int> PicturesOf(PeProtectionTone tone, bool encrypted) {
    std::vector<int> pictures;
    if (encrypted) {
        pictures.push_back(SECURE_LOCK_CLOSED);
    }
    if (int own = ColorsOf(tone).picture; own >= 0) {
        pictures.push_back(own);
    }
    return pictures;
}

int IconSize(PeProtectionTone tone) {
    int cx = 0, cy = 0;
    ImageList_GetIconSize(IconList(ColorsOf(tone).icons), &cx, &cy);
    return cx;
}

// where the words start: after the pictures
int WordsLeft(PeProtectionTone tone, bool encrypted) {
    size_t count = PicturesOf(tone, encrypted).size();
    int left = Scale(8);
    if (count > 0) {
        left += static_cast<int>(count) * (IconSize(tone) + Scale(3)) + Scale(4);
    }
    return left;
}

constexpr UINT kWordsFormat = DT_WORDBREAK | DT_NOPREFIX | DT_LEFT;

int WordsHeight(HDC dc, HFONT font, const std::wstring& words, int width) {
    HGDIOBJ old = SelectObject(dc, font);
    RECT bounds = {0, 0, std::max(width, 1), 0};
    DrawTextW(dc, words.c_str(), static_cast<int>(words.size()), &bounds, DT_CALCRECT | kWordsFormat);
    SelectObject(dc, old);
    return bounds.bottom - bounds.top;
}

}  // namespace

ToneColors TonePalette(PeProtectionTone tone) {
    const ToneLook& look = ColorsOf(tone);
    return {look.frame, look.fill, look.words};
}

IconSet RecipientKeySet(const PeComposeRecipient& recipient) {
    return ColorsOf(recipient.tone).icons;
}

int RecipientKeyPicture(const PeComposeRecipient& recipient) {
    // the lock while it is looked up, grey
    return recipient.has_key || recipient.key == PE_RECIPIENT_KEY_LOOKING ? SECURE_LOCK_CLOSED : SECURE_WARNING;
}

int SecurityBarHeight(PeProtectionTone tone, bool encrypted, const std::wstring& words, HFONT font, int width, int reserved) {
    HDC dc = GetDC(nullptr);
    int wordsWidth = width - WordsLeft(tone, encrypted) - reserved - Scale(8);
    int height = WordsHeight(dc, font, words, wordsWidth);
    ReleaseDC(nullptr, dc);
    // one line is as tall as the Details button with room around it, so the bar keeps its height from message to
    // message; more lines make it taller
    return std::max(Scale(23) + 2 * Scale(4), height + 2 * Scale(7));
}

void DrawSecurityBar(HDC dc, const RECT& area, PeProtectionTone tone, bool encrypted, const std::wstring& words, HFONT font, int reserved) {
    const ToneLook& colors = ColorsOf(tone);
    HBRUSH fill = CreateSolidBrush(colors.fill);
    FillRect(dc, &area, fill);
    DeleteObject(fill);
    HBRUSH frame = CreateSolidBrush(colors.frame);
    FrameRect(dc, &area, frame);
    DeleteObject(frame);
    // the pictures, in the middle of the first line's height
    HIMAGELIST icons = IconList(colors.icons);
    int size = IconSize(tone);
    int x = area.left + Scale(8);
    int y = area.top + (area.bottom - area.top - size) / 2;
    for (int picture : PicturesOf(tone, encrypted)) {
        ImageList_Draw(icons, picture, dc, x, y, ILD_NORMAL);
        x += size + Scale(3);
    }
    RECT text = {area.left + WordsLeft(tone, encrypted), area.top, area.right - reserved - Scale(8), area.bottom};
    int height = WordsHeight(dc, font, words, text.right - text.left);
    text.top = area.top + std::max(0L, (area.bottom - area.top - height) / 2);
    HGDIOBJ old = SelectObject(dc, font);
    SetBkMode(dc, TRANSPARENT);
    SetTextColor(dc, colors.words);
    DrawTextW(dc, words.c_str(), static_cast<int>(words.size()), &text, kWordsFormat);
    SelectObject(dc, old);
}

// ---- the Details window ----

namespace {

const wchar_t* kDetailsClass = L"InboxClassicSecurityDetails";

struct DetailsState {
    bool done = false;
    PeProtectionTone tone = PE_PROTECTION_TONE_NONE;
    bool encrypted = false;
    std::wstring summary;
    HFONT bold = nullptr;
};

LRESULT CALLBACK DetailsProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {
    auto* state = reinterpret_cast<DetailsState*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
    if (!state) {
        return DefWindowProcW(hwnd, message, wParam, lParam);
    }
    switch (message) {
    case WM_COMMAND:
        if (LOWORD(wParam) == IDOK || LOWORD(wParam) == IDCANCEL) {
            state->done = true;
        }
        return 0;
    case WM_CLOSE:
        state->done = true;
        return 0;
    case WM_DRAWITEM: {
        // the state at the top, as the bar over the message shows it
        const auto& item = *reinterpret_cast<const DRAWITEMSTRUCT*>(lParam);
        DrawSecurityBar(item.hDC, item.rcItem, state->tone, state->encrypted, state->summary, state->bold, 0);
        return TRUE;
    }
    case WM_CTLCOLORSTATIC:
        // the read-only text white, as a document is
        SetBkColor(reinterpret_cast<HDC>(wParam), GetSysColor(COLOR_WINDOW));
        return reinterpret_cast<LRESULT>(GetSysColorBrush(COLOR_WINDOW));
    }
    return DefWindowProcW(hwnd, message, wParam, lParam);
}

// the parts of the text as an edit box shows them, without the summary the bar at the top shows (the first line,
// as the core writes it), and where part `part` (0 the first, -1 none) starts in it: each part follows an empty line
std::wstring BoxText(const std::wstring& summary, const std::wstring& details, int part, int& start) {
    std::wstring rest = details;
    int skip = part;
    if (rest.rfind(summary + L"\n\n", 0) == 0) {
        rest.erase(0, summary.size() + 2);
    } else if (part >= 0) {
        skip++;
    }
    std::wstring text = WithCrlf(rest);
    start = 0;
    size_t at = 0;
    for (int i = 0; i < skip; i++) {
        at = text.find(L"\r\n\r\n", at);
        if (at == std::wstring::npos) {
            return text;
        }
        at += 4;
    }
    start = static_cast<int>(at);
    return text;
}

}  // namespace

void SecurityDetailsDialog(HWND owner, PeProtectionTone tone, bool encrypted, const std::wstring& summary, const std::wstring& details,
                           int part) {
    RegisterDialogClass(kDetailsClass, DetailsProc);
    DetailsState state;
    state.tone = tone;
    state.encrypted = encrypted;
    state.summary = summary;
    LOGFONTW font = {};
    GetObjectW(UiFont(), sizeof(font), &font);
    font.lfWeight = FW_BOLD;
    state.bold = CreateFontIndirectW(&font);

    int pad = Scale(10), width = Scale(500);
    int barHeight = SecurityBarHeight(tone, encrypted, summary, state.bold, width - 2 * pad, 0);
    // the text as tall as it is, up to a size that leaves the window on any screen; longer, it scrolls
    int boxWidth = width - 2 * pad;
    HDC dc = GetDC(nullptr);
    int textHeight = WordsHeight(dc, UiFont(), details,
                                 boxWidth - GetSystemMetrics(SM_CXVSCROLL) - Scale(10));
    ReleaseDC(nullptr, dc);
    int boxHeight = std::clamp(textHeight + Scale(12), Scale(110), Scale(380));
    int buttonHeight = Scale(23);
    int height = pad + barHeight + Scale(8) + boxHeight + Scale(10) + buttonHeight + pad;

    HelpScope help("protection-details");
    HWND dialog = CreateModalWindow(owner, kDetailsClass, core::Plain(PE_TEXT_UI_PROTECTION_DETAILS_TITLE).c_str(), width, height);
    SetWindowLongPtrW(dialog, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(&state));
    int top = pad;
    // its words are its name, for a screen reader
    CreateChild(dialog, L"STATIC", summary.c_str(), SS_OWNERDRAW | SS_NOPREFIX, IDC_SECURITY_BAR, {pad, top, width - pad, top + barHeight});
    top += barHeight + Scale(8);
    int start = 0;
    std::wstring text = BoxText(summary, details, part, start);
    HWND box = CreateChild(dialog, L"EDIT", text.c_str(), WS_TABSTOP | WS_VSCROLL | ES_MULTILINE | ES_READONLY | ES_AUTOVSCROLL,
                           IDC_SECURITY_DETAILS, {pad, top, width - pad, top + boxHeight}, WS_EX_CLIENTEDGE);
    SendMessageW(box, EM_SETMARGINS, EC_LEFTMARGIN | EC_RIGHTMARGIN, MAKELONG(Scale(4), Scale(4)));
    std::wstring close = core::T(PE_TEXT_UI_CLOSE);
    int closeWidth = ButtonWidth({close});
    CreateChild(dialog, L"BUTTON", close.c_str(), WS_TABSTOP | BS_DEFPUSHBUTTON, IDCANCEL,
                {width - pad - closeWidth, height - pad - buttonHeight, width - pad, height - pad});
    // the part whose label was clicked at the top of the text
    SendMessageW(box, EM_SETSEL, start, start);
    SendMessageW(box, EM_LINESCROLL, 0, SendMessageW(box, EM_LINEFROMCHAR, start, 0));
    RunModal(dialog, box, state.done);
    DeleteObject(state.bold);
}
