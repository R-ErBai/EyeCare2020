# Eye Care 20-20-20 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a personal-use iOS timer that repeats 20-minute work and 20-second look-away phases, pauses on lock, and resets after a lock longer than one minute.

**Architecture:** A pure Swift state machine owns all timing state. A SwiftUI view model coordinates the state machine with protected-data lock observation, local notifications, and a silent background audio session.

**Tech Stack:** Swift 5.9+, SwiftUI, Foundation, UIKit, UserNotifications, AVFoundation, XCTest, Xcode project on iOS 17+.

## Global Constraints

- Target: iPhone, iOS 17.0 minimum.
- Work duration: exactly 1,200 seconds.
- Look-away duration: exactly 20 seconds.
- Resume threshold: lock duration less than or equal to 60 seconds.
- Reset threshold: lock duration greater than 60 seconds.
- Stop only through the visible Stop control or process termination.
- Personal sideload build; do not claim App Store compliance.

---

### Task 1: Timer State Machine

**Files:**
- Create: `EyeCare2020/Timer/TimerCore.swift`
- Test: `EyeCare2020Tests/TimerCoreTests.swift`

**Interfaces:**
- Consumes: `Date` values from the caller.
- Produces: `TimerCore.start(at:)`, `stop(at:)`, `lock(at:)`, `unlock(at:)`, `tick(at:)`, `TimerCore.Event`, `TimerCore.Phase`, and `TimerCore.Status`.

- [ ] **Step 1: Write failing state-machine tests**

```swift
func testShortLockResumesWithRemainingTime() {
    var core = TimerCore()
    let start = Date(timeIntervalSince1970: 1_000)
    core.start(at: start)
    _ = core.tick(at: start.addingTimeInterval(300))
    core.lock(at: start.addingTimeInterval(300))
    let result = core.unlock(at: start.addingTimeInterval(360))

    XCTAssertEqual(result, .resumed)
    XCTAssertEqual(core.remaining(at: start.addingTimeInterval(360)), 900, accuracy: 0.001)
}
```

- [ ] **Step 2: Add the test target in Xcode and verify RED**

Run the `EyeCare2020Tests` target. Expected: compilation failure because `TimerCore` does not exist.

- [ ] **Step 3: Implement the minimal deterministic state machine**

```swift
struct TimerCore {
    enum Phase { case work, lookAway }
    enum Status { case idle, running, locked }
    enum UnlockResult: Equatable { case ignored, resumed, reset }

    var phase: Phase = .work
    var status: Status = .idle
    private(set) var remainingSnapshot: TimeInterval = 1_200
    private var deadline: Date?
    private var lockedAt: Date?
}
```

- [ ] **Step 4: Verify GREEN**

Run `xcodebuild test -project EyeCare2020.xcodeproj -scheme EyeCare2020 -destination 'platform=iOS Simulator,name=iPhone 15'`.

- [ ] **Step 5: Commit**

```bash
git add EyeCare2020/Timer/TimerCore.swift EyeCare2020Tests/TimerCoreTests.swift
git commit -m "feat: add deterministic eye-care timer state machine"
```

### Task 2: Lock, Notification, and Audio Services

**Files:**
- Create: `EyeCare2020/Services/LockObserver.swift`
- Create: `EyeCare2020/Services/NotificationScheduler.swift`
- Create: `EyeCare2020/Services/BackgroundAudioKeeper.swift`

**Interfaces:**
- Consumes: `TimerCore` events and run state.
- Produces: lock callbacks, `schedule(phase:at:)`, `cancelAll()`, `start()`, and `stop()`.

- [ ] **Step 1: Add unit tests for notification identifiers and deadline calculation**

```swift
func testWorkNotificationUsesConfiguredDeadline() {
    let date = Date(timeIntervalSince1970: 10_000)
    let plan = NotificationSchedule.make(deadline: date)
    XCTAssertEqual(plan.deadline, date)
    XCTAssertEqual(plan.identifier, "eye-care-phase")
}
```

- [ ] **Step 2: Verify RED**

Run the test target. Expected: missing `NotificationSchedule`.

- [ ] **Step 3: Implement the three services**

`LockObserver` subscribes to protected-data notifications. `NotificationScheduler` requests alert and sound permission, replaces the single phase request, and removes pending and delivered requests. `BackgroundAudioKeeper` configures an audio playback session and loops the bundled silent WAV.

- [ ] **Step 4: Verify GREEN and run a simulator smoke test**

Start a session, background the simulator app, confirm the pending notification exists, then stop and confirm it is removed.

- [ ] **Step 5: Commit**

```bash
git add EyeCare2020/Services EyeCare2020Tests
git commit -m "feat: add lock, notification, and background services"
```

### Task 3: SwiftUI Interface and App Lifecycle

**Files:**
- Create: `EyeCare2020/EyeCare2020App.swift`
- Create: `EyeCare2020/ContentView.swift`
- Create: `EyeCare2020/ViewModels/TimerViewModel.swift`
- Create: `EyeCare2020/Theme/AppTheme.swift`

**Interfaces:**
- Consumes: `TimerCore` and all three services.
- Produces: one-screen start/stop experience, countdown display, phase label, progress ring, permission message, and notification delegate.

- [ ] **Step 1: Write view-model transition tests**

```swift
@MainActor
func testWorkToLookAwayPublishesPrompt() {
    let model = TimerViewModel(dateProvider: { Date(timeIntervalSince1970: 1_200) })
    model.start()
    model.handleTick(now: Date(timeIntervalSince1970: 2_400))
    XCTAssertEqual(model.phase, .lookAway)
    XCTAssertTrue(model.shouldShowLookAwayPrompt)
}
```

- [ ] **Step 2: Verify RED**

Run the test target. Expected: missing `TimerViewModel`.

- [ ] **Step 3: Implement the view model and screen**

Use a 0.25-second Combine timer, `ProgressView`-style circular stroke, monospaced timer text, accessible labels, and a high-contrast Start/Stop button. The notification delegate presents banners and sounds in the foreground.

- [ ] **Step 4: Verify GREEN and inspect the simulator**

Run the app on an iPhone simulator and check 20:00, Start, Stop, Work, and Look Away states.

- [ ] **Step 5: Commit**

```bash
git add EyeCare2020/EyeCare2020App.swift EyeCare2020/ContentView.swift EyeCare2020/ViewModels EyeCare2020/Theme EyeCare2020Tests
git commit -m "feat: add eye-care timer interface"
```

### Task 4: Xcode Project, Assets, and Documentation

**Files:**
- Create: `EyeCare2020.xcodeproj/project.pbxproj`
- Create: `EyeCare2020/Info.plist`
- Create: `EyeCare2020/Resources/silence.wav`
- Create: `EyeCare2020/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png`
- Create: `README.md`

**Interfaces:**
- Consumes: source files from Tasks 1-3.
- Produces: openable Xcode project with notification and audio-background capabilities and a personal-install guide.

- [ ] **Step 1: Add structural verification**

```powershell
rg --files EyeCare2020 EyeCare2020Tests
rg -n "UIBackgroundModes|audio|Info.plist|EyeCare2020Tests" EyeCare2020.xcodeproj/project.pbxproj
```

Expected: all required source, asset, and target references are present.

- [ ] **Step 2: Generate the silent loop and app icon**

Create a one-second mono 44.1 kHz WAV with zero samples. Create a 1024-by-1024 eye-themed PNG without transparency.

- [ ] **Step 3: Write install instructions**

Document opening the project in Xcode, selecting the development team, changing the bundle identifier if needed, connecting an iPhone, enabling Developer Mode, running the app, and testing the two lock thresholds.

- [ ] **Step 4: Verify project structure**

Check that all source files referenced by the project exist and that plist/XML/JSON assets parse.

- [ ] **Step 5: Commit**

```bash
git add EyeCare2020.xcodeproj EyeCare2020/Info.plist EyeCare2020/Resources EyeCare2020/Assets.xcassets README.md
git commit -m "chore: package Xcode app and setup guide"
```

### Task 5: Final Verification

**Files:**
- Modify: `progress.md`

**Interfaces:**
- Consumes: all prior deliverables.
- Produces: audited completion evidence and a clear list of external device checks.

- [ ] **Step 1: Run available automated checks**

```powershell
node scripts/verify-project.mjs
```

Expected: PASS with no missing resources or invalid JSON/XML files.

- [ ] **Step 2: Run Mac/Xcode checks where available**

```bash
xcodebuild clean build test -project EyeCare2020.xcodeproj -scheme EyeCare2020 -destination 'platform=iOS Simulator,name=iPhone 15'
```

Expected: build and tests succeed.

- [ ] **Step 3: Run physical-iPhone checks**

Lock for 30 seconds and confirm resume. Lock for 70 seconds and confirm reset and automatic start. Background the app for 21 minutes and confirm the reminder. Stop and confirm no later prompt.

- [ ] **Step 4: Record evidence and limitations**

Update `progress.md` with command output summaries and explicitly list any checks that could not run on Windows.

- [ ] **Step 5: Commit**

```bash
git add progress.md
git commit -m "docs: record eye-care timer verification"
```
