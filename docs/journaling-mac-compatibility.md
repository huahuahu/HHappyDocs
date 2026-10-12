# JournalingSuggestions and iOS Apps on Mac

Apple reported ITMS-90863 for HDiary 1.16 (1). The exported IPA and its archive
both contain a strong `LC_LOAD_DYLIB` dependency on JournalingSuggestions.
`#if os(iOS)` and `canImport` do not remove that dependency when the same iOS
binary runs on an Apple silicon Mac.

## Fix

- Weak-link JournalingSuggestions in the main app for the iPhoneOS SDK. The
  simulator and native macOS SDK configurations are unchanged.
- Return false from the existing capability check for `isiOSAppOnMac`.
- Check that capability at the picker entry point as well as the menu. An
  unavailable `.fromSuggestion` request falls back to the ordinary editor.
- Keep the framework import, picker body and selection conversion in a separate
  view whose stored properties use app-owned types and SwiftUI only.

## Verification on 2026-10-12

- Xcode native MCP Debug build succeeded on `HDiary Snapshot iPhone 17 Pro`,
  iOS 27.0, scheme HDiary.
- Release iPhoneOS build succeeded with signing disabled, using the locked
  dependencies. This is a local build, not an uploaded distribution artifact.
- `otool -l` confirms `LC_LOAD_WEAK_DYLIB` in the fixed Release executable.
- `nm -m` confirms all 83 JournalingSuggestions imports are weak; none are strong.
- The embedded widget has no JournalingSuggestions dependency.
- All five existing `AddMomentAccessTests` passed.
- On the iPhone simulator, the offline fixture opened the ordinary new-moment
  editor from the list and cancelled back to the list without a crash.

Local build logs, the old/new load-command comparison, weak-import listing and
simulator screenshots are under `.build/journaling-mac-validation/`.

## Remaining release validation

The current multiplatform scheme does not list a “Designed for iPad” Mac run
destination, including when requested with iPhoneOS SDK overrides. Running the
native macOS target would not validate this iOS-on-Mac scenario. A runtime pass
in that environment and an actual iPhone suggestion-picker interaction remain
unverified.

Upload a newly numbered, signed build containing this fix before considering
Apple's warning resolved remotely. The existing 1.16 (1) binary is unchanged;
this change does not modify App Store Connect, screenshots or submission state.
