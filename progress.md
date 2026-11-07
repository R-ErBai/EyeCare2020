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
