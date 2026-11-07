# Rest Choice and Notifications Implementation Plan

1. Add failing state-machine tests for the rest-choice timeout, 20-second
   choice, 1-minute choice, and locking while the choice is pending.
2. Add failing notification metadata tests for the actionable choice
   notification and break-completion notification.
3. Extend `TimerCore` with `awaitingRestChoice`, `RestDuration`, configurable
   work minutes, and the choice transition while preserving existing stop,
   lock, and unlock guarantees.
4. Extend notification scheduling with the rest-choice category, two action
   identifiers, break completion, and complete cancellation.
5. Update the app delegate to route notification actions into the view model.
6. Add the work-duration settings sheet, foreground rest-choice panel, and
   notification-permission guidance.
7. Run repository checks, Swift tests, simulator tests, and an unsigned device
   build through GitHub Actions.
8. Publish a new IPA and source metadata only after all automated checks pass.
