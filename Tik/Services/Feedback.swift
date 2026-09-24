import AVFoundation
import UIKit

/// Haptics and sounds. Each one can be turned off in Settings.
@MainActor
enum Feedback {
    /// A task was ticked or unticked.
    static func tick(done: Bool) {
        if hapticsOn {
            UIImpactFeedbackGenerator(style: done ? .medium : .light).impactOccurred()
        }
        if done && soundsOn {
            SoundPlayer.shared.play(.tick)
        }
    }

    /// A task was added.
    static func added() {
        if hapticsOn {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }
    }

    /// The last task of the day was ticked.
    static func celebrate() {
        if hapticsOn {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        if soundsOn {
            SoundPlayer.shared.play(.celebrate)
        }
    }

    private static var hapticsOn: Bool { UserDefaults.tik.bool(forKey: PrefKey.haptics) }
    private static var soundsOn: Bool { UserDefaults.tik.bool(forKey: PrefKey.sounds) }
}

/// Plays the two short sounds made by Scripts/make-sounds.py.
///
/// Everything that touches audio runs on one background queue: it talks to
/// the audio system, which can briefly block, and the main thread should
/// never wait for a sound. The players are only used on that queue.
final class SoundPlayer: @unchecked Sendable {
    enum Sound: String, CaseIterable {
        case tick
        case celebrate
    }

    static let shared = SoundPlayer()

    private let queue = DispatchQueue(label: "com.mahyarmozafar.tik.sounds", qos: .userInitiated)
    private var players: [Sound: AVAudioPlayer] = [:]

    private init() {}

    /// Loads the sounds. Called once at launch.
    func prepare() {
        queue.async { [self] in
            // Mix with music, and stay quiet when the phone is on silent.
            let session = AVAudioSession.sharedInstance()
            try? session.setCategory(.ambient, options: [.mixWithOthers])
            try? session.setActive(true)

            for sound in Sound.allCases {
                guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "wav"),
                      let player = try? AVAudioPlayer(contentsOf: url) else { continue }
                player.volume = sound == .tick ? 0.6 : 0.75
                player.prepareToPlay()
                players[sound] = player
            }
        }
    }

    func play(_ sound: Sound) {
        queue.async { [self] in
            guard let player = players[sound] else { return }
            player.currentTime = 0
            player.play()
        }
    }
}
