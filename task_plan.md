# Task Plan: 20-20-20 Eye Care iOS App

## Goal

Deliver a personal-use iPhone app that runs 20-minute near-work and 20-second look-away cycles in the background until the user explicitly stops it, pauses while the device is locked, resumes within one minute, and restarts the cycle after a lock longer than one minute.

## Next Step

Install AltServer on Windows, sign in with the user's own Apple ID, and run the physical-iPhone lock tests.

## Current Phase

Phase 5

## Phases

### Phase 1: Requirements & Discovery

- [x] Capture the timer and lock-screen requirements
- [x] Verify iOS background and lock-detection constraints against Apple documentation
- [x] Record findings and limitations
- **Status:** complete

### Phase 2: Planning & Structure

- [x] Choose a personal-use architecture
- [x] Define the state machine and component boundaries
- [x] Write the design and implementation plan
- **Status:** complete

### Phase 3: Implementation

- [x] Add core timer state machine and unit tests
- [x] Add lock observation, notification scheduling, and background keeper
- [x] Build the SwiftUI interface and Xcode project
- [x] Add app icon, documentation, and install instructions
- **Status:** complete

### Phase 4: Testing & Verification

- [x] Validate timer and lock transition tests in Swift/XCTest
- [x] Validate project structure and assets
- [x] Document checks that require Xcode and a physical iPhone
- **Status:** complete

### Phase 5: Delivery

- [x] Review all files
- [x] Package the Xcode project
- [x] Provide Windows + AltStore deployment and auto-refresh steps
- [x] Create and populate the public GitHub repository
- [x] Build and publish the unsigned AltStore release
- [ ] Install and validate on the physical iPhone
- **Status:** in_progress

## Key Questions

1. Does the user want App Store distribution? Assumed personal sideloading because exact lock behavior is required.
2. Does the target device run iOS 17 or newer? Target set to iOS 17 for broad compatibility.
3. Is an iPhone available for final install? The requested platform implies yes; final device verification remains external.

## Decisions Made

| Decision | Rationale |
|----------|-----------|
| Personal-use SwiftUI app | Exact lock-aware background behavior conflicts with App Store-safe background execution rules |
| Silent background audio | Keeps the process alive long enough to react to lock state and stop prompts immediately |
| Protected-data notifications | Public UIKit signal that reliably corresponds to device lock while the app is running |
| Pure Swift timer state machine | Makes the one-minute boundary and cycle transitions deterministic and unit-testable |
| iOS 17 minimum | Supports current SwiftUI APIs while covering a wide device range |

## Errors Encountered

| Error | Attempt | Resolution |
|-------|---------|------------|
| `mcporter` unavailable for Agent Reach | 1 | Used direct Apple documentation endpoints instead |
| `ponytail` skill cache listed but files missing | 1 | Continued with the product's minimum-change principle |
| Windows has no Xcode or Swift compiler | 1 | Generate a complete Xcode project and document required macOS verification |
| Swift installer requires an unavailable administrator confirmation | 1 | Canceled installation cleanly; retained XCTest source for execution on Mac |

## Notes

- The app is designed for personal sideloading, not App Store submission.
- The cloud build and automated tests run on GitHub macOS runners.
- Physical-device lock tests remain to be performed after AltStore installation.
