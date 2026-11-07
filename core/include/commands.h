// Generated from core/commands.toml by core/crates/pe-ffi/build.rs, do not edit
#pragma once

#include "texts.h"

// the commands of the menus, toolbar and tray, posted as WM_COMMAND
enum PeCommandId : unsigned short {
    IDM_NEW_ACCOUNT = 100,
    IDM_EXIT = 101,
    IDM_SYNC = 102,
    IDM_UNDO = 135,
    IDM_SELECT_ALL = 134,
    IDM_MARK_READ = 103,
    IDM_MARK_UNREAD = 104,
    IDM_PICTURES = 105,
    IDM_ABOUT = 106,
    IDM_NEW_MAIL = 107,
    IDM_REPLY = 108,
    IDM_REPLY_ALL = 109,
    IDM_FORWARD = 110,
    IDM_HELP = 111,
    IDM_DELETE = 112,
    IDM_MOVE = 113,
    IDM_COPY = 136,
    IDM_FLAG = 114,
    IDM_NEW_FOLDER = 115,
    IDM_RENAME_FOLDER = 116,
    IDM_DELETE_FOLDER = 117,
    IDM_ACCOUNTS = 118,
    IDM_FIND = 120,
    IDM_SAVE_AS = 121,
    IDM_PRINT = 122,
    IDM_IMPORT = 123,
    IDM_OUTBOX = 124,
    IDM_PROPERTIES = 125,
    IDM_MARK_ALL_READ = 126,
    IDM_JUNK = 127,
    IDM_NOT_JUNK = 128,
    IDM_ARCHIVE = 138,
    IDM_NOTIFY = 129,
    IDM_OPEN = 130,
    IDM_DEFAULT_APP = 131,
    IDM_VIEW_SOURCE = 132,
    IDM_AI_AGENTS = 133,
    IDM_OPTIONS = 137,
};

// whether a command acts on one message only, off while several are selected
inline bool CommandNeedsOne(unsigned id) {
    switch (id) {
    case IDM_PICTURES:
    case IDM_REPLY:
    case IDM_REPLY_ALL:
    case IDM_PRINT:
    case IDM_PROPERTIES:
    case IDM_VIEW_SOURCE:
        return true;
    default:
        return false;
    }
}

// whether a command acts on one or several messages: off with none selected
inline bool CommandNeedsSome(unsigned id) {
    switch (id) {
    case IDM_FORWARD:
    case IDM_SAVE_AS:
        return true;
    default:
        return false;
    }
}

// the label of a command in the catalog (& marks the menu letter): pe_text(CommandText(IDM_...))
inline PeText CommandText(PeCommandId id) {
    switch (id) {
    case IDM_NEW_ACCOUNT: return PE_TEXT_CMD_NEW_ACCOUNT;
    case IDM_EXIT: return PE_TEXT_CMD_EXIT;
    case IDM_SYNC: return PE_TEXT_CMD_SYNC;
    case IDM_UNDO: return PE_TEXT_CMD_UNDO;
    case IDM_SELECT_ALL: return PE_TEXT_CMD_SELECT_ALL;
    case IDM_MARK_READ: return PE_TEXT_CMD_MARK_READ;
    case IDM_MARK_UNREAD: return PE_TEXT_CMD_MARK_UNREAD;
    case IDM_PICTURES: return PE_TEXT_CMD_PICTURES;
    case IDM_ABOUT: return PE_TEXT_CMD_ABOUT;
    case IDM_NEW_MAIL: return PE_TEXT_CMD_NEW_MAIL;
    case IDM_REPLY: return PE_TEXT_CMD_REPLY;
    case IDM_REPLY_ALL: return PE_TEXT_CMD_REPLY_ALL;
    case IDM_FORWARD: return PE_TEXT_CMD_FORWARD;
    case IDM_HELP: return PE_TEXT_CMD_HELP;
    case IDM_DELETE: return PE_TEXT_CMD_DELETE;
    case IDM_MOVE: return PE_TEXT_CMD_MOVE;
    case IDM_COPY: return PE_TEXT_CMD_COPY;
    case IDM_FLAG: return PE_TEXT_CMD_FLAG;
    case IDM_NEW_FOLDER: return PE_TEXT_CMD_NEW_FOLDER;
    case IDM_RENAME_FOLDER: return PE_TEXT_CMD_RENAME_FOLDER;
    case IDM_DELETE_FOLDER: return PE_TEXT_CMD_DELETE_FOLDER;
    case IDM_ACCOUNTS: return PE_TEXT_CMD_ACCOUNTS;
    case IDM_FIND: return PE_TEXT_CMD_FIND;
    case IDM_SAVE_AS: return PE_TEXT_CMD_SAVE_AS;
    case IDM_PRINT: return PE_TEXT_CMD_PRINT;
    case IDM_IMPORT: return PE_TEXT_CMD_IMPORT;
    case IDM_OUTBOX: return PE_TEXT_CMD_OUTBOX;
    case IDM_PROPERTIES: return PE_TEXT_CMD_PROPERTIES;
    case IDM_MARK_ALL_READ: return PE_TEXT_CMD_MARK_ALL_READ;
    case IDM_JUNK: return PE_TEXT_CMD_JUNK;
    case IDM_NOT_JUNK: return PE_TEXT_CMD_NOT_JUNK;
    case IDM_ARCHIVE: return PE_TEXT_CMD_ARCHIVE;
    case IDM_NOTIFY: return PE_TEXT_CMD_NOTIFY;
    case IDM_OPEN: return PE_TEXT_CMD_OPEN;
    case IDM_DEFAULT_APP: return PE_TEXT_CMD_DEFAULT_APP;
    case IDM_VIEW_SOURCE: return PE_TEXT_CMD_VIEW_SOURCE;
    case IDM_AI_AGENTS: return PE_TEXT_CMD_AI_AGENTS;
    case IDM_OPTIONS: return PE_TEXT_CMD_OPTIONS;
    }
    return PE_TEXT_CMD_NEW_ACCOUNT;
}
