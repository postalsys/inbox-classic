// C++ side of the Rust core (core/include/inbox_classic.h): owns the strings it returns and converts UTF-8 to the
// UTF-16 of the Windows API. Nothing here parses data, that is the job of the core.
#pragma once

#include <memory>
#include <string>
#include <string_view>

#include "inbox_classic.h"

namespace core {

// frees what the core returned with the core's own function
template <auto Free>
struct Deleter {
    template <typename T>
    void operator()(T* value) const { Free(value); }
};

// a string returned by the core
using String = std::unique_ptr<char, Deleter<pe_string_free>>;
// handles returned by the core
using Core = std::unique_ptr<PeCore, Deleter<pe_core_close>>;
using AccountList = std::unique_ptr<PeAccountList, Deleter<pe_account_list_free>>;
using FolderList = std::unique_ptr<PeFolderList, Deleter<pe_folder_list_free>>;
using MessageList = std::unique_ptr<PeMessageList, Deleter<pe_message_list_free>>;
using MessageView = std::unique_ptr<PeMessageView, Deleter<pe_message_view_free>>;
using Draft = std::unique_ptr<PeDraft, Deleter<pe_draft_free>>;
using Autoconfig = std::unique_ptr<PeAutoconfig, Deleter<pe_autoconfig_free>>;
using Outbox = std::unique_ptr<PeOutbox, Deleter<pe_outbox_free>>;
using AccountSettings = std::unique_ptr<PeAccountSettingsView, Deleter<pe_account_settings_free>>;
using SignInAppList = std::unique_ptr<PeSignInAppList, Deleter<pe_sign_in_app_list_free>>;
using SignInPresetList = std::unique_ptr<PeSignInPresetList, Deleter<pe_sign_in_preset_list_free>>;

std::wstring Widen(std::string_view utf8);
std::string Narrow(std::wstring_view utf16);

std::wstring Version();

}  // namespace core
