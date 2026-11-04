# Changelog

## [0.4.1](https://github.com/postalsys/inbox-classic/compare/v0.4.0...v0.4.1) (2026-11-04)


### Bug Fixes

* keep the toolbar from painting over the search field ([404d1ff](https://github.com/postalsys/inbox-classic/commit/404d1fff5ad84776b0bcb90660deeef5fa5779a9))

## [0.4.0](https://github.com/postalsys/inbox-classic/compare/v0.3.0...v0.4.0) (2026-11-04)


### Features

* a signature for each account ([b61db76](https://github.com/postalsys/inbox-classic/commit/b61db761850c6e59b9891487f049d6d10842c826))
* a slim search bar over the list ([c1d1f75](https://github.com/postalsys/inbox-classic/commit/c1d1f755447c0dedf52510b947aa1cc96c06f8f9))
* brand logos (BIMI) beside the header ([cc31b74](https://github.com/postalsys/inbox-classic/commit/cc31b740a78eaecc47fc2e4241a2caa7aa569dc5))
* calendar invitations shown readably ([120b921](https://github.com/postalsys/inbox-classic/commit/120b921f3de845e40269383604dfe8bf1fa69d37))
* complete addresses from the people written to and heard from ([abe5a88](https://github.com/postalsys/inbox-classic/commit/abe5a88777cc215077ab9f422c57bdc7936c143f))
* local full-text search with Gmail query syntax ([87cd7cc](https://github.com/postalsys/inbox-classic/commit/87cd7cc97fa771746d77a25142c2634f4a35af04))
* Mark All Read, dragging messages onto folders, Junk and Not Junk ([4a53a4d](https://github.com/postalsys/inbox-classic/commit/4a53a4d91bb5efb1f58fec77157fd42b7dee938f))
* new mail as it arrives, in the tray and as a notification ([a9176bc](https://github.com/postalsys/inbox-classic/commit/a9176bcba4a2c75817dcd553708ff9a212fea5f4))
* search every folder from one search field ([836b575](https://github.com/postalsys/inbox-classic/commit/836b5758400cfc409c2b34656a726f34d41c1eaa))
* the default mail app for mailto: links ([9742fb5](https://github.com/postalsys/inbox-classic/commit/9742fb545db7e29c01b6fb207578b16111bcb809))
* Unsubscribe from mailing lists ([86d5e98](https://github.com/postalsys/inbox-classic/commit/86d5e98be54ee842b920c193c3c5413d2c28835c))

## [0.3.0](https://github.com/postalsys/inbox-classic/compare/v0.2.0...v0.3.0) (2026-11-03)


### Features

* links in a message being written can be seen, opened, changed and removed ([6b2bc15](https://github.com/postalsys/inbox-classic/commit/6b2bc15dad953234387fd728cf275f5983ef5dba))
* pictures dragged onto the text go in as Insert Picture puts them ([ed7a8f6](https://github.com/postalsys/inbox-classic/commit/ed7a8f636b0752783914e938ab80b0a1538d3cd2))

## [0.2.0](https://github.com/postalsys/inbox-classic/compare/v0.1.0...v0.2.0) (2026-11-03)


### Features

* sign-in apps, OAuth clients of your own at any OpenID Connect provider ([f1a28c8](https://github.com/postalsys/inbox-classic/commit/f1a28c8202ada9077d1469140ea6ff8f654ac7ff))

## 0.1.0 (2026-11-03)


### ⚠ BREAKING CHANGES

* **compose:** remove Send Later

### Features

* **accounts:** Sign in with Google and Microsoft buttons, no password up front ([4e8dfeb](https://github.com/postalsys/inbox-classic/commit/4e8dfeb9bda756f9a5d5cbb68eff48d9362e09fb))
* **app:** Outlook Express style mail window on the core ([efb1b0c](https://github.com/postalsys/inbox-classic/commit/efb1b0cf75dccbfe87ef6d77061503224afd1fb9))
* **compose:** a From row that shows and chooses the sending account ([f4fb19e](https://github.com/postalsys/inbox-classic/commit/f4fb19e7aa13df37e22207de2872a2ec79afbae8))
* **compose:** message windows of their own, and saying what Save and Send did ([f269b1b](https://github.com/postalsys/inbox-classic/commit/f269b1bf4ae4c60a77bbcd3d9d1b0adecf2de955))
* **compose:** plain text when nothing is formatted; Cc and Bcc on demand ([cf865eb](https://github.com/postalsys/inbox-classic/commit/cf865ebd80764de5665499f17fbeed93b5b9fe4b))
* **compose:** remove Send Later ([091d1d1](https://github.com/postalsys/inbox-classic/commit/091d1d1120bc281308c8c99fb78d6e75b556bc87))
* **compose:** WYSIWYG HTML editor, the quote folded behind "..." ([2d0defd](https://github.com/postalsys/inbox-classic/commit/2d0defd527b0ad4ff65b00ef4daafee094a97273))
* **core,autoconfig:** saved passwords and server lookup for new accounts ([3f852f5](https://github.com/postalsys/inbox-classic/commit/3f852f5fd887c3e3bb08f1f020a93fdfbbb1843d))
* **core,ffi:** mail engine and C API v1 ([cfffe46](https://github.com/postalsys/inbox-classic/commit/cfffe466739a42394dd98a00710f38cbbe859ca0))
* delete, move and flag messages ([76f4c27](https://github.com/postalsys/inbox-classic/commit/76f4c275a2fc685080734e8f11c461dc8104734f))
* drafts ([5ed22f3](https://github.com/postalsys/inbox-classic/commit/5ed22f38eb9a37aa60b6f739ab70285deee87cfa))
* fold earlier messages, find servers like EmailEngine ([8199129](https://github.com/postalsys/inbox-classic/commit/81991295d840dcc15a00ec334e89f79d15a102c5))
* folders, accounts and Find ([5913ebe](https://github.com/postalsys/inbox-classic/commit/5913ebe2752a014c7166c5552661c7918808027a))
* **imap:** IMAP connection with TLS, authentication, mailboxes, messages and IDLE ([3f0acea](https://github.com/postalsys/inbox-classic/commit/3f0acead6000adfa1b41f9fcbd5d7b9007e15a36))
* **imap:** response framing, parser and command compiler ported from imapflow ([9ab7aa5](https://github.com/postalsys/inbox-classic/commit/9ab7aa5afced71a024caae30a4fe59ce72a6d896))
* **mime,imap:** encoded words, parameters, dates, envelopes and body structures ([c5e3f89](https://github.com/postalsys/inbox-classic/commit/c5e3f897cb80e4536a4b86073597a02af8be4c69))
* **mime:** message parser ported from postal-mime, inline images in the preview ([5f980e5](https://github.com/postalsys/inbox-classic/commit/5f980e54a4593fc92045b3ff543a10506b1de583))
* **oauth:** a designed page in the browser after signing in ([687da26](https://github.com/postalsys/inbox-classic/commit/687da26623a1d7da93468650cb530a00f1157989))
* **oauth:** explain when a Microsoft 365 organization must approve the app ([2feff6d](https://github.com/postalsys/inbox-classic/commit/2feff6d3dd590bbc32e1072c1972dfd6718be702))
* **oauth:** Gmail sign-in through the browser in every build ([543d77d](https://github.com/postalsys/inbox-classic/commit/543d77d532100743b4a51a71832ac34d89e7217e))
* **oauth:** sign in to Gmail and Outlook.com through the browser ([dc76218](https://github.com/postalsys/inbox-classic/commit/dc76218728510edf34ad1c0175b894187280c033))
* Outbox and Send Later, Save As, Import and Print ([aa16396](https://github.com/postalsys/inbox-classic/commit/aa16396798db8d66f8d197664259768063c7bdc1))
* **reading:** message views built off the window thread ([0ea6f6f](https://github.com/postalsys/inbox-classic/commit/0ea6f6f6efd41de10f4e633be17d60069e961baf))
* **smtp,core,app:** send mail, reply and forward ([5423868](https://github.com/postalsys/inbox-classic/commit/542386829c7656183db7fd48a37cd24b56a1e347))
* **store,sync:** SQLite message store and IMAP folder sync ([2a4a69d](https://github.com/postalsys/inbox-classic/commit/2a4a69de5f36db65f58f063976bd4412a84ce455))
* **tree:** accounts with the same name show their address ([456f4f1](https://github.com/postalsys/inbox-classic/commit/456f4f19fde4b6e5099d3441b1e9737ca888f73e))
* UI end-to-end test, in-app help, encryption-required errors ([ab6354e](https://github.com/postalsys/inbox-classic/commit/ab6354eca9fdb21ef180df4c6e1cbb21fc178157))
* **ui:** Accounts as a list with columns ([305a3c0](https://github.com/postalsys/inbox-classic/commit/305a3c0bed1738e0f3fddc86508871d2dafdb54c))
* **ui:** Fluent icons on the toolbars ([7120b0a](https://github.com/postalsys/inbox-classic/commit/7120b0a81add84f7da145fa623cff396416565ce))
* **ui:** Outlook Express layout details, Message Properties ([9e30017](https://github.com/postalsys/inbox-classic/commit/9e300179e80f941f476a4b68a3efa605f62fd6e0))
* **ui:** print window, Outlook Express reading pane bars, app icon ([b9f3d53](https://github.com/postalsys/inbox-classic/commit/b9f3d5322e4d8b298b5f008ffe07436dd591d99b))
* **ui:** removable attachments, Outbox columns, grouped toolbars ([a6bb9d9](https://github.com/postalsys/inbox-classic/commit/a6bb9d969bbb1413cf46ecb350a4e297ba0f391a))


### Bug Fixes

* **mime:** a Date zone that cuts a character no longer panics ([e30b6fe](https://github.com/postalsys/inbox-classic/commit/e30b6fe307a4c12ce69974a5a383a83c4fc1ae38))
* **net:** resume TLS sessions only for platform trust ([51652b4](https://github.com/postalsys/inbox-classic/commit/51652b4d74238c4a0e25c82aa668af77515c0e83))
* **oauth:** Microsoft sign-in comes back to localhost ([c4bac74](https://github.com/postalsys/inbox-classic/commit/c4bac7477f93ff0f04349b34b47d7362b957ca54))
* **security:** mark saved attachments and messages as from the internet ([54f716c](https://github.com/postalsys/inbox-classic/commit/54f716c0957050bdaf370cf0e335b695c9d5a5e3))
* **ui:** offer Download pictures only for messages that have them ([6a7287c](https://github.com/postalsys/inbox-classic/commit/6a7287c642eca458e7d1ab8dbcb43a476ef83899))
* **ui:** Size column wide enough for 1023 bytes ([87f96c2](https://github.com/postalsys/inbox-classic/commit/87f96c28b49d73f1c18a49f042c2e361d97c8e67))
