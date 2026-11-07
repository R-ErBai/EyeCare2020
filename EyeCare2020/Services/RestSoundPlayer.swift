import AVFoundation

final class RestSoundPlayer {
    private let session = AVAudioSession.sharedInstance()
    private var player: AVAudioPlayer?

    func play(_ sound: RestEndSound) {
        guard let url = Bundle.main.url(
            forResource: sound.rawValue,
            withExtension: "wav"
        ) else {
            return
        }

        do {
            try session.setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers]
            )
            try session.setActive(true)

            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = 0.72
            player.prepareToPlay()
            player.play()
            self.player = player
        } catch {
            // The system notification still carries the same sound.
        }
    }

    func stop() {
        player?.stop()
        player = nil
    }
}
