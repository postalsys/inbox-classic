#include "core.h"

#include <windows.h>

#include <vector>

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

namespace {
std::wstring Taken(char* text) {
    String held(text);
    return held ? Widen(held.get()) : std::wstring();
}
}  // namespace

std::wstring T(PeText text) {
    return Taken(pe_text(static_cast<uint32_t>(text)));
}

std::wstring Plain(PeText text) {
    return Taken(pe_text_plain(static_cast<uint32_t>(text)));
}

std::wstring T(PeText text, std::initializer_list<std::pair<const char*, std::wstring>> args) {
    std::vector<std::string> values;
    std::vector<const char*> names;
    values.reserve(args.size());
    for (const auto& [name, value] : args) {
        names.push_back(name);
        values.push_back(Narrow(value));
    }
    std::vector<const char*> pointers;
    for (const auto& value : values) {
        pointers.push_back(value.c_str());
    }
    return Taken(pe_text_args(static_cast<uint32_t>(text), names.data(), pointers.data(), names.size()));
}


}  // namespace core
