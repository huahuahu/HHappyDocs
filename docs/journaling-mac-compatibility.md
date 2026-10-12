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

## Signed build and App Store submission

HDiary 1.16 (2), built from `17d0d9d628d533ebb2e28515154d26e17653649c`,
was uploaded and submitted on 2026-10-12. The final exported IPA passed code
signature validation, contains `LC_LOAD_WEAK_DYLIB`, and has 83 weak
JournalingSuggestions imports with no strong imports. The widget does not link
the framework, and the Release executable excludes screenshot launch flags.

- IPA SHA-256: `d363843225e471f6830e3adfb6552f598ac0d6b2a71c8a1ccca8f09dc06fc1ee`
- Build ID: `b457624e-5cfd-4c26-b021-95630fdc9faa`; processing: `VALID`.
- Review submission: `34c6b01e-4464-4cbf-a859-d8aa7976b2cd`.
- Verified review state: `WAITING_FOR_REVIEW`, with build 2 attached.
- Existing four-light/one-dark screenshots were preserved and reverified.

Receipts are in `release/1.16/build2/`; `release/1.16/status-build1.json`
preserves the previous submission. Raw signing and upload logs remain under
`.asc/artifacts/journaling-mac-release/`.

`asc xcode export` repeatedly failed at the packaging copy step. Export
succeeded using direct `xcodebuild -exportArchive` with absolute paths,
`PATH=/usr/bin:/bin:/usr/sbin:/sbin`, and the original automatic-signing
`ExportOptions.plist`. This isolates a successful export route; the exact
cause of the wrapper/environment failure was not established.

## Remaining runtime validation

The current multiplatform scheme does not list a “Designed for iPad” Mac run
destination, including when requested with iPhoneOS SDK overrides. Running the
native macOS target would not validate this iOS-on-Mac scenario. A runtime pass
in that environment and an actual iPhone suggestion-picker interaction remain
unverified.

The new build and upload APIs returned `VALID` and `COMPLETE`, with no reported
warnings or errors. Those API results do not independently verify the absence
of a later Apple warning email. Review submission is not review approval.
