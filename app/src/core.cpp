#include "core.h"

#include <windows.h>

#include <mutex>
#include <unordered_map>
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

namespace {
// the words without placeables, looked up once: the language only changes with a restart, and menus and paints ask
// for the same words again and again
std::mutex g_wordsLock;
std::unordered_map<uint32_t, std::wstring> g_words, g_plainWords;

std::wstring Cached(std::unordered_map<uint32_t, std::wstring>& cache, PeText text, char* (*lookup)(uint32_t)) {
    std::lock_guard lock(g_wordsLock);
    auto found = cache.find(static_cast<uint32_t>(text));
    if (found == cache.end()) {
        found = cache.emplace(static_cast<uint32_t>(text), Taken(lookup(static_cast<uint32_t>(text)))).first;
    }
    return found->second;
}
}  // namespace

void SetLanguage(const std::wstring& code) {
    String used(pe_set_language(Narrow(code).c_str()));
    std::lock_guard lock(g_wordsLock);
    g_words.clear();
    g_plainWords.clear();
}

std::wstring T(PeText text) {
    return Cached(g_words, text, pe_text);
}

std::wstring Plain(PeText text) {
    return Cached(g_plainWords, text, pe_text_plain);
}

std::wstring Title(PeText text) {
    return Taken(pe_text_title(static_cast<uint32_t>(text)));
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
