import ActivityKit
import SwiftUI
import WidgetKit

@main
struct EyeCare2020LiveActivityBundle: WidgetBundle {
    var body: some Widget {
        EyeCareLiveActivityWidget()
    }
}

struct EyeCareLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: EyeCareLiveActivityAttributes.self) { context in
            lockScreenView(context.state)
                .activityBackgroundTint(AppTheme.liveActivityForest)
                .activitySystemActionForegroundColor(AppTheme.liveActivityPaper)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: context.state.status == .paused ? "pause.fill" : "eye.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(context.state.phase.color)
                        .padding(.leading, 4)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    timerView(context.state)
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.liveActivityPaper)
                        .padding(.trailing, 4)
                }

                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        Text(context.state.phase.title)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(context.state.phase.color)

                        Text(statusText(context.state))
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.liveActivityPaper.opacity(0.62))
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 6) {
                        Image(systemName: "timer")
                        Text("\(context.state.workMinutes) 分钟用眼")
                        Text("·")
                        Text("20 秒 / 1 分钟休息")
                    }
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.liveActivityPaper.opacity(0.56))
                }
            } compactLeading: {
                Image(systemName: context.state.status == .paused ? "pause.fill" : "eye.fill")
                    .foregroundStyle(context.state.phase.color)
            } compactTrailing: {
                timerView(context.state)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.liveActivityPaper)
                    .frame(maxWidth: 48)
            } minimal: {
                Image(systemName: context.state.status == .paused ? "pause.fill" : "eye.fill")
                    .foregroundStyle(context.state.phase.color)
            }
            .keylineTint(context.state.phase.color)
        }
    }

    private func lockScreenView(
        _ state: EyeCareLiveActivityAttributes.ContentState
    ) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(state.phase.color.opacity(0.16))
                    .frame(width: 50, height: 50)

                Image(systemName: state.status == .paused ? "pause.fill" : "eye.fill")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(state.phase.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(state.phase.title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.liveActivityPaper)

                Text(statusText(state))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.liveActivityPaper.opacity(0.58))
            }

            Spacer()

            timerView(state)
                .font(.system(size: 28, weight: .light, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(AppTheme.liveActivityPaper)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    @ViewBuilder
    private func timerView(
        _ state: EyeCareLiveActivityAttributes.ContentState
    ) -> some View {
        if state.status == .running, let deadline = state.deadline {
            Text(timerInterval: Date()...deadline, countsDown: true)
                .monospacedDigit()
        } else {
            Text(formattedTime(state.remaining))
                .monospacedDigit()
        }
    }

    private func statusText(
        _ state: EyeCareLiveActivityAttributes.ContentState
    ) -> String {
        switch state.status {
        case .running:
            return state.phase == .lookAway ? "看向约 6 米外" : "保持当前节奏"
        case .waiting:
            return "等待选择休息时间"
        case .paused:
            return "熄屏暂停 · 解锁后继续"
        }
    }

    private func formattedTime(_ interval: TimeInterval) -> String {
        let totalSeconds = max(0, Int(ceil(interval)))
        return String(
            format: "%02d:%02d",
            totalSeconds / 60,
            totalSeconds % 60
        )
    }
}

private extension EyeCareActivityPhase {
    var title: String {
        switch self {
        case .work:
            return "用眼计时"
        case .lookAway:
            return "休息中"
        case .restChoice:
            return "该休息了"
        }
    }

    var color: Color {
        switch self {
        case .work:
            return AppTheme.liveActivityMint
        case .lookAway, .restChoice:
            return AppTheme.liveActivityAmber
        }
    }
}

private enum AppTheme {
    static let liveActivityForest = Color(red: 0.025, green: 0.10, blue: 0.085)
    static let liveActivityPaper = Color(red: 0.91, green: 0.96, blue: 0.91)
    static let liveActivityMint = Color(red: 0.62, green: 0.90, blue: 0.74)
    static let liveActivityAmber = Color(red: 0.95, green: 0.69, blue: 0.39)
}
