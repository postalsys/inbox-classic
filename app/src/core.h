// C++ side of the Rust core (core/include/postal_express.h): owns the strings it returns and converts UTF-8 to the
// UTF-16 of the Windows API. Nothing here parses data, that is the job of the core.
#pragma once

#include <memory>
#include <string>
#include <string_view>

#include "postal_express.h"

namespace core {

struct StringDeleter {
    void operator()(char* text) const { pe_string_free(text); }
};
// a string returned by the core, freed by the core
using String = std::unique_ptr<char, StringDeleter>;

std::wstring Widen(std::string_view utf8);
std::string Narrow(std::wstring_view utf16);

std::wstring Version();
// a sanitized document for the preview, empty when the core failed
std::wstring RenderHtml(std::string_view html, bool remoteImages);

}  // namespace core
