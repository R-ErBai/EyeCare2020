import SwiftUI

enum AppTheme {
    static let forest = Color(red: 0.025, green: 0.10, blue: 0.085)
    static let moss = Color(red: 0.07, green: 0.22, blue: 0.18)
    static let mint = Color(red: 0.62, green: 0.90, blue: 0.74)
    static let paper = Color(red: 0.91, green: 0.96, blue: 0.91)
    static let amber = Color(red: 0.95, green: 0.69, blue: 0.39)
    static let danger = Color(red: 0.96, green: 0.55, blue: 0.46)

    static func accent(for phase: TimerCore.Phase) -> Color {
        phase == .work ? mint : amber
    }
}
