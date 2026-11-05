import AVFoundation

final class BackgroundAudioKeeper {
    var onFailure: ((String) -> Void)?

    private let session = AVAudioSession.sharedInstance()
    private var player: AVAudioPlayer?
    private var shouldPlay = false
    private var interruptionObserver: NSObjectProtocol?

    init() {
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: session,
            queue: .main
        ) { [weak self] notification in
            self?.handleInterruption(notification)
        }
    }

    deinit {
        if let interruptionObserver {
            NotificationCenter.default.removeObserver(interruptionObserver)
        }
    }

    func start() {
        shouldPlay = true

        do {
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)

            if let player {
                player.play()
                return
            }

            guard let url = Bundle.main.url(forResource: "silence", withExtension: "wav") else {
                onFailure?("后台音频资源缺失，熄屏判断可能延迟。")
                return
            }

            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.prepareToPlay()
            player.play()
            self.player = player
        } catch {
            onFailure?("后台保持失败，熄屏判断可能延迟。")
        }
    }

    func stop() {
        shouldPlay = false
        player?.stop()
        player = nil

        do {
            try session.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            // The session may already be inactive; stopping the timer is still complete.
        }
    }

    private func handleInterruption(_ notification: Notification) {
        guard
            let rawType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: rawType),
            type == .ended,
            shouldPlay
        else {
            return
        }

        do {
            try session.setActive(true)
            player?.play()
        } catch {
            onFailure?("音频中断后未能恢复后台保持。")
        }
    }
}
