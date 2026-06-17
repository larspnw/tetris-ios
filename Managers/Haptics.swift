import UIKit

/// Thin wrapper over UIKit feedback generators. Generators are prepared ahead of time to
/// minimize first-tap latency, and every call respects the user's haptics setting.
final class Haptics {
    static let shared = Haptics()

    private let light = UIImpactFeedbackGenerator(style: .light)
    private let medium = UIImpactFeedbackGenerator(style: .medium)
    private let heavy = UIImpactFeedbackGenerator(style: .heavy)
    private let rigid = UIImpactFeedbackGenerator(style: .rigid)
    private let notify = UINotificationFeedbackGenerator()

    private var enabled: Bool { SettingsManager.shared.hapticsEnabled }

    private init() {}

    /// Warm up the generators (call when a game starts).
    func prepare() {
        light.prepare(); medium.prepare(); heavy.prepare(); rigid.prepare()
    }

    func move()   { guard enabled else { return }; light.impactOccurred(intensity: 0.5) }
    func rotate() { guard enabled else { return }; light.impactOccurred(intensity: 0.7) }
    func lock()   { guard enabled else { return }; medium.impactOccurred() }
    func hardDrop() { guard enabled else { return }; rigid.impactOccurred() }
    func lineClear(_ lines: Int) {
        guard enabled else { return }
        if lines >= 4 { heavy.impactOccurred(intensity: 1.0) }
        else { medium.impactOccurred(intensity: 0.8) }
    }
    func tspin()    { guard enabled else { return }; heavy.impactOccurred(intensity: 0.9) }
    func levelUp()  { guard enabled else { return }; notify.notificationOccurred(.success) }
    func gameOver() { guard enabled else { return }; notify.notificationOccurred(.error) }
}
