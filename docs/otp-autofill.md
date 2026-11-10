# One-time codes and macOS AutoFill

Safari and other apps on the Mac offer one-time codes "From Mail" and "From Messages" in a field marked
`autocomplete="one-time-code"`. Inbox Classic shows a code in a card with Copy (`pe-core/src/otp.rs`); this note is
about also offering it to AutoFill.

**Built: the notification names the code.** With Show sign-in codes in new mail notifications on (Tools > Options,
Settings on the Mac, Preferences on Linux; off unless chosen), the worker downloads the source of a fresh message
(at most five seconds, announced without the code when that is slow), runs the same trusted detection as the card
(`pe-core/src/otp.rs`) and starts the notification's text with "482913 is your code for example.com". Whether macOS
then offers it to AutoFill is what the test below decides; if it does, the setting's default can be reconsidered.

## What exists

- **Notifications.** iOS 26 reads 3 to 8 digit codes from the notifications of other apps (Gmail, WhatsApp, Google
  Voice) and offers them above the keyboard, with "delete after use" and a choice of sources under the Verification
  Codes settings. WhatsApp's documentation and the press describe it; Apple does not. For macOS 26 the reports only say
  that codes from Messages are filled in Chrome and Firefox too, so whether the Mac reads other apps' notifications is
  not established.
- **A credential provider extension.** `ProvidesOneTimeCodes` in the extension's
  `ASCredentialProviderExtensionCapabilities`; the system asks with `ASCredentialRequestType.oneTimeCode`, the extension
  answers with `completeOneTimeCodeRequest` or lists codes in `prepareOneTimeCodeCredentialList`. Apple describes it for
  authenticator apps (TOTP), keyed by the site.

## The test that decides it

On a Mac with macOS 26 and Inbox Classic's notifications allowed:

1. Turn on Show sign-in codes in new mail notifications, then have a signed code mail arrive while the main window is
   not in front, so the new mail notification shows with "123456 is your code for ..." first.
2. Open a page with `<input autocomplete="one-time-code">` in Safari and in Chrome, and see whether the code is offered.
3. See whether Inbox Classic is listed as a source under System Settings > Passwords > Verification Codes (or AutoFill).

## If the notification is read

That is built (above): turn the setting on. A code in a notification can be read on a locked screen, which is why it
is off unless chosen.

## If it is not

The extension is the only way. It needs a sandboxed app extension sharing an App Group with the app, the AutoFill
credential provider entitlement and a provisioning profile (which the Developer ID build made with the Swift package
and no Xcode project does not have today), and the user turning Inbox Classic on as a password provider in System
Settings. Codes are asked for by site, so a mail code fits through its origin or its sender's domain. That is a
project of its own, to decide on its cost.

Sources: [Apple: Providing one-time passcodes to AutoFill](https://developer.apple.com/documentation/authenticationservices/providing-one-time-passcodes-to-autofill),
[MacRumors](https://www.macrumors.com/2025/06/12/ios-26-macos-tahoe-expand-one-time-code-autofill/),
[9to5Mac](https://9to5mac.com/2025/08/20/apples-killer-one-time-code-autofill-feature-gets-even-better-in-ios-26/),
[WhatsApp keyboard suggestions](https://developers.facebook.com/documentation/business-messaging/whatsapp/templates/authentication-templates/keyboard-suggestions).
