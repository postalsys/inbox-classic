// WebView2 for message bodies. The documents come from the Rust core (pe_html_render) sanitized and with a
// Content-Security-Policy that allows only embedded images; on top of that scripts are off, every http(s) request is
// refused here and links open in the default browser instead of in the pane. The C++ side never changes a document.
#include "preview.h"

#include <shellapi.h>
#include <shlwapi.h>

#include <algorithm>
#include <climits>
#include <cmath>
#include <cstring>
#include <cwctype>
#include <map>
#include <memory>
#include <utility>

#include "app.h"
#include "core.h"
#include "webview.h"

using Microsoft::WRL::Callback;
using Microsoft::WRL::ComPtr;
using webview::OpenExternally;
using webview::StartsWith;

namespace {

// where the documents are served from memory (webview.h); .invalid never resolves
const wchar_t* kPageUrl = L"https://preview.inboxclassic.invalid/";

// where the page asks for the pictures of the previews of attachments (root-relative /pv/ in the document)
const wchar_t* kPreviewsUrl = L"https://preview.inboxclassic.invalid/pv/";

// the Previews keeping a request for each ask, until the core answers it
std::map<uint64_t, Preview*> g_asks;

// the UI test's looks at the previews: the pictures (how many, how many loaded, how many are PDF pages, a notice), and
// the middle of a file's first picture (or the link to all of a PDF file's pages), scrolled into view, in pixels of
// the pane
const wchar_t* kPreviewsState =
    L"(()=>{const s=document.querySelector('section[class^=\"pe-att-\"]');"
    L"const a=[...document.images].filter(i=>i.src.includes('/pv/'));"
    L"const l=a.filter(i=>i.complete&&i.naturalWidth>0).length,p=a.filter(i=>i.classList.contains('p')).length;"
    L"return a.length*1000000+l*10000+p*100+(s&&s.querySelector('.w')?1:0)})()";
std::wstring PreviewsPoint(const wchar_t* element) {
    return std::wstring(L"(()=>{const f=document.querySelectorAll('section[class^=\"pe-att-\"] figure');const e=") + element +
           L";if(!e)return 0;e.scrollIntoView({block:'center'});const r=e.getBoundingClientRect(),d=devicePixelRatio;"
           L"return Math.round((r.left+r.width/2)*d)*100000+Math.round((r.top+r.height/2)*d)})()";
}

// the same looks in the frame of part `n` (from 1) of a signed or encrypted message: its pictures (how many, how many
// loaded, whether its first file is named `name`), or the middle of its first picture, in pixels of the pane
std::wstring PartPreviews(int n, const std::wstring& name) {
    return L"(()=>{const f=document.querySelectorAll('iframe.pe-d')[" + std::to_wstring(n - 1) +
           L"];const d=f&&f.contentDocument;if(!d)return 0;const a=[...d.images].filter(i=>i.src.includes('/pv/'));"
           L"const l=a.filter(i=>i.complete&&i.naturalWidth>0).length,c=d.querySelector('figure .n');"
           L"return a.length*100+l*10+(c&&c.textContent==='" +
           name + L"'?1:0)})()";
}
// (or of its first link to the web, `link`)
std::wstring PartPreviewPoint(int n, bool link = false) {
    return L"(()=>{const f=document.querySelectorAll('iframe.pe-d')[" + std::to_wstring(n - 1) +
           L"];const e=f&&f.contentDocument&&f.contentDocument.querySelector('" +
           (link ? L"a[href^=\"http\"]" : L"figure img") + L"');if(!e)return 0;"
           L"e.scrollIntoView({block:'center'});const o=f.getBoundingClientRect(),r=e.getBoundingClientRect(),d=devicePixelRatio;"
           L"return Math.round((o.left+f.clientLeft+r.left+r.width/2)*d)*100000+Math.round((o.top+f.clientTop+r.top+r.height/2)*d)})()";
}

// the letters of a file's name in a look, nothing that would end the script's string
std::wstring NameOnly(const std::wstring& text) {
    std::wstring name;
    for (wchar_t c : text) {
        if (iswalnum(c) || c == L' ' || c == L'.' || c == L'-' || c == L'_') {
            name += c;
        }
    }
    return name;
}

// the UI test's look at a page of parts: how many frames, whether each is as tall as its document, their heights
const wchar_t* kFramesCheck =
    L"(()=>{let n=0,fit=100,sum=0;for(const f of document.querySelectorAll('iframe')){n++;const d=f.contentDocument;"
    L"const h=d&&d.documentElement?d.documentElement.scrollHeight:1e9;if(f.offsetHeight<h)fit=0;sum+=f.offsetHeight}"
    L"return n+fit+1000*sum})()";

// the core's script that sizes each frame to its document
const std::wstring& MeasureScript() {
    static const std::wstring script = core::Widen(pe_measure_script());
    return script;
}

}  // namespace

void Preview::Create(HWND parent, std::function<void(const std::wstring&)> onError, HWND owner, UINT_PTR findTimer) {
    parent_ = parent;
    owner_ = owner;
    findTimer_ = findTimer;
    onError_ = std::move(onError);
    std::shared_ptr<bool> alive = alive_;
    webview::Create(
        parent_,
        [this, alive](ICoreWebView2Environment* environment, ICoreWebView2Controller* controller) {
            if (!*alive) {
                controller->Close();
                return;
            }
            environment_ = environment;
            controller_ = controller;
            controller_->get_CoreWebView2(&view_);
            Configure();
        },
        [this, alive](const std::wstring& error) {
            if (*alive) {
                onError_(error + L" " + core::T(PE_TEXT_WIN_NO_BODIES));
            }
        });
}

void Preview::Configure() {
    // a click in the document or the keyboard to it, for the stack (stack.h)
    controller_->add_GotFocus(Callback<ICoreWebView2FocusChangedEventHandler>([this](ICoreWebView2Controller*, IUnknown*) {
                                  if (focused_) {
                                      focused_();
                                  }
                                  return S_OK;
                              }).Get(),
                              nullptr);
    // View > Text Size changed its size, for the stack (stack.h): the document's height with it
    controller_->add_ZoomFactorChanged(Callback<ICoreWebView2ZoomFactorChangedEventHandler>([this](ICoreWebView2Controller*, IUnknown*) {
                                           if (zoomed_) {
                                               zoomed_();
                                           }
                                           return S_OK;
                                       }).Get(),
                                       nullptr);
    ComPtr<ICoreWebView2Settings> settings;
    view_->get_Settings(&settings);
    settings->put_IsScriptEnabled(FALSE);
    settings->put_AreDefaultScriptDialogsEnabled(FALSE);
    settings->put_IsWebMessageEnabled(FALSE);
    settings->put_AreHostObjectsAllowed(FALSE);
    settings->put_AreDevToolsEnabled(FALSE);
    settings->put_IsStatusBarEnabled(FALSE);
    // View > Text Size, and none of the web view's own zoom
    settings->put_IsZoomControlEnabled(FALSE);
    if (textZoom_) {
        webview::TrackTextZoom(controller_.Get());
    }
    // the classic light look, also when Windows uses dark mode: the labels of a signed or encrypted message's parts
    // in the colours of the security bar over them
    ComPtr<ICoreWebView2_13> withProfile;
    ComPtr<ICoreWebView2Profile> profile;
    if (SUCCEEDED(view_.As(&withProfile)) && SUCCEEDED(withProfile->get_Profile(&profile)) && profile) {
        profile->put_PreferredColorScheme(COREWEBVIEW2_PREFERRED_COLOR_SCHEME_LIGHT);
    }

    // the document from memory; nothing from the network, also not what a CSP would let through, but images when the
    // user asked for them
    webview::FilterRequests(
        view_.Get(), environment_.Get(), kPageUrl, [this]() -> const std::wstring& { return document_; },
        [this](const wchar_t* uri, COREWEBVIEW2_WEB_RESOURCE_CONTEXT context) {
            if ((StartsWith(uri, L"http://") || StartsWith(uri, L"https://")) && !StartsWith(uri, kPageUrl)) {
                remoteRequests_++;
            }
            return remoteImages_ && webview::IsRemoteImage(uri, context, kPageUrl);
        },
        // the parts' documents, beside the page: the core says which part an address asks for
        [this](const wchar_t* uri, std::string& document) {
            int64_t index = pe_part_document(core::Narrow(uri).c_str());
            if (index < 0) {
                return false;
            }
            if (static_cast<size_t>(index) < parts_.size()) {
                document = parts_[static_cast<size_t>(index)];
            }
            return true;
        },
        // the pictures of the previews, answered once the core has them
        [this](const wchar_t* uri, ICoreWebView2WebResourceRequestedEventArgs* args) { return AskPreview(uri, args); });
    TrimMenu();

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
    // a part's frame (a signed or encrypted message's) loads its document beside the page, by the page's doing only.
    // A link clicked in it navigates the top page (the part's <base target="_top">), which NavigationStarting above
    // cancels and follows: a link to the browser, a preview to its file. Should a navigation of the frame itself come,
    // it leaves the frame where it is: a preview of the part's files opens its file (the core takes only a link whose
    // token is that part's), any other link opens in the browser, never as one of the page's own links, which only the
    // page's labels are
    view_->add_FrameNavigationStarting(
        Callback<ICoreWebView2NavigationStartingEventHandler>([this](ICoreWebView2*, ICoreWebView2NavigationStartingEventArgs* args) {
            LPWSTR uri = nullptr;
            args->get_Uri(&uri);
            BOOL user = FALSE;
            args->get_IsUserInitiated(&user);
            bool part = !user && StartsWith(uri, kPageUrl) && pe_part_document(core::Narrow(uri).c_str()) >= 0;
            if (!part && !StartsWith(uri, L"about:")) {
                args->put_Cancel(TRUE);
                if (user && uri && pe_reader_link(core::Narrow(uri).c_str()) == PE_READER_LINK_ATTACHMENT) {
                    Follow(uri);
                } else if (user) {
                    OpenExternally(uri);
                }
            }
            CoTaskMemFree(uri);
            return S_OK;
        }).Get(),
        nullptr);
    // the frames of a page of parts sized once it loaded, its frames' documents with it
    view_->add_NavigationCompleted(Callback<ICoreWebView2NavigationCompletedEventHandler>([this](ICoreWebView2*, ICoreWebView2NavigationCompletedEventArgs*) {
                                       // the newest document's own load done, not one it replaced (Loaded)
                                       LPWSTR source = nullptr;
                                       if (SUCCEEDED(view_->get_Source(&source)) && source) {
                                           if (std::wstring(kPageUrl) + std::to_wstring(shown_) + L"/" == source) {
                                               loaded_ = shown_;
                                           }
                                           CoTaskMemFree(source);
                                       }
                                       Measure();
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
            } else if (kind == COREWEBVIEW2_KEY_EVENT_KIND_SYSTEM_KEY_DOWN && key >= 'A' && key <= 'Z' && mnemonics_ &&
                       ClickMnemonic(GetAncestor(parent_, GA_ROOT), static_cast<wchar_t>(key))) {
                // Alt with a letter while the message has the keyboard: a button of its window that has it (Details)
                args->put_Handled(TRUE);
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
        // the document given before, with the token of its previews
        Load();
    } else {
        Clear();
    }
}

bool Preview::AskPreview(const wchar_t* uri, ICoreWebView2WebResourceRequestedEventArgs* args) {
    if (!core_ || !StartsWith(uri, kPreviewsUrl)) {
        return false;
    }
    // the core only looks the address up here; the picture is read and drawn off this thread, PreviewAnswered follows
    uint64_t ask = pe_preview_ask(core_, core::Narrow(uri).c_str());
    ComPtr<ICoreWebView2Deferral> deferral;
    if (ask && SUCCEEDED(args->GetDeferral(&deferral)) && deferral) {
        waiting_[ask] = {args, deferral};
        g_asks[ask] = this;
        return true;
    }
    // no preview of the document shown (or one the core answers to nobody, then dropped in Answered)
    if (auto response = NotFound()) {
        args->put_Response(response.Get());
    }
    return true;
}

ComPtr<ICoreWebView2WebResourceResponse> Preview::NotFound() const {
    ComPtr<ICoreWebView2WebResourceResponse> response;
    if (environment_) {
        environment_->CreateWebResourceResponse(nullptr, 404, L"Not Found", L"", &response);
    }
    return response;
}

void Preview::Answered(PeCore* core, uint64_t ask) {
    PePreviewAnswer* answer = pe_preview_answer(core, ask);
    if (auto found = g_asks.find(ask); found != g_asks.end()) {
        Preview* preview = found->second;
        g_asks.erase(found);
        preview->Answer(ask, pe_preview_answer_picture(answer));
    }
    pe_preview_answer_free(answer);
}

void Preview::Answer(uint64_t ask, const PePreviewPicture* picture) {
    auto found = waiting_.find(ask);
    if (found == waiting_.end()) {
        return;
    }
    Waiting request = std::move(found->second);
    waiting_.erase(found);
    ComPtr<ICoreWebView2WebResourceResponse> response;
    // the core's own encode, one of two types
    bool known = picture && picture->mime_type &&
                 (std::strcmp(picture->mime_type, "image/png") == 0 || std::strcmp(picture->mime_type, "image/jpeg") == 0);
    if (environment_ && known && picture->bytes && picture->length > 0 && picture->length <= UINT_MAX) {
        ComPtr<IStream> stream;
        stream.Attach(SHCreateMemStream(picture->bytes, static_cast<UINT>(picture->length)));
        std::wstring headers = L"Content-Type: " + core::Widen(picture->mime_type) + L"\r\nCache-Control: no-store";
        if (stream) {
            environment_->CreateWebResourceResponse(stream.Get(), 200, L"OK", headers.c_str(), &response);
        }
    }
    if (!response) {
        response = NotFound();
    }
    if (response) {
        request.args->put_Response(response.Get());
    }
    request.deferral->Complete();
}

void Preview::EndPreviews() {
    if (core_ && !previewToken_.empty()) {
        pe_previews_end(core_, previewToken_.c_str());
    }
    previewToken_.clear();
    // finished now: the core's answers to them, which follow, find nobody waiting
    std::map<uint64_t, Waiting> waiting = std::exchange(waiting_, {});
    for (const auto& [ask, request] : waiting) {
        g_asks.erase(ask);
        if (auto response = NotFound()) {
            request.args->put_Response(response.Get());
        }
        request.deferral->Complete();
    }
}

namespace {

// whether the menu's target is a picture the core drew: one served from /pv/, or one whose address WebView2 does not
// tell (it gives none for a picture in a link, and every picture of the text is the core's but those of the internet
// after Download Pictures)
bool CorePicture(ICoreWebView2ContextMenuTarget* target) {
    COREWEBVIEW2_CONTEXT_MENU_TARGET_KIND kind = COREWEBVIEW2_CONTEXT_MENU_TARGET_KIND_PAGE;
    BOOL has = FALSE;
    LPWSTR uri = nullptr;
    if (FAILED(target->get_Kind(&kind)) || kind != COREWEBVIEW2_CONTEXT_MENU_TARGET_KIND_IMAGE) {
        return false;
    }
    if (FAILED(target->get_HasSourceUri(&has)) || !has || FAILED(target->get_SourceUri(&uri))) {
        return true;
    }
    bool preview = StartsWith(uri, kPreviewsUrl);
    CoTaskMemFree(uri);
    return preview;
}

// whether the menu's target is in a preview's link (inboxclassic:attachment-), which only the app opens
bool PreviewLink(ICoreWebView2ContextMenuTarget* target) {
    BOOL has = FALSE;
    LPWSTR uri = nullptr;
    if (FAILED(target->get_HasLinkUri(&has)) || !has || FAILED(target->get_LinkUri(&uri))) {
        return false;
    }
    bool preview = StartsWith(uri, L"inboxclassic:attachment-");
    CoTaskMemFree(uri);
    return preview;
}

}  // namespace

void Preview::TrimMenu() {
    ComPtr<ICoreWebView2_11> view;
    if (FAILED(view_.As(&view))) {
        return;
    }
    view->add_ContextMenuRequested(
        Callback<ICoreWebView2ContextMenuRequestedEventHandler>([this](ICoreWebView2*, ICoreWebView2ContextMenuRequestedEventArgs* args) {
            testMenu_ = 1000;
            ComPtr<ICoreWebView2ContextMenuTarget> target;
            if (FAILED(args->get_ContextMenuTarget(&target)) || !target) {
                return S_OK;
            }
            // a picture the core drew (a preview of a file, or a picture in the text) is Inbox Classic's copy, not
            // the file: nothing saves or opens it as if it were, Copy Image stays; a preview's link opens the file in
            // the app, nothing copies or opens it elsewhere, while a picture's link to the web keeps its items
            bool image = CorePicture(target.Get());
            bool link = PreviewLink(target.Get());
            ComPtr<ICoreWebView2ContextMenuItemCollection> items;
            UINT32 count = 0;
            if (FAILED(args->get_MenuItems(&items)) || !items || FAILED(items->get_Count(&count))) {
                return S_OK;
            }
            for (UINT32 i = count; i-- > 0;) {
                ComPtr<ICoreWebView2ContextMenuItem> item;
                LPWSTR name = nullptr;
                if (FAILED(items->GetValueAtIndex(i, &item)) || FAILED(item->get_Name(&name)) || !name) {
                    continue;
                }
                std::wstring kind = name;
                CoTaskMemFree(name);
                bool imageItem = kind.find(L"Image") != std::wstring::npos && kind != L"copyImage";
                bool linkItem = kind == L"saveLinkAs" || kind == L"copyLinkLocation" || kind == L"openLinkInNewWindow";
                if ((image && imageItem) || (link && linkItem)) {
                    items->RemoveValueAtIndex(i);
                } else {
                    testMenu_ += kind == L"copyLinkLocation" ? 100 : kind == L"copyImage" ? 10 : imageItem ? 1 : 0;
                }
            }
            return S_OK;
        }).Get(),
        nullptr);
}

int64_t Preview::TestPreviews(const std::wstring& query) {
    if (query == L"menu") {
        return testMenu_;
    }
    std::wstring script;
    if (query == L"state") {
        script = kPreviewsState;
    } else if (query == L"inline") {
        // the pictures of the text: none from a data: or cid: address, the first served from /pv/ and its width
        script = L"(()=>{const i=[...document.images],s=e=>e.getAttribute('src')||'',b=i[0];"
                 L"return i.filter(e=>/^(data|cid):/i.test(s(e))).length*100000+"
                 L"(b&&s(b).startsWith('/pv/')?10000:0)+(b&&b.complete?b.naturalWidth:0)})()";
    } else if (query == L"banner") {
        script = PreviewsPoint(L"document.images[0]");
    } else if (query == L"photo") {
        script = PreviewsPoint(L"f[0]&&f[0].querySelector('img')");
    } else if (query == L"second") {
        script = PreviewsPoint(L"f[1]&&f[1].querySelector('img')");
    } else if (query == L"last") {
        script = PreviewsPoint(L"f[f.length-1]&&f[f.length-1].querySelector('img')");
    } else if (query == L"overflow") {
        // how far the page is wider than the pane, 0 when it fits
        script = L"Math.max(0,document.documentElement.scrollWidth-document.documentElement.clientWidth)";
    } else if (query == L"findkey") {
        // Find Key beside a part's label, 0 when the page has none
        script = PreviewsPoint(L"document.querySelector('a.pe-f')");
    } else if (query == L"more") {
        script = PreviewsPoint(L"document.querySelector('section[class^=\"pe-att-\"] a.m')");
    } else if (query == L"tiles") {
        // the files shown as tiles, times 100, plus how many of them say why
        script = L"(()=>{const t=[...document.querySelectorAll('section[class^=\"pe-att-\"] a.t')];"
                 L"return t.length*100+t.filter(a=>(a.querySelector('.r')||{}).textContent).length})()";
    } else if (query.starts_with(L"part:") && query.size() > 7) {
        // "part:N:name", the pictures of part N's frame and whether its file is that one
        script = PartPreviews(query[5] - L'0', NameOnly(query.substr(7)));
    } else if (query.starts_with(L"partpoint:") && query.size() == 11) {
        script = PartPreviewPoint(query[10] - L'0');
    } else if (query.starts_with(L"partlink:") && query.size() == 10) {
        script = PartPreviewPoint(query[9] - L'0', true);
    } else if (query.starts_with(L"partframe:") && query.size() == 11) {
        // part N's label and frame scrolled to the top of the pane
        script = L"(()=>{const f=document.querySelectorAll('iframe.pe-d')[" + std::to_wstring(query[10] - L'1') +
                 L"];if(!f)return 0;f.parentElement.scrollIntoView({block:'start'});return 1})()";
    } else if (query.starts_with(L"text:")) {
        // whether the document's text has the words after the colon: 2, else 1
        std::wstring words;
        for (wchar_t c : query.substr(5)) {
            if (iswalnum(c) || c == L' ') {
                words += c;
            }
        }
        script = L"document.body&&document.body.innerText.includes('" + words + L"')?2:1";
    } else if (query == L"scroll" || query.starts_with(L"scroll:")) {
        // scrolled to a place first (a number only), then how far it is, plus 1 so the top is an answer too
        std::wstring to = query.size() > 7 ? std::to_wstring(_wtoi(query.c_str() + 7)) : L"";
        script = (to.empty() ? L"" : L"window.scrollTo(0," + to + L");") + L"Math.round(window.scrollY||0)+1";
    } else {
        return -1;
    }
    auto last = testPreviews_.find(query);
    int64_t answer = last != testPreviews_.end() ? last->second : -1;
    testPreviews_.erase(query);
    if (view_) {
        view_->ExecuteScript(script.c_str(), Callback<ICoreWebView2ExecuteScriptCompletedHandler>([this, query](HRESULT result, LPCWSTR json) {
                                                 testPreviews_[query] = SUCCEEDED(result) && json ? _wtoi64(json) : -1;
                                                 return S_OK;
                                             }).Get());
    }
    // a point in the pane, on the screen
    if (answer > 0 && query != L"state" && query != L"overflow" && query != L"tiles" && query != L"inline" && !query.starts_with(L"scroll") &&
        !query.starts_with(L"text:") && !query.starts_with(L"part:") &&
        !query.starts_with(L"partframe:")) {
        POINT origin = {bounds_.left, bounds_.top};
        ClientToScreen(parent_, &origin);
        answer = (origin.x + answer / 100000) * 100000 + origin.y + answer % 100000;
    }
    return answer;
}

void Preview::Follow(const wchar_t* uri) {
    if (uri && links_ && links_(uri)) {
        return;
    }
    OpenExternally(uri);
}

void Preview::Show(const std::wstring& html, bool remoteImages, std::vector<std::string> parts, const char* previewToken) {
    // the places found were in the document before, its previews too
    StopFind();
    EndPreviews();
    previewToken_ = previewToken ? previewToken : "";
    remoteImages_ = remoteImages;
    parts_ = std::move(parts);
    remoteRequests_ = 0;
    testFrames_ = -1;
    document_ = html;
    if (!view_) {
        pending_ = true;
        return;
    }
    Load();
}

void Preview::Load() {
    pending_ = false;
    // a new address for each document, so it is loaded again rather than taken from history; a folder, so the frames of
    // a page of parts ask for theirs beside it (part-N)
    std::wstring url = std::wstring(kPageUrl) + std::to_wstring(++shown_) + L"/";
    view_->Navigate(url.c_str());
}

void Preview::Measure() {
    // the page's own scripts are off (IsScriptEnabled); a script the app runs still runs
    if (view_ && !parts_.empty()) {
        view_->ExecuteScript(MeasureScript().c_str(), nullptr);
    }
}

void Preview::MeasureHeight(std::function<void(int pixels)> done) {
    if (!view_ || !controller_) {
        return;
    }
    static const std::wstring script = core::Widen(pe_height_script());
    ComPtr<ICoreWebView2Controller> controller = controller_;
    view_->ExecuteScript(script.c_str(), Callback<ICoreWebView2ExecuteScriptCompletedHandler>([controller, done](HRESULT result, LPCWSTR json) {
                             double css = SUCCEEDED(result) && json ? _wtof(json) : 0;
                             if (css <= 0) {
                                 return S_OK;
                             }
                             double zoom = 1, scale = 1;
                             controller->get_ZoomFactor(&zoom);
                             ComPtr<ICoreWebView2Controller3> scaled;
                             if (SUCCEEDED(controller.As(&scaled))) {
                                 scaled->get_RasterizationScale(&scale);
                             }
                             done(static_cast<int>(std::ceil(css * zoom * scale)));
                             return S_OK;
                         }).Get());
}

void Preview::OnFocus(std::function<void()> focused) {
    focused_ = std::move(focused);
}

void Preview::OnZoom(std::function<void()> zoomed) {
    zoomed_ = std::move(zoomed);
}

int64_t Preview::TestFrames() {
    int64_t last = testFrames_;
    if (view_) {
        view_->ExecuteScript(kFramesCheck, Callback<ICoreWebView2ExecuteScriptCompletedHandler>([this](HRESULT result, LPCWSTR json) {
                                               testFrames_ = SUCCEEDED(result) && json ? _wtoi64(json) : -1;
                                               return S_OK;
                                           }).Get());
    }
    return last;
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
    *alive_ = false;
    StopFind();
    EndPreviews();
    if (controller_) {
        webview::UntrackTextZoom(controller_.Get());
        controller_->Close();
    }
    view_.Reset();
    controller_.Reset();
    environment_.Reset();
}
