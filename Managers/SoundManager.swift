import AVFoundation

/// Lightweight sound effects synthesized at runtime (sine bursts) so the app bundles no
/// audio assets. All playback respects the user's sound setting and mixes with other audio.
final class SoundManager {
    static let shared = SoundManager()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let sampleRate = 44_100.0
    private let format: AVAudioFormat
    private var started = false
    private var cache: [String: AVAudioPCMBuffer] = [:]

    private var enabled: Bool { SettingsManager.shared.soundEnabled }

    private init() {
        format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
    }

    func start() {
        guard !started else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            try engine.start()
            player.play()
            started = true
        } catch {
            started = false
        }
    }

    private func tone(_ key: String, frequency: Double, duration: Double, volume: Float = 0.25) -> AVAudioPCMBuffer? {
        if let cached = cache[key] { return cached }
        let frames = AVAudioFrameCount(duration * sampleRate)
        guard frames > 0, let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames) else { return nil }
        buf.frameLength = frames
        let data = buf.floatChannelData![0]
        let omega = 2.0 * Double.pi * frequency
        for i in 0..<Int(frames) {
            let t = Double(i) / sampleRate
            let attack = min(1.0, t / 0.005)
            let release = min(1.0, (duration - t) / 0.02)
            let env = Float(max(0.0, min(attack, release)))
            data[i] = Float(sin(omega * t)) * volume * env
        }
        cache[key] = buf
        return buf
    }

    private func play(_ buffer: AVAudioPCMBuffer?) {
        guard enabled, started, let buffer else { return }
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
    }

    func move()    { play(tone("move", frequency: 220, duration: 0.04, volume: 0.12)) }
    func rotate()  { play(tone("rotate", frequency: 330, duration: 0.05, volume: 0.15)) }
    func lock()    { play(tone("lock", frequency: 160, duration: 0.06, volume: 0.2)) }
    func hardDrop(){ play(tone("drop", frequency: 110, duration: 0.07, volume: 0.25)) }
    func lineClear(_ lines: Int) {
        play(tone("clear\(lines)", frequency: 440 + Double(lines) * 110, duration: 0.18, volume: 0.3))
    }
    func tspin()   { play(tone("tspin", frequency: 660, duration: 0.2, volume: 0.3)) }
    func levelUp() { play(tone("level", frequency: 880, duration: 0.2, volume: 0.3)) }
    func gameOver(){ play(tone("over", frequency: 130, duration: 0.4, volume: 0.3)) }
}
