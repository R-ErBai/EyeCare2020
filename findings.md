# Findings & Decisions

## Requirements

- iOS app for personal eye-care reminders.
- Repeating 20-20-20 cycle: 20 minutes of near work, then a 20-second look-away reminder.
- Continue in the background until manually stopped.
- Screen lock pauses the timer immediately.
- Lock duration up to and including 60 seconds resumes the remaining cycle.
- Lock duration over 60 seconds resets the timer to a fresh 20 minutes and starts automatically on unlock.
- The user explicitly stops the app to end the loop.

## Research Findings

- Apple's `applicationWillResignActive` and `sceneWillResignActive` events are also used for interruptions other than lock, so they cannot alone identify a lock.
- `UIApplication.isProtectedDataAvailable` is false while data protection is active and the device is locked.
- `UIApplication.protectedDataWillBecomeUnavailableNotification` posts before protected files become inaccessible; `protectedDataDidBecomeAvailableNotification` posts after they become available again.
- Local notifications can be scheduled for future delivery while the app is suspended and canceled while the app is executing.
- Apple does not grant ordinary timer apps indefinite arbitrary background CPU time.
- A playback audio session with the audio background mode is the practical personal-use way to keep the app alive for immediate lock handling. This is not an App Store-safe use of the entitlement.

## Technical Decisions

| Decision | Rationale |
|----------|-----------|
| Personal-use SwiftUI app | The requested behavior needs continuous background execution and cannot be guaranteed in a policy-safe App Store build |
| Wall-clock deadlines plus remaining-time snapshots | Keeps timing correct across background time and SwiftUI redraw gaps |
| Pure state machine with injected `Date` | Makes lock boundaries and phase transitions testable without sleeping |
| Local notification per active phase | Provides a system prompt if the app is throttled despite background audio |
| Cancel all notifications on lock | Prevents a prompt from firing while the device is locked |
| No persistence between launches | Manual force-quit ends the session, matching “until I manually stop” |

## Issues Encountered

| Issue | Resolution |
|-------|------------|
| The current machine is Windows and cannot compile iOS targets | Deliver a complete Xcode project and clearly separate local validation from required Mac/iPhone validation |
| The silent-audio approach may be rejected by App Review | Scope the first version to personal sideloading and document the tradeoff |

## Resources

- Apple, Background Tasks: https://developer.apple.com/documentation/backgroundtasks
- Apple, `protectedDataWillBecomeUnavailableNotification`: https://developer.apple.com/documentation/uikit/uiapplication/protecteddatawillbecomeunavailablenotification
- Apple, `protectedDataDidBecomeAvailableNotification`: https://developer.apple.com/documentation/uikit/uiapplication/protecteddatadidbecomeavailablenotification
- Apple, `isProtectedDataAvailable`: https://developer.apple.com/documentation/uikit/uiapplication/isprotecteddataavailable
- Apple, Scheduling a notification locally: https://developer.apple.com/documentation/usernotifications/scheduling-a-notification-locally-from-your-app
- AltStore, AltServer behavior: https://faq.altstore.io/altstore-classic/altserver
- AltStore, app refresh and free-account limits: https://faq.altstore.io/altstore-classic/your-altstore
- AltStore, source JSON format: https://faq.altstore.io/developers/make-a-source
- AltStore, Classic distribution: https://faq.altstore.io/developers/distribute-with-altstore-classic
- AltStore, Remote AltServer: https://faq.altstore.io/altstore-classic/remote-altservers

## AltStore Delivery Findings

- AltStore Classic can install any IPA without a paid Apple Developer account.
- Free Apple ID apps expire after seven days, but AltStore attempts automatic background refresh during the week.
- Automatic refresh requires the iPhone to reach AltServer on the same Wi-Fi network, over USB, or through the optional Remote AltServer setup.
- AltStore Classic requires users to enter their own Apple ID into AltServer; no credentials need to be shared with this project.
- AltStore Classic allows at most three active sideloaded apps.
- On Windows, AltStore officially requires iTunes and iCloud installed from Apple rather than the Microsoft Store.
- A custom AltStore source needs a publicly reachable JSON file, an IPA download URL, matching bundle/version metadata, and a declared permissions object.
