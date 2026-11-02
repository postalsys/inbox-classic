#include "core.h"

#include <windows.h>

namespace core {

std::wstring Widen(std::string_view utf8) {
    if (utf8.empty()) {
        return {};
    }
    int length = MultiByteToWideChar(CP_UTF8, 0, utf8.data(), static_cast<int>(utf8.size()), nullptr, 0);
    std::wstring out(length, L'\0');
    MultiByteToWideChar(CP_UTF8, 0, utf8.data(), static_cast<int>(utf8.size()), out.data(), length);
    return out;
}

std::string Narrow(std::wstring_view utf16) {
    if (utf16.empty()) {
        return {};
    }
    int length = WideCharToMultiByte(CP_UTF8, 0, utf16.data(), static_cast<int>(utf16.size()), nullptr, 0, nullptr, nullptr);
    std::string out(length, '\0');
    WideCharToMultiByte(CP_UTF8, 0, utf16.data(), static_cast<int>(utf16.size()), out.data(), length, nullptr, nullptr);
    return out;
}

std::wstring Version() {
    return Widen(pe_version());
}

std::wstring RenderHtml(std::string_view html, bool remoteImages) {
    String document(pe_html_render(reinterpret_cast<const uint8_t*>(html.data()), html.size(), remoteImages));
    return document ? Widen(document.get()) : std::wstring();
}

}  // namespace core
