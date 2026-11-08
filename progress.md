# Progress Log

## Session: 2026-11-05

### Phase 1: Requirements & Discovery

- **Status:** complete
- Captured the 20-20-20 cycle, manual stop, lock pause, one-minute reset threshold, and background requirements.
- Verified the relevant iOS lifecycle and notification behavior against Apple documentation.
- Documented the personal-use background-audio tradeoff.

### Phase 2: Planning & Structure

- **Status:** complete
- Selected SwiftUI with a pure timer state machine.
- Planned separate lock observer, notification scheduler, and background keeper services.
- Defined unit tests for start, phase transition, lock pause, one-minute boundary, long-lock reset, and manual stop.

### Phase 3: Implementation

- **Status:** complete
- Implemented the deterministic timer state machine, lock observer, notification scheduler, silent background audio keeper, SwiftUI interface, app lifecycle, assets, and Xcode project.
- Added tests for the initial state, phase transitions, lock pause, exact 60-second resume threshold, long-lock reset, stop, invalid calls, and notification content.
- Generated an opaque 1024×1024 app icon and a one-second silent 44.1 kHz mono WAV loop.

### Phase 4: Testing & Verification

- **Status:** complete
- Parsed the Xcode project object graph and resolved all group file references.
- Verified 11 Swift files, 4 asset JSON files, Plist and scheme XML, app/test targets, build phases, labels, icon dimensions, and silent WAV format.
- `node scripts/verify-project.mjs` reported `PASS` with 1,136 checks.
- Confirmed asset generation is deterministic by comparing SHA-256 hashes before and after regeneration.
- Added `verify-on-mac.command` and a GitHub Actions workflow to run resource checks, Swift tests, and an iOS simulator build on macOS.
- Added an unsigned IPA release workflow, automatic AltStore source generation, and a Windows + AltStore installation guide.
- Confirmed from AltStore's official documentation that AltStore Classic auto-refreshes free Apple ID builds while it can reach AltServer on the same Wi-Fi or over USB.
- Re-ran the project verifier successfully.
- Generated a test AltStore source with a placeholder repository URL and confirmed the app metadata, latest-release IPA URL, and byte-size field.
- Cloud Swift state-machine tests passed on macOS.
- The unsigned iPhone Release build succeeded and published `EyeCare2020.ipa`.
- GitHub iOS verification completed successfully.
- Downloaded and inspected the published IPA: `Payload/EyeCare2020.app/Info.plist` and the app binary are present, and its size matches `altstore.json`.
- Physical lock behavior, notification delivery, background audio persistence, and battery use remain pending on iPhone.

### Phase 5: Delivery

- **Status:** in_progress
- Created the public repository `R-ErBai/EyeCare2020` and pushed the complete project.
- Published the AltStore source at `https://github.com/R-ErBai/EyeCare2020/releases/latest/download/altstore.json`.
- Added the one-click AltStore installation route and automatic free-account refresh guidance.

## Test Results

| Test | Input | Expected | Actual | Status |
|------|-------|----------|--------|--------|
| Project verifier | `node scripts/verify-project.mjs` | All structure and asset checks pass | `PASS`, 1,152 checks | Passed |
| Plist parser | Python `plistlib` | Valid plist with display name, audio mode, portrait orientation | Parsed successfully | Passed |
| Scheme XML parser | Python ElementTree | Valid scheme XML | Parsed `Scheme 1.7` | Passed |
| Asset generator | Run twice and compare SHA-256 | Identical PNG and WAV | Identical | Passed |
| Swift state-machine tests | GitHub macOS `swift test` | All timer tests pass | Passed | Passed |
| iOS verification | GitHub Actions run `42058468341` | iOS build and tests pass | Passed | Passed |
| AltStore cloud build | GitHub Actions run `42058530094` | Publish IPA, source JSON, and icon | Passed | Passed |
| Published AltStore source | Latest release URL | HTTP 200 and valid JSON | HTTP 200, valid bundle/version metadata | Passed |
| Published IPA | Latest release URL | Valid ZIP with app binary and Info.plist | 175,909 bytes, 9 entries, both files present | Passed |
| Physical lock tests | iPhone lock for 30 s and 70 s | Resume at 30 s; reset at 70 s | No iPhone available in current environment | Not run |
| AltStore source generator | Placeholder `owner/repo` and local IPA | Valid JSON with matching bundle and release URLs | Generated and parsed successfully | Passed |
| AltStore release workflow structure | Static source scan | Manual trigger, unsigned device build, IPA, source JSON, release upload | All required steps present | Passed |

## Session: 2026-11-07

### Physical-device delivery

- **Status:** paused until the user reconnects the iPhone the next day.
- Installed `EyeCare2020.ipa` on the connected iPhone 15 Pro (iOS 26.0) with Sideloadly; Sideloadly reported `Done. 100%`.
- Downloaded the published IPA through the GitHub API and confirmed its SHA-256 digest matches the release asset:
  `106b2a18c8c5d7faf0b87736b9d3e68cc985e55af79c3509b65958c6a5edc968`.
- The user confirmed that the installed “远眺” app opens and appears normal.
- Initially installed AltStore successfully with Sideloadly, but an attempted AltServer reinstall failed with:
  `AltServer could not write app data to the device.`
- Sideloadly diagnosed the underlying failure as
  `AFC_E_NO_SPACE_LEFT` while installing AltStore at 63%.
- The user removed at least 1 GB from the iPhone, but a retry still failed at the same point. The partial AltStore installation was likely left on the device; the recommended recovery is to delete that broken AltStore app, free additional space (2 GB preferred), then reinstall.
- AltStore automatic refresh is not yet configured.
- Physical lock tests are not yet run: 30-second lock should resume, 70-second lock should reset to 20:00 and continue, no reminder should fire while locked, and stopping manually should cancel further reminders.

### Next session

1. Reconnect and unlock the iPhone, then confirm the exact free space shown under Settings → General → iPhone Storage.
2. Delete the broken AltStore app if it is still present.
3. Reinstall AltStore from `D:\CodexTemp\EyeCare2020\AltStoreClassic-mirror.ipa` with Sideloadly.
4. Open AltStore, add
   `https://github.com/R-ErBai/EyeCare2020/releases/latest/download/altstore.json`,
   and put “远眺” under My Apps for auto-refresh.
5. Run the physical lock-screen and notification tests listed above.

### Configurable interval and notification revision

- **Status:** implemented, released, and installed; physical verification remains.
- Added a persisted 1–120 minute work interval setting, defaulting to 20 minutes.
- Changes made during an active cycle apply to the next work interval.
- Added a foreground 20-second / 1-minute rest choice card.
- Added actionable background notification choices and a separate break-completion notification.
- Added notification permission status and a direct link to iOS notification settings.
- Bumped the app to version 1.1 (build 2).
- GitHub Actions run `42329736162` passed resource checks, Swift tests, simulator build/tests, and UI build.
- GitHub Actions release run `42380234323` passed and published release `altstore-42380234323`.
- Downloaded and verified the released IPA:
  - size `236985`
  - SHA-256 `aece6ffd4410ad67ac05b4f8c713fb6acdc0fa7e6af9206f574f76ced684856d`
  - bundle version `1.1 (2)`
- Installed the 1.1 IPA and reinstalled AltStore on the connected iPhone with Sideloadly.
- Pull request `#1` passed the pull-request verification run and was merged into `main`.
- Remaining: add the AltStore source, put “远眺” into My Apps, verify notification permission, and run the physical foreground/background/lock tests.

### Rest flow and Live Activity revision

- Bumped the app to version 1.2.2 (build 5).
- At work deadline, the 20-second break now starts immediately.
- The foreground card lasts five seconds and allows keeping 20 seconds or extending to one minute.
- The background notification no longer opens the app when selecting “休息 1 分钟”.
- The selected break-completion sound is played directly by the app; the notification itself is silent to prevent duplicate playback.
- Live Activity is refreshed when the app becomes active after unlock, addressing the stale “解锁后继续” display.
- Added a widget extension and verified that the built IPA contains
  `PlugIns/EyeCare2020LiveActivity.appex`.
- GitHub iOS verification passed for commit `e5efa03`; release workflow
  `42388658734` published release `altstore-42388658734`.
- The published IPA is 457,629 bytes with SHA-256
  `0ff497eab5c9bf23b6c6284256adef485ec8f4056c470536c5365f8fac6c67fb`.
- Version 1.2.2 was installed successfully on the original iPhone.

### Second iPhone preparation

- A second iPhone (“安琪的 iPhone”, iOS 26.2.1) was connected.
- The computer was trusted and Developer Mode was made visible with the AMFI
  command, then manually enabled and confirmed on-device.
- Sideloadly's local Fake2 Anisette marker was found at
  `C:\Users\64580\AppData\Local\cache\sideloadly\native-anis-Fake2.crashed`
  and moved to `native-anis-Fake2.crashed.bak`.
- Installation on the second iPhone was postponed at the user's request.
- Next time: install `EyeCare2020.ipa`, trust the developer profile if prompted,
  and run the physical notification, sound, lock, and Live Activity checks.

## Error Log

| Timestamp | Error | Attempt | Resolution |
|-----------|-------|---------|------------|
| 2026-11-05 | `mcporter` unavailable | 1 | Used direct Apple documentation |
| 2026-11-05 | `ponytail` skill unavailable | 1 | Followed minimum-change principle manually |
| 2026-11-05 | No Xcode/Swift on Windows | 1 | Prepare project and document Mac verification |
| 2026-11-05 | Swift toolchain installer blocked by administrator confirmation | 1 | Canceled cleanly; kept XCTest source for Mac |

## 5-Question Reboot Check

| Question | Answer |
|----------|--------|
| Where am I? | Phase 5: physical-device delivery |
| Where am I going? | AltServer setup, iPhone installation, lock-behavior verification |
| What's the goal? | See `task_plan.md` |
| What have I learned? | See `findings.md` |
| What have I done? | See this log |
