# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

PostalExpress is a Windows email client that looks like Outlook Express. It is a sibling of ImapKit Desktop (`../imapkit-win`), which has the same classic Win32 look but runs a Node.js sidecar. PostalExpress has no sidecar: IMAP, SMTP and MIME run in-process in a Rust core.

## Security model (the reason for the architecture)

Everything a remote party writes (IMAP responses, message headers and bodies, attachment names, autoconfig XML, DNS answers) is parsed only in Rust. The C++ code never parses remote data; it shows values the core has already decoded and validated, and passes sanitized HTML to WebView2 without changing it. Keep the C++ side minimal: new logic that touches mail data belongs in `core/`, not `app/`.

- **Rust (`core/`)**: IMAP, SMTP, MIME parsing and building, charsets, HTML sanitizing, the local store, `.eml` import and export, account autodiscovery, OAuth token exchange, credentials (Windows Credential Manager), and safe attachment filenames.
- **WebView2 (`app/src/preview.cpp`)**: renders the documents from `pe_html_render` with scripts, web messages, host objects and dev tools off. A `WebResourceRequested` filter on `*` refuses http(s), ftp and file requests (remote images only after the user allows them), and navigation and new windows are cancelled, with links opened in the default browser. Do not enable scripts to run a JS sanitizer such as DOMPurify; sanitizing is done in Rust (`pe-html`, ammonia) and the document carries a CSP as one more layer.
- **C++ (`app/`)**: windows, common controls, menus, dialogs and plain app preferences.

## Rust core

A Cargo workspace in `core/` (edition 2024, `rustfmt.toml` sets 120 columns). The crates under `core/crates/`:

- `pe-imap`: port of `../imapflow/src`. `pe-smtp`: port of the client parts of `../nodemailer/src` (smtp-connection, mime-node, mail-composer, mime-funcs, addressparser, qp, punycode, xoauth2). `pe-mime`: port of `../postal-mime/src`. Port these idiomatically rather than line by line: response parsing as pure functions over bytes, the connection on top of that. Use the TS test suites and fixtures of the originals as the reference for behavior.
- `pe-html`: ammonia sanitizer and the preview document wrapper with its CSP.
- `pe-net`: TCP and TLS (rustls with the platform verifier, or a pinned certificate) for IMAP and SMTP.
- `pe-store`: the local cache in SQLite (rusqlite, bundled): accounts without secrets, folders, message summaries, cached sources. Schema changes are new entries in `schema.rs` `MIGRATIONS`, never edits of shipped ones.
- `pe-sync`: keeps `pe-store` in step with an IMAP account through `pe-imap`.
- `pe-testkit`: starts ImapKit (`core/e2e`) for the end-to-end tests and talks to its REST API.
- `pe-ffi`: the only crate with `unsafe` code and the only one the app links. Every other crate starts with `#![forbid(unsafe_code)]`.

### The C ABI (`pe-ffi`)

- Built as `staticlib` (`pe_ffi.lib`) and linked into the exe, not as a DLL: one signed exe, no DLL search-order risk.
- `build.rs` runs cbindgen and writes `core/include/postal_express.h`. The header is committed so API changes show up in diffs; rebuild the crate after changing an export and commit the header with it.
- Calls are coarse, on opaque handles. Strings go both ways as UTF-8; strings returned to C++ are allocated by Rust and released with `pe_string_free` (in C++, `core::String`, a `unique_ptr` with that deleter, see `app/src/core.h`).
- Every export runs its body inside `guard` (`catch_unwind`) so no panic crosses into C++. Do not switch to `panic = "abort"`: a panic on a malformed message would then crash the app on every start.
- Rust is built with `+crt-static` (`core/.cargo/config.toml`) to match the static CRT of the app (`/MT`, no Debug CRT variant). Cargo only reads that file when it runs in `core/`, which is why `app/CMakeLists.txt` sets `WORKING_DIRECTORY`. When a new Rust dependency needs more Windows system libraries, get them from `cargo rustc -p pe-ffi --release -- --print native-static-libs` and add them to `target_link_libraries`.

## C++ app (`app/`)

Plain Win32 (C++20, MSVC, `/W4 /utf-8 /permissive-`). The manifest (`app/res/app.manifest`) deliberately has no dependency on Common Controls 6, so the controls draw in the classic 3D style; keep it that way. Code style and patterns (pages, dialogs, tray, list views, preview) follow `../imapkit-win/host-win/src`; borrow from there when adding UI. CMake runs `cargo build --release --locked -p pe-ffi` on every build, with the Cargo target dir under `build/cargo`, and downloads the WebView2 SDK from NuGet pinned by hash.

The app version is the `[workspace.package] version` of `core/Cargo.toml`. CMake reads the first `version = "x.y.z"` line of that file, so keep `[workspace.package]` at the top.

## Commands

Rust, on the Mac or anywhere:

```
cd core
cargo test --workspace                 # all tests
cargo test -p pe-html keeps_mail_layout   # one test
cargo clippy --workspace --all-targets
cargo fmt --all
```

`Cargo.lock` is committed and the Windows build uses `--locked`, so commit lockfile changes along with dependency changes.

The app only builds on Windows. The build machine is `andri@10.8.0.8` (Windows 11, VS 2022 Build Tools, Rust via rustup); the sources live at `C:\Users\andri\src\postal-express`. From the Mac:

```
scripts/win-build.sh                  # copy the working tree over (tar, no .git or build outputs) and build build\PostalExpress.exe
scripts/win-test.sh [cargo args]      # copy and run cargo test on Windows
scripts/win-run.sh                    # start the app on the interactive desktop (scheduled task; SSH has no desktop)
scripts/win-screenshot.sh out.png     # screenshot of the window, DESKTOP=1 for the whole screen
```

On Windows itself: `scripts\win-build.cmd` and `scripts\win-test.cmd`. Both call `scripts\vcvars.cmd`, which finds Visual Studio with vswhere and puts cargo on PATH.

Screenshots need a logged-in desktop session that is not disconnected or locked; check with `ssh andri@10.8.0.8 query user` (`Active`, not `Disc`). In a disconnected session they come out blank white.

CI (`.github/workflows/ci.yml`) runs fmt, clippy with `-D warnings`, a check that the committed C header matches the build, the Rust tests on Linux, Windows and macOS, and the app build on Windows (artifact `PostalExpress-win-x64`). Markdown and YAML are formatted with prettier (`npx prettier --write`, config in `.prettierrc.json`).

For test IMAP and SMTP accounts use Ethereal (see the global instructions) or ImapKit (`../imapkit`, `../imapkit-win`).
