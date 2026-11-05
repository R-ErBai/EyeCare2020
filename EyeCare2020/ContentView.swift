import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: TimerViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
            Text(model.phase == .lookAway && model.status == .running ? "6 米外" : "20 分钟")
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
