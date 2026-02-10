import AVFoundation
import UIKit

final class SoundManager {
    static let shared = SoundManager()

    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private var isSoundEnabled = true

    private init() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
    }

    func preloadSound(named name: String, extension ext: String = "wav") {
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else { return }
        audioPlayers[name] = try? AVAudioPlayer(contentsOf: url)
        audioPlayers[name]?.prepareToPlay()
    }

    func play(_ name: String) {
        guard isSoundEnabled else { return }
        audioPlayers[name]?.currentTime = 0
        audioPlayers[name]?.play()
    }

    func toggleSound(_ enabled: Bool) {
        isSoundEnabled = enabled
    }
}

// MARK: - Haptic Manager

enum HapticManager {
    static func questCompleted() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func objectiveCompleted() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func questFailed() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}
