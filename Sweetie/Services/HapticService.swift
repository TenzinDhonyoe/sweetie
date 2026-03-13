import UIKit

enum HapticService {
    static func tap() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func heavyTap() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    // MARK: - Tap Preset Patterns

    /// 💕 — 3x light impacts at 80ms intervals
    static func tripleQuick() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            generator.impactOccurred()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            generator.impactOccurred()
        }
    }

    /// 🤗 — 1x heavy impact for a hug feel
    static func longHug() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred(intensity: 1.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            generator.impactOccurred(intensity: 0.6)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
            generator.impactOccurred(intensity: 0.3)
        }
    }

    /// 😘 — 2x medium impacts at 120ms interval
    static func doubleKiss() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            generator.impactOccurred()
        }
    }

    /// 🌙 — soft → medium fade
    static func gentleNight() {
        let light = UIImpactFeedbackGenerator(style: .light)
        let medium = UIImpactFeedbackGenerator(style: .medium)
        light.prepare()
        medium.prepare()
        light.impactOccurred(intensity: 0.4)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            medium.impactOccurred(intensity: 0.6)
        }
    }

    /// ☀️ — light → medium → heavy ascending
    static func morningRise() {
        let light = UIImpactFeedbackGenerator(style: .light)
        let medium = UIImpactFeedbackGenerator(style: .medium)
        let heavy = UIImpactFeedbackGenerator(style: .heavy)
        light.prepare()
        medium.prepare()
        heavy.prepare()
        light.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
            medium.impactOccurred()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
            heavy.impactOccurred()
        }
    }

    /// Play the haptic for a given pattern string
    static func playPattern(_ pattern: String) {
        switch pattern {
        case "love": tripleQuick()
        case "hug": longHug()
        case "kiss": doubleKiss()
        case "goodnight": gentleNight()
        case "morning": morningRise()
        default: tap()
        }
    }
}
