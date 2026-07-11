# TestFlight Feature Access Design

## Goal

Allow every TestFlight installation to use subscription-gated Happy Moments features even when its sandbox subscription expires. Keep StoreKit's real subscription state and all purchase UI intact so testers can continue exercising purchase, renewal, expiration, and restore flows.

Production App Store installations must continue to require a valid subscription.

## Current Behavior

`RecordSubscriptionStatusModifier` resolves and caches a `RecordSubscriptionStatus`, then injects it through SwiftUI's environment. `AddMomentNavigationView` reads that status directly to decide whether to open the add-moment flow, show the introductory promotion, or present the subscription screen. Settings and purchase views read the same status to describe the user's StoreKit subscription.

This single value currently represents two different concepts:

- The StoreKit subscription state shown in purchase UI.
- Permission to use subscription-gated features.

Changing the status to a fabricated subscription for TestFlight would unlock features, but it would also hide the real sandbox state from testers. The new design keeps these concepts separate.

## Design

### Distribution classification

Add a small distribution classifier to `HDiaryIAP`. It reports `.testFlight` only when all of the following are true:

- The process is running on a physical device, not the simulator.
- `Bundle.main.appStoreReceiptURL?.lastPathComponent` is `sandboxReceipt`.
- The installed app bundle does not contain `embedded.mobileprovision`.

The combination distinguishes a TestFlight installation from a production App Store receipt, StoreKit Testing in Xcode, and a development or ad hoc installation. Apple exposes the transaction environment through `AppTransaction.environment`, but a sandbox environment alone is insufficient because development sandbox transactions are also sandbox transactions.

The classifier accepts receipt name, provisioning-profile presence, and simulator state as inputs. The live detector supplies bundle and compilation-environment values; unit tests supply explicit values.

Classification is conservative. Missing or unexpected evidence produces `.other`, which preserves the normal subscription requirement instead of accidentally granting production access.

### Feature access policy

Add a separate record-feature access value to the SwiftUI environment. It is computed in memory from:

- The real `RecordSubscriptionStatus`.
- The current app distribution.

Access is allowed when either condition is true:

1. The real status is monthly or annual and has already passed the existing transaction validation.
2. The current distribution is TestFlight.

The TestFlight override is never encoded into `recordSubscriptionStatusData` or any other persistent storage. A later production App Store installation therefore cannot inherit a stale TestFlight unlock.

### UI data flow

`RecordSubscriptionStatusModifier` remains the root provider for the real StoreKit status. It additionally injects the derived feature-access value.

`AddMomentNavigationView` uses feature access, rather than matching `.notSubscribed`, for both gating decisions:

- A TestFlight user opens the add-moment flow without seeing the subscription blocker.
- A TestFlight user also skips the first-use subscription promotion in that flow.
- A production user retains the current free-limit, promotion, and subscription-screen behavior.

Purchase surfaces continue using the real status:

- `RecordSubscriptionBuyCell` stays visible in Settings and keeps its current label based on StoreKit state.
- `RecordSubscriptionView` continues presenting StoreKit products.
- Purchase, restore, renewal, expiration, and upgrade behavior is unchanged.

This preserves the user's selected behavior: TestFlight has functional access, while IAP remains available for explicit testing.

## Error Handling and Logging

Distribution detection is synchronous and has no network dependency. If the receipt URL is missing, the receipt name is unexpected, or a development provisioning profile exists, the detector returns `.other`.

Log the resulting distribution category when the subscription environment is installed. Do not log receipt contents or other purchase data.

StoreKit status failures retain the current behavior. In TestFlight, the distribution-derived feature access still allows gated features even if loading the sandbox subscription status fails; purchase UI continues to reflect the status available through the existing StoreKit flow.

## Tests

Add focused unit tests to `HDiaryIAPTests` for the pure classifier:

- Physical device + `sandboxReceipt` + no embedded provisioning profile is TestFlight.
- Production `receipt` is not TestFlight.
- `sandboxReceipt` with an embedded provisioning profile is not TestFlight.
- A simulator with `sandboxReceipt` is not TestFlight.
- A missing receipt is not TestFlight.

Add policy tests:

- TestFlight plus `.notSubscribed` allows feature access.
- A non-TestFlight `.notSubscribed` status denies feature access.
- Monthly and annual statuses allow access in every distribution.

The implementation will follow test-driven development: add the failing classifier and policy tests first, confirm they fail for the expected missing behavior, then add the smallest production implementation and rerun the relevant package and project tests.

## Out of Scope

- Fabricating or persisting a paid subscription status.
- Hiding, disabling, or changing StoreKit purchase UI.
- Changing sandbox product durations or App Store Connect configuration.
- Adding server-side receipt validation.
- Unlocking Debug, simulator, development, ad hoc, or production App Store installations without a valid subscription.

## Success Criteria

- A TestFlight user can add moments beyond the free limit even with no current sandbox subscription.
- The same TestFlight user can still open Settings and exercise the real IAP flow.
- Subscription labels continue to reflect StoreKit's real state.
- A production App Store installation with no valid subscription remains restricted.
- The TestFlight override is not persisted and cannot leak into a later production installation.
