// C++ side of the Rust core (core/include/inbox_classic.h): owns the strings it returns and converts UTF-8 to the
// UTF-16 of the Windows API. Nothing here parses data, that is the job of the core.
#pragma once

#include <memory>
#include <string>
#include <string_view>

#include <initializer_list>
#include <utility>

#include "inbox_classic.h"
#include "texts.h"

// a read of the core started off the window thread (a reply, a draft, an attachment) and done: the busy pointer over
// the app's windows once one has taken longer than PE_LIST_LOADING_MS, until every one is done
void BusyStart();
void BusyEnd();
// one such read waited for, with the busy pointer while it runs: a newer one, or Reset, cancels it (not on
// destruction: the core may be closed by then)
class PendingRead {
public:
    // `request` (0: it did not start, false) waited for in place of the one before
    bool Start(PeCore* core, uint64_t request) {
        Reset();
        if (!request) {
            return false;
        }
        core_ = core;
        request_ = request;
        BusyStart();
        return true;
    }
    // the read not waited for any more: cancelled
    void Reset() {
        if (request_) {
            pe_read_cancel(core_, std::exchange(request_, 0));
            BusyEnd();
        }
    }
    // whether `request` is the one waited for, which is then done (not waited for any more)
    bool Done(uint64_t request) {
        if (!request_ || request != request_) {
            return false;
        }
        request_ = 0;
        BusyEnd();
        return true;
    }
    explicit operator bool() const { return request_ != 0; }

private:
    PeCore* core_ = nullptr;
    uint64_t request_ = 0;
};

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
using ContactList = std::unique_ptr<PeContactList, Deleter<pe_contact_list_free>>;
using CardList = std::unique_ptr<PeCardList, Deleter<pe_card_list_free>>;
using CardView = std::unique_ptr<PeCardView, Deleter<pe_card_free>>;
using GroupList = std::unique_ptr<PeGroupList, Deleter<pe_group_list_free>>;
using GroupView = std::unique_ptr<PeGroupView, Deleter<pe_group_free>>;
using FolderList = std::unique_ptr<PeFolderList, Deleter<pe_folder_list_free>>;
using FolderTree = std::unique_ptr<PeTree, Deleter<pe_tree_free>>;
using TargetList = std::unique_ptr<PeTargetList, Deleter<pe_target_list_free>>;
using MessageList = std::unique_ptr<PeMessageList, Deleter<pe_message_list_free>>;
using MessageView = std::unique_ptr<PeMessageView, Deleter<pe_message_view_free>>;
using Draft = std::unique_ptr<PeDraft, Deleter<pe_draft_free>>;
using Autoconfig = std::unique_ptr<PeAutoconfig, Deleter<pe_autoconfig_free>>;
using Outbox = std::unique_ptr<PeOutbox, Deleter<pe_outbox_free>>;
using AccountSettings = std::unique_ptr<PeAccountSettingsView, Deleter<pe_account_settings_free>>;
using SignInAppList = std::unique_ptr<PeSignInAppList, Deleter<pe_sign_in_app_list_free>>;
using SignInPresetList = std::unique_ptr<PeSignInPresetList, Deleter<pe_sign_in_preset_list_free>>;
using RuleList = std::unique_ptr<PeRules, Deleter<pe_rules_free>>;
using RuleTargetList = std::unique_ptr<PeRuleTargets, Deleter<pe_rule_targets_free>>;
using AgentConnect = std::unique_ptr<PeAgentConnectInfo, Deleter<pe_agent_connect_free>>;
using AgentSend = std::unique_ptr<PeAgentSendInfo, Deleter<pe_agent_send_free>>;
using AgentUnsubscribe = std::unique_ptr<PeAgentUnsubscribeInfo, Deleter<pe_agent_unsubscribe_free>>;
using AgentHostList = std::unique_ptr<PeAgentHostList, Deleter<pe_agent_host_list_free>>;
using AgentLog = std::unique_ptr<PeAgentLog, Deleter<pe_agent_log_free>>;
using AgentReads = std::unique_ptr<PeAgentReads, Deleter<pe_agent_reads_free>>;
using AgentUndoQuestion = std::unique_ptr<PeAgentUndoQuestionInfo, Deleter<pe_agent_undo_question_free>>;
using Selection = std::unique_ptr<PeSelection, Deleter<pe_selection_free>>;
using Positions = std::unique_ptr<PePositions, Deleter<pe_positions_free>>;
using ListLoad = std::unique_ptr<PeListLoad, Deleter<pe_list_load_free>>;
// what a message list shows (its folder, words, order, grouping and open conversations), kept by the core
using ListView = std::unique_ptr<PeListView, Deleter<pe_list_view_free>>;
using TextList = std::unique_ptr<PeTextList, Deleter<pe_text_list_free>>;
using Export = std::unique_ptr<PeExport, Deleter<pe_export_free>>;
// OpenPGP keys: the key book's rows, the addresses of a key, a correspondent's keys, the keys of own addresses
using KeyList = std::unique_ptr<PeKeyList, Deleter<pe_pgp_key_list_free>>;
using PeerKeys = std::unique_ptr<PePeerKeys, Deleter<pe_pgp_peer_free>>;
using IdentityList = std::unique_ptr<PeIdentityList, Deleter<pe_pgp_identity_list_free>>;
using ComposeSecurity = std::unique_ptr<PeComposeSecurity, Deleter<pe_compose_security_free>>;
using ComposeToggled = std::unique_ptr<PeComposeToggled, Deleter<pe_compose_toggled_free>>;
using FromChoices = std::unique_ptr<PeFromChoices, Deleter<pe_from_choices_free>>;
// a setup file: an export being set up, a file read, the lines of what was done, the app preferences it carries
using SetupExport = std::unique_ptr<PeSetupExport, Deleter<pe_setup_export_free>>;
using SetupFile = std::unique_ptr<PeSetupFile, Deleter<pe_setup_file_free>>;
using SetupLines = std::unique_ptr<PeSetupLines, Deleter<pe_setup_lines_free>>;
using SetupPrefNames = std::unique_ptr<PeSetupPrefNames, Deleter<pe_setup_pref_names_free>>;

std::wstring Widen(std::string_view utf8);
std::string Narrow(std::wstring_view utf16);

std::wstring Version();

// a word of the catalogs (core/locales) in the language in use, `&` marking a menu letter as the catalog has it
// Sets the language of the words (once, at start), and forgets the words looked up before
void SetLanguage(const std::wstring& code);
std::wstring T(PeText text);
// the same without the menu letter marks
std::wstring Plain(PeText text);
// a command as the title of the window it opens: without its menu letter and the "..." that says a window follows
std::wstring Title(PeText text);
// a word with its placeables filled: T(PE_TEXT_X, {{"count", L"3"}, {"folder", name}})
std::wstring T(PeText text, std::initializer_list<std::pair<const char*, std::wstring>> args);

}  // namespace core
