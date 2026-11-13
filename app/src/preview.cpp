// WebView2 for message bodies. The documents come from the Rust core (pe_html_render) sanitized and with a
// Content-Security-Policy that allows only embedded images; on top of that scripts are off, every http(s) request is
// refused here and links open in the default browser instead of in the pane. The C++ side never changes a document.
#include "preview.h"

#include <shellapi.h>

#include <algorithm>
#include <utility>

#include "core.h"
#include "webview.h"

using Microsoft::WRL::Callback;
using Microsoft::WRL::ComPtr;
using webview::OpenExternally;
using webview::StartsWith;

namespace {

// where the documents are served from memory (webview.h); .invalid never resolves
const wchar_t* kPageUrl = L"https://preview.inboxclassic.invalid/";


}  // namespace

void Preview::Create(HWND parent, std::function<void(const std::wstring&)> onError, HWND owner, UINT_PTR findTimer) {
    parent_ = parent;
    owner_ = owner;
    findTimer_ = findTimer;
    onError_ = std::move(onError);
    webview::Create(
        parent_,
        [this](ICoreWebView2Environment* environment, ICoreWebView2Controller* controller) {
            environment_ = environment;
            controller_ = controller;
            controller_->get_CoreWebView2(&view_);
            Configure();
        },
        [this](const std::wstring& error) { onError_(error + L" " + core::T(PE_TEXT_WIN_NO_BODIES)); });
}

void Preview::Configure() {
    ComPtr<ICoreWebView2Settings> settings;
    view_->get_Settings(&settings);
    settings->put_IsScriptEnabled(FALSE);
    settings->put_AreDefaultScriptDialogsEnabled(FALSE);
    settings->put_IsWebMessageEnabled(FALSE);
    settings->put_AreHostObjectsAllowed(FALSE);
    settings->put_AreDevToolsEnabled(FALSE);
    settings->put_IsStatusBarEnabled(FALSE);
    settings->put_IsZoomControlEnabled(TRUE);

    // the document from memory; nothing from the network, also not what a CSP would let through, but images when the
    // user asked for them
    webview::FilterRequests(
        view_.Get(), environment_.Get(), kPageUrl, [this]() -> const std::wstring& { return document_; },
        [this](const wchar_t* uri, COREWEBVIEW2_WEB_RESOURCE_CONTEXT context) {
            return remoteImages_ && webview::IsRemoteImage(uri, context, kPageUrl);
        });

    // links open in the browser, the pane only ever shows the documents it is given
    view_->add_NavigationStarting(
        Callback<ICoreWebView2NavigationStartingEventHandler>([this](ICoreWebView2*, ICoreWebView2NavigationStartingEventArgs* args) {
            LPWSTR uri = nullptr;
            args->get_Uri(&uri);
            if (!webview::IsOwnPage(uri, kPageUrl)) {
                args->put_Cancel(TRUE);
                BOOL user = FALSE;
                args->get_IsUserInitiated(&user);
                // a relative link of the message points into the made-up address, not anywhere
                if (user && !StartsWith(uri, kPageUrl)) {
                    Follow(uri);
                }
            }
            CoTaskMemFree(uri);
            return S_OK;
        }).Get(),
        nullptr);
    view_->add_NewWindowRequested(
        Callback<ICoreWebView2NewWindowRequestedEventHandler>([this](ICoreWebView2*, ICoreWebView2NewWindowRequestedEventArgs* args) {
            LPWSTR uri = nullptr;
            args->get_Uri(&uri);
            args->put_Handled(TRUE);
            Follow(uri);
            CoTaskMemFree(uri);
            return S_OK;
        }).Get(),
        nullptr);

    controller_->add_AcceleratorKeyPressed(
        Callback<ICoreWebView2AcceleratorKeyPressedEventHandler>([this](ICoreWebView2Controller*, ICoreWebView2AcceleratorKeyPressedEventArgs* args) {
            COREWEBVIEW2_KEY_EVENT_KIND kind;
            UINT key = 0;
            args->get_KeyEventKind(&kind);
            args->get_VirtualKey(&key);
            if (kind == COREWEBVIEW2_KEY_EVENT_KIND_KEY_DOWN && key == VK_F1) {
                // the help of the window, as F1 in any of its controls opens it (the message loop takes the key)
                args->put_Handled(TRUE);
                PostMessageW(GetAncestor(parent_, GA_ROOT), WM_KEYDOWN, VK_F1, 0);
            } else if (keys_ && kind == COREWEBVIEW2_KEY_EVENT_KIND_KEY_DOWN && keys_(key)) {
                args->put_Handled(TRUE);
            }
            return S_OK;
        }).Get(),
        nullptr);

    // Tab past the first or last link of the document: on to the window's next or previous control, as from any other
    HWND root = GetAncestor(parent_, GA_ROOT);
    if (root != parent_) {
        controller_->add_MoveFocusRequested(
            Callback<ICoreWebView2MoveFocusRequestedEventHandler>(
                [this, root](ICoreWebView2Controller*, ICoreWebView2MoveFocusRequestedEventArgs* args) {
                    COREWEBVIEW2_MOVE_FOCUS_REASON reason;
                    args->get_Reason(&reason);
                    HWND next = GetNextDlgTabItem(root, parent_, reason == COREWEBVIEW2_MOVE_FOCUS_REASON_PREVIOUS);
                    if (next && next != parent_) {
                        SetFocus(next);
                        args->put_Handled(TRUE);
                    }
                    return S_OK;
                })
                .Get(),
            nullptr);
    }

    controller_->put_Bounds(bounds_);
    controller_->put_IsVisible(IsWindowVisible(parent_) ? TRUE : FALSE);
    if (std::exchange(focusPending_, false) && GetFocus() == parent_) {
        controller_->MoveFocus(COREWEBVIEW2_MOVE_FOCUS_REASON_PROGRAMMATIC);
    }
    if (pending_) {
        Show(document_, remoteImages_);
    } else {
        Clear();
    }
}

void Preview::Follow(const wchar_t* uri) {
    if (uri && links_ && links_(uri)) {
        return;
    }
    OpenExternally(uri);
}

void Preview::Show(const std::wstring& html, bool remoteImages) {
    // the places found were in the document before
    StopFind();
    remoteImages_ = remoteImages;
    document_ = html;
    if (!view_) {
        pending_ = true;
        return;
    }
    pending_ = false;
    // a new address for each document, so it is loaded again rather than taken from history
    std::wstring url = std::wstring(kPageUrl) + L"?" + std::to_wstring(++shown_);
    view_->Navigate(url.c_str());
}

void Preview::Clear(bool noMessage) {
    if (noMessage) {
        ShowState(PE_READER_STATE_NO_MESSAGE);
        return;
    }
    // white like the documents of messages, also when Windows uses dark mode
    Show(L"<!doctype html><html><head><meta name=\"color-scheme\" content=\"light\"><style>html{background:#fff}</style>"
         L"</head><body></body></html>");
}

void Preview::ShowState(PeReaderState state, PeFailureKind failure, const std::string& reason, uint64_t size) {
    core::String page(pe_reader_page(state, failure, reason.c_str(), size));
    Show(page ? core::Widen(page.get()) : L"");
}

void Preview::Focus(FocusFrom from) {
    if (!controller_) {
        focusPending_ = true;
        return;
    }
    controller_->MoveFocus(from == FocusFrom::Start  ? COREWEBVIEW2_MOVE_FOCUS_REASON_NEXT
                           : from == FocusFrom::End  ? COREWEBVIEW2_MOVE_FOCUS_REASON_PREVIOUS
                                                     : COREWEBVIEW2_MOVE_FOCUS_REASON_PROGRAMMATIC);
}

void Preview::SetVisible(bool visible) {
    if (controller_) {
        controller_->put_IsVisible(visible ? TRUE : FALSE);
    }
}

void Preview::Print() {
    ComPtr<ICoreWebView2_16> printing;
    if (view_ && SUCCEEDED(view_.As(&printing))) {
        printing->ShowPrintUI(COREWEBVIEW2_PRINT_DIALOG_KIND_BROWSER);
    }
}

void Preview::Resize(const RECT& bounds) {
    bounds_ = bounds;
    if (controller_) {
        controller_->put_Bounds(bounds);
    }
}

void Preview::Find(const std::wstring& words, std::function<void(int count)> done) {
    StopFind();
    ComPtr<ICoreWebView2_28> view;
    ComPtr<ICoreWebView2Environment15> environment;
    ComPtr<ICoreWebView2Find> find;
    ComPtr<ICoreWebView2FindOptions> options;
    if (!view_ || FAILED(view_.As(&view)) || FAILED(environment_.As(&environment)) || FAILED(view->get_Find(&find)) || !find ||
        FAILED(environment->CreateFindOptions(&options)) || !options) {
        done(-1);
        return;
    }
    options->put_FindTerm(words.c_str());
    // the app says what was found; the browser's own find bar stays away
    options->put_SuppressDefaultFindDialog(TRUE);
    options->put_ShouldHighlightAllMatches(TRUE);
    find_ = find;
    findDone_ = std::move(done);
    // the count can come after the find has started: told once there is a place, or after a moment as it is then
    find_->add_MatchCountChanged(
        Callback<ICoreWebView2FindMatchCountChangedEventHandler>([this](ICoreWebView2Find* sender, IUnknown*) {
            INT32 count = 0;
            if (sender == find_.Get() && SUCCEEDED(sender->get_MatchCount(&count))) {
                FoundCount(count, false);
            }
            return S_OK;
        }).Get(),
        nullptr);
    find_->Start(options.Get(), Callback<ICoreWebView2FindStartCompletedHandler>([this, find](HRESULT result) {
                     if (find.Get() != find_.Get()) {
                         return S_OK;
                     }
                     INT32 count = 0;
                     if (FAILED(result)) {
                         FoundCount(-1, true);
                     } else if (SUCCEEDED(find->get_MatchCount(&count))) {
                         FoundCount(count, false);
                     }
                     if (findDone_ && owner_) {
                         SetTimer(owner_, findTimer_, 500, nullptr);
                     }
                     return S_OK;
                 }).Get());
}

void Preview::FoundCount(int count, bool settled) {
    if (!findDone_ || (count <= 0 && !settled)) {
        return;
    }
    KillTimer(owner_, findTimer_);
    found_ = std::max(count, 0);
    auto done = std::exchange(findDone_, nullptr);
    done(count);
}

void Preview::FindSettled() {
    KillTimer(owner_, findTimer_);
    INT32 count = 0;
    if (find_ && SUCCEEDED(find_->get_MatchCount(&count))) {
        FoundCount(std::max(count, 0), true);
    }
}

bool Preview::FindNext() {
    return find_ && SUCCEEDED(find_->FindNext());
}

void Preview::StopFind() {
    if (find_) {
        find_->Stop();
        find_.Reset();
    }
    findDone_ = nullptr;
    found_ = 0;
    if (owner_) {
        KillTimer(owner_, findTimer_);
    }
}

void Preview::Close() {
    StopFind();
    if (controller_) {
        controller_->Close();
    }
    view_.Reset();
    controller_.Reset();
    environment_.Reset();
}
