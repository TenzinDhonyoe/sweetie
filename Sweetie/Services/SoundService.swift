import AVFoundation

@MainActor
enum SoundService {
    private static var player: AVAudioPlayer?

    static func play(_ sound: Sound) {
        guard let url = Bundle.main.url(forResource: sound.filename, withExtension: "wav") else { return }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.play()
        } catch {
            // Silently fail — sounds are non-critical
        }
    }

    enum Sound {
        case pop
        case chime
        case paperRustle

        var filename: String {
            switch self {
            case .pop: "pop"
            case .chime: "chime"
            case .paperRustle: "paper-rustle"
            }
        }
    }
}
