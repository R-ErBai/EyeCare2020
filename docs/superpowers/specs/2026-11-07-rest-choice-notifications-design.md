# Rest Choice and Notification Design

## Goal

Make the 20-minute deadline noticeable while the app is foregrounded, let the
user choose a 20-second or 1-minute break, and notify again when the break ends.
The existing lock-screen rules remain unchanged.

## User-facing behavior

- At the end of each 20-minute work interval, the app presents a foreground
  choice panel with "休息 20 秒" and "休息 1 分钟".
- If the app is in the background with the screen on, the same choice appears
  as an actionable system notification.
- If no choice is made within 10 seconds, the 20-second break starts
  automatically.
- A choice applies only to the current break. The next work interval always
  returns to the configured work duration.
- A second notification announces that the break has ended.
- Locking the screen pauses the timer and cancels every pending notification.
  Unlocking within 60 seconds resumes the saved state; a longer lock resets to
  a fresh 20-minute work interval and starts automatically.
- If notification permission is denied, the in-app choice panel still works
  and the interface shows a button to open iOS notification settings.
- The work interval is configurable from 1 to 120 minutes and defaults to 20.
  The value persists in `UserDefaults`; changing it during a cycle applies
  starting with the next work interval.

## State model

`TimerCore` gains an explicit `awaitingRestChoice` status, a `RestDuration`
value of 20 or 60 seconds, and a validated work-duration setting. The state
machine owns the 10-second choice timeout, starts the selected break, and
preserves the pending choice when the screen locks.

`TimerViewModel` maps state-machine events to haptics, the in-app panel, and
notification scheduling. It also persists the work duration and presents a
settings sheet. Notifications use two stable identifiers: one for the break
choice and one for break completion.

`AppNotificationDelegate` presents the in-app panel instead of a duplicate
banner when the app is active, exposes the two rest actions in the background,
and forwards the selected action to the view model.

## Failure handling

- Locking cancels both pending notification types.
- Resuming after a short lock reschedules only the notification appropriate
  for the restored phase.
- Choosing 1 minute replaces the pending 20-second completion notification.
- Notification authorization failures do not block the timer or in-app choice
  panel.

## Verification

- Unit tests cover the choice timeout, both choices, transition back to work,
  short and long lock behavior while waiting for a choice, and notification
  metadata.
- Project checks, Swift tests, simulator build, and UI build run in GitHub
  Actions because the current Windows machine has no Xcode toolchain.
- Physical-device checks remain required for lock detection, notification
  delivery, background audio, and battery behavior.
