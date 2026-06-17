import SwiftUI

/// Game settings: feedback toggles, ghost piece, and the touch control scheme + auto-shift.
struct SettingsView: View {
    @ObservedObject private var settings = SettingsManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section("Feedback") {
                    Toggle("Haptics", isOn: $settings.hapticsEnabled)
                    Toggle("Sound effects", isOn: $settings.soundEnabled)
                }
                Section("Gameplay") {
                    Toggle("Ghost piece", isOn: $settings.ghostEnabled)
                }
                Section("Controls") {
                    Picker("Scheme", selection: $settings.controlScheme) {
                        ForEach(ControlScheme.allCases) { Text($0.displayName).tag($0) }
                    }
                    Text(settings.controlScheme.detail).font(.caption).foregroundColor(.secondary)
                }
                Section("Auto-shift (advanced)") {
                    VStack(alignment: .leading) {
                        Text("DAS: \(Int(settings.dasMilliseconds)) ms").font(.caption)
                        Slider(value: $settings.dasMilliseconds, in: 50...400, step: 1)
                    }
                    VStack(alignment: .leading) {
                        Text("ARR: \(Int(settings.arrMilliseconds)) ms").font(.caption)
                        Slider(value: $settings.arrMilliseconds, in: 0...120, step: 1)
                    }
                    Text("Delay before a held move repeats, and the repeat rate. Lower is faster.")
                        .font(.caption2).foregroundColor(.secondary)
                }
                Section {
                    Button(role: .destructive) { settings.resetToDefaults() } label: {
                        Text("Reset to Defaults")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
