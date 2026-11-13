cmake_minimum_required(VERSION 3.24)
project(InboxClassic LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
# static CRT without the Debug variant, the Rust core is built with +crt-static (core/.cargo/config.toml) to match
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded")

set(CORE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../core)

# the version of the app is the version of the Rust workspace, the first `version = ` line of core/Cargo.toml
file(STRINGS ${CORE_DIR}/Cargo.toml VERSION_LINE REGEX "^version = \"[0-9]+\\.[0-9]+\\.[0-9]+\"" LIMIT_COUNT 1)
string(REGEX MATCH "[0-9]+\\.[0-9]+\\.[0-9]+" APP_VERSION "${VERSION_LINE}")
string(REPLACE "." "," APP_VERSION_COMMAS "${APP_VERSION}")
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS ${CORE_DIR}/Cargo.toml)

# The Rust core as a static library. Cargo runs in core/ so it reads core/.cargo/config.toml, and every build
# runs it, cargo itself knows whether anything changed.
find_program(CARGO cargo HINTS "$ENV{USERPROFILE}/.cargo/bin" "$ENV{HOME}/.cargo/bin" REQUIRED)
set(CARGO_TARGET_DIR ${CMAKE_BINARY_DIR}/cargo)
set(PE_CORE_LIB ${CARGO_TARGET_DIR}/release/pe_ffi.lib)
add_custom_target(pe_core_cargo
    COMMAND ${CARGO} build --release --locked -p pe-ffi --target-dir ${CARGO_TARGET_DIR}
    WORKING_DIRECTORY ${CORE_DIR}
    BYPRODUCTS ${PE_CORE_LIB}
    USES_TERMINAL VERBATIM)

# WebView2 SDK from NuGet, only the headers and the static loader are used
set(WEBVIEW2_VERSION 1.0.4258.31)
set(WEBVIEW2_DIR ${CMAKE_BINARY_DIR}/webview2-${WEBVIEW2_VERSION})
if(NOT EXISTS ${WEBVIEW2_DIR}/build/native/include/WebView2.h)
    file(DOWNLOAD https://www.nuget.org/api/v2/package/Microsoft.Web.WebView2/${WEBVIEW2_VERSION} ${CMAKE_BINARY_DIR}/webview2.nupkg
        TLS_VERIFY ON EXPECTED_HASH SHA256=56f7f4b8bf9aee4b8efefbbdd4f67d5f74ebd1b100ed0806da71bf76af481aa9)
    file(ARCHIVE_EXTRACT INPUT ${CMAKE_BINARY_DIR}/webview2.nupkg DESTINATION ${WEBVIEW2_DIR})
endif()


add_executable(InboxClassic WIN32
    src/main.cpp
    src/addressbook.cpp
    src/accounts.cpp
    src/agents.cpp
    src/signinapps.cpp
    src/compose.cpp
    src/complete.cpp
    src/tray.cpp
    src/editor.cpp
    src/core.cpp
    src/help.cpp
    src/options.cpp
    src/outbox.cpp
    src/mailbox.cpp
    src/messagewindow.cpp
    src/reader.cpp
    src/folderpicker.cpp
    src/folderpane.cpp
    src/columnrow.cpp
    src/dragdrop.cpp
    src/ui.cpp
    src/preview.cpp
    src/print.cpp
    src/webview.cpp
    res/app.rc
)
add_dependencies(InboxClassic pe_core_cargo)

target_include_directories(InboxClassic PRIVATE src ${CORE_DIR}/include ${WEBVIEW2_DIR}/build/native/include)
target_compile_definitions(InboxClassic PRIVATE UNICODE _UNICODE WIN32_LEAN_AND_MEAN NOMINMAX
    APP_VERSION="${APP_VERSION}" APP_VERSION_COMMAS=${APP_VERSION_COMMAS})
target_compile_options(InboxClassic PRIVATE /W4 /utf-8 /permissive-)
target_link_libraries(InboxClassic PRIVATE
    ${PE_CORE_LIB}
    # what the Rust standard library needs on Windows (cargo rustc -p pe-ffi -- --print native-static-libs)
    kernel32 advapi32 ntdll userenv ws2_32 dbghelp bcrypt
    ${WEBVIEW2_DIR}/build/native/x64/WebView2LoaderStatic.lib
    comctl32 comdlg32 shlwapi shell32 ole32 version windowscodecs msimg32 oleacc
)
# the manifest comes from app.rc
target_link_options(InboxClassic PRIVATE /MANIFEST:NO)
