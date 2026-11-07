import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: TimerViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var isShowingWorkDurationSettings = false

    var body: some View {
        GeometryReader { proxy in
            let dialSize = min(proxy.size.width - 52, 356)
            let accent = AppTheme.accent(for: model.phase)

            ZStack {
                background

                VStack(spacing: 0) {
                    header
                        .padding(.horizontal, 24)
                        .padding(.top, 18)

                    Spacer(minLength: 24)

                    timerDial(size: dialSize, accent: accent)

                    phaseCopy(accent: accent)
                        .padding(.top, 28)

                    Spacer(minLength: 24)

                    footer(accent: accent)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 18)
                }
            }
            .animation(
                reduceMotion ? nil : .easeInOut(duration: 0.55),
                value: model.phase
            )
            .animation(
                reduceMotion ? nil : .easeInOut(duration: 0.3),
                value: model.status
            )
        }
        .preferredColorScheme(.dark)
        .overlay {
            if model.isAwaitingRestChoice {
                RestChoiceOverlay(
                    secondsRemaining: model.restChoiceSecondsRemaining
                ) { duration in
                    model.selectRest(duration)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.97)))
            }
        }
        .animation(
            reduceMotion ? nil : .easeInOut(duration: 0.25),
            value: model.isAwaitingRestChoice
        )
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                model.refreshNotificationAuthorization()
            }
        }
        .sheet(isPresented: $isShowingWorkDurationSettings) {
            WorkDurationSettingsSheet(
                workMinutes: Binding(
                    get: { model.workMinutes },
                    set: { model.setWorkDuration(minutes: $0) }
                ),
                restEndSound: model.restEndSound,
                onSelectSound: { sound in
                    model.setRestEndSound(sound)
                },
                onPreviewSound: {
                    model.previewRestEndSound()
                }
            )
            .presentationDetents([.height(620)])
            .presentationDragIndicator(.visible)
        }
    }

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [AppTheme.forest, AppTheme.moss.opacity(0.82), AppTheme.forest],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    AppTheme.accent(for: model.phase).opacity(model.phase == .work ? 0.18 : 0.24),
                    .clear
                ],
                center: .center,
                startRadius: 30,
                endRadius: 330
            )
        }
        .ignoresSafeArea()
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text("远眺")
                    .font(.system(size: 26, weight: .semibold, design: .serif))
                    .foregroundStyle(AppTheme.paper)

                Text("20 · 20 · 20")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .tracking(2.4)
                    .foregroundStyle(AppTheme.paper.opacity(0.55))
            }

            Spacer()

            HStack(spacing: 8) {
                Button {
                    isShowingWorkDurationSettings = true
                } label: {
                    Label("\(model.workMinutes) 分钟", systemImage: "timer")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.paper.opacity(0.76))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(.white.opacity(0.07), in: Capsule())
                        .overlay {
                            Capsule()
                                .stroke(.white.opacity(0.08), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("work-duration-settings-button")

                if model.completedWorkCycles > 0 {
                    Text("第 \(model.completedWorkCycles) 轮")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.paper.opacity(0.7))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(.white.opacity(0.07), in: Capsule())
                        .overlay {
                            Capsule()
                                .stroke(.white.opacity(0.08), lineWidth: 1)
                        }
                }
            }
        }
    }

    private func timerDial(size: CGFloat, accent: Color) -> some View {
        ZStack {
            Circle()
                .stroke(accent.opacity(0.1), lineWidth: 1)
                .frame(width: size * 0.82, height: size * 0.82)

            ForEach(0..<20, id: \.self) { index in
                MinuteTick(
                    isSpent: model.progress >= Double(index + 1) / 20,
                    accent: accent,
                    size: size
                )
                .rotationEffect(.degrees(Double(index) * 18))
            }

            VStack(spacing: 8) {
                Text(model.phaseTitle)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .tracking(1.6)
                    .foregroundStyle(accent.opacity(0.92))

                Text(model.timeText)
                    .font(.system(size: size * 0.205, weight: .thin, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(AppTheme.paper)
                    .contentTransition(.numericText(countsDown: true))
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                    .accessibilityLabel("剩余时间")
                    .accessibilityValue(model.timerAccessibilityValue)

                if model.status == .locked {
                    Label("已暂停", systemImage: "lock.fill")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.paper.opacity(0.64))
                }
            }
            .frame(width: size * 0.62)
        }
        .frame(width: size, height: size)
    }

    private func phaseCopy(accent: Color) -> some View {
        VStack(spacing: 9) {
            Text(
                model.phase == .lookAway && model.status == .running
                    ? "6 米外"
                    : "\(model.workMinutes) 分钟"
            )
                .font(.system(size: 15, weight: .semibold, design: .serif))
                .foregroundStyle(accent)

            Text(model.phaseSubtitle)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(AppTheme.paper.opacity(0.66))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .frame(maxWidth: 300)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func footer(accent: Color) -> some View {
        VStack(spacing: 12) {
            if let notice = model.notice {
                Text(notice)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.paper.opacity(0.76))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(.black.opacity(0.16), in: RoundedRectangle(cornerRadius: 12))
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            if model.notificationPermissionDenied {
                Button {
                    model.openNotificationSettings()
                } label: {
                    Label("打开通知设置", systemImage: "bell.badge")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.amber)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.white.opacity(0.06), in: Capsule())
                }
                .buttonStyle(.plain)
            }

            Button {
                model.toggle()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: model.isRunning ? "stop.fill" : "eye.fill")
                        .font(.system(size: 15, weight: .semibold))

                    Text(model.buttonTitle)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(model.isRunning ? AppTheme.paper : AppTheme.forest)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(model.isRunning ? Color.white.opacity(0.08) : AppTheme.paper)
                        .overlay {
                            if model.isRunning {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(.white.opacity(0.14), lineWidth: 1)
                            }
                        }
                }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("timer-toggle-button")

            Text("熄屏暂停 · 超过 1 分钟重新开始")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.paper.opacity(0.38))
                .padding(.bottom, 2)
        }
    }
}

private struct WorkDurationSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var workMinutes: Int
    let restEndSound: RestEndSound
    let onSelectSound: (RestEndSound) -> Void
    let onPreviewSound: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppTheme.forest, AppTheme.moss.opacity(0.88)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("用眼时长")
                            .font(.system(size: 22, weight: .semibold, design: .serif))
                            .foregroundStyle(AppTheme.paper)

                        Text("默认 20 分钟，计时中修改会在下一轮生效")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.paper.opacity(0.5))
                    }

                    Spacer()

                    Button("完成") {
                        dismiss()
                    }
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.mint)
                }
                .padding(.horizontal, 22)
                .padding(.top, 14)

                Picker("每轮用眼时长", selection: $workMinutes) {
                    ForEach(
                        TimerCore.minimumWorkMinutes...TimerCore.maximumWorkMinutes,
                        id: \.self
                    ) { minutes in
                        Text("\(minutes) 分钟")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.paper)
                            .tag(minutes)
                    }
                }
                .pickerStyle(.wheel)
                .padding(.horizontal, 16)

                Divider()
                    .overlay(.white.opacity(0.08))
                    .padding(.horizontal, 22)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("休息结束提示音")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppTheme.paper)

                        Spacer()

                        Button {
                            onPreviewSound()
                        } label: {
                            Label("试听", systemImage: "speaker.wave.2")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(AppTheme.mint)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 22)

                    HStack(spacing: 8) {
                        ForEach(RestEndSound.allCases, id: \.self) { sound in
                            Button {
                                onSelectSound(sound)
                            } label: {
                                VStack(spacing: 5) {
                                    Image(
                                        systemName: restEndSound == sound
                                            ? "checkmark.circle.fill"
                                            : "circle"
                                    )
                                    .font(.system(size: 17, weight: .semibold))

                                    Text(sound.title)
                                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.75)
                                }
                                .foregroundStyle(
                                    restEndSound == sound
                                        ? AppTheme.mint
                                        : AppTheme.paper.opacity(0.62)
                                )
                                .frame(maxWidth: .infinity)
                                .frame(height: 62)
                                .background(
                                    .white.opacity(restEndSound == sound ? 0.1 : 0.05),
                                    in: RoundedRectangle(cornerRadius: 14)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 22)
                }
                .padding(.bottom, 10)
            }
            .padding(.bottom, 8)
        }
        .preferredColorScheme(.dark)
    }
}

private struct RestChoiceOverlay: View {
    let secondsRemaining: Int
    let onSelect: (TimerCore.RestDuration) -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.62)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "eye")
                    .font(.system(size: 30, weight: .light))
                    .foregroundStyle(AppTheme.mint)
                    .padding(.top, 4)

                VStack(spacing: 8) {
                    Text("该让眼睛休息了")
                        .font(.system(size: 25, weight: .semibold, design: .serif))
                        .foregroundStyle(AppTheme.paper)

                    Text("看向约 6 米外，让眼睛放松一下")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(AppTheme.paper.opacity(0.68))
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 10) {
                    choiceButton(
                        title: "休息 20 秒",
                        detail: "标准 20-20-20 节奏",
                        icon: "timer",
                        color: AppTheme.mint
                    ) {
                        onSelect(.twentySeconds)
                    }

                    choiceButton(
                        title: "休息 1 分钟",
                        detail: "这次多放松一会儿",
                        icon: "hourglass",
                        color: AppTheme.amber
                    ) {
                        onSelect(.oneMinute)
                    }
                }

                Text("\(max(0, secondsRemaining)) 秒后默认休息 20 秒")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.paper.opacity(0.48))
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 24)
            .frame(maxWidth: 350)
            .background {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(LinearGradient(
                        colors: [AppTheme.moss, AppTheme.forest],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .overlay {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(.white.opacity(0.12), lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(0.38), radius: 32, y: 18)
            }
            .padding(.horizontal, 24)
        }
        .accessibilityAddTraits(.isModal)
    }

    private func choiceButton(
        title: String,
        detail: String,
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 13) {
                Image(systemName: icon)
                    .font(.system(size: 26))
                    .foregroundStyle(color)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.paper)

                    Text(detail)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.paper.opacity(0.5))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.paper.opacity(0.36))
            }
            .padding(.horizontal, 16)
            .frame(height: 60)
            .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 17))
            .overlay {
                RoundedRectangle(cornerRadius: 17)
                    .stroke(color.opacity(0.25), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct MinuteTick: View {
    let isSpent: Bool
    let accent: Color
    let size: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(accent.opacity(isSpent ? 0.1 : 0.92))
            .frame(width: 3, height: isSpent ? 10 : 17)
            .offset(y: -size * 0.46)
            .animation(.easeInOut(duration: 0.3), value: isSpent)
    }
}

#Preview {
    ContentView()
        .environmentObject(TimerViewModel())
}
