import Foundation
import SwiftUI

/// ViewModel for equalizer functionality
class EqualizerViewModel: ObservableObject {
    // Published properties
    @Published var gains: [Float] = Array(repeating: 0, count: 10)
    @Published var selectedPreset: EqualizerPreset = .normal
    @Published var isEnabled = true

    // Audio service dependency (injected)
    private let audioService: AudioService

    let frequencies: [String] = ["32", "64", "125", "250", "500", "1K", "2K", "4K", "8K", "16K"]

    init(audioService: AudioService = AudioService()) {
        self.audioService = audioService
        loadDefaultPreset()
    }

    // MARK: - Gain Management

    func setGain(_ gain: Float, forBand band: Int) {
        guard band >= 0 && band < gains.count else { return }

        // Clamp gain between -12 and +12 dB (typical equalizer range)
        let clampedGain = min(max(gain, -12), 12)
        gains[band] = clampedGain

        // Apply to audio service if enabled
        if isEnabled {
            audioService.setGain(clampedGain, forBandAt: band)
        }
    }

    func getGain(forBand band: Int) -> Float {
        guard band >= 0 && band < gains.count else { return 0 }
        return gains[band]
    }

    // MARK: - Preset Management

    func applyPreset(_ preset: EqualizerPreset) {
        selectedPreset = preset
        gains = preset.gains

        if isEnabled {
            for i in 0..<gains.count {
                audioService.setGain(preset.gains[i], forBandAt: i)
            }
        }
    }

    func loadDefaultPreset() {
        applyPreset(.normal)
    }

    // MARK: - Equalizer State

    func toggleEnabled() {
        isEnabled.toggle()
        applyCurrentSettings()
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        applyCurrentSettings()
    }

    func applyCurrentSettings() {
        if isEnabled {
            for i in 0..<gains.count {
                audioService.setGain(gains[i], forBandAt: i)
            }
        } else {
            // Reset to flat (no equalization)
            for i in 0..<gains.count {
                audioService.setGain(0, forBandAt: i)
            }
        }
    }

    // MARK: - Reset Functions

    func resetToFlat() {
        gains = Array(repeating: 0, count: 10)
        selectedPreset = .normal

        if isEnabled {
            for i in 0..<gains.count {
                audioService.setGain(0, forBandAt: i)
            }
        }
    }

    func resetToPreset() {
        applyPreset(selectedPreset)
    }

    // MARK: - Computed Properties

    var maxGain: Float { 12.0 }
    var minGain: Float { -12.0 }

    var overallBoost: Float {
        gains.reduce(0, +) / Float(gains.count)
    }

    var hasChangesFromPreset: Bool {
        selectedPreset.gains != gains
    }

    var currentGainDescription: String {
        if !isEnabled {
            return "Disabled (Flat)"
        }

        if gains.allSatisfy({ $0 == 0 }) {
            return "Flat Response"
        }

        let avgGain = overallBoost
        if avgGain > 0.5 {
            return "Boosted (\(String(format: "%.1f", avgGain)) dB)"
        } else if avgGain < -0.5 {
            return "Cut (\(String(format: "%.1f", avgGain)) dB)"
        } else {
            return "Flat (\(String(format: "%.1f", avgGain)) dB)"
        }
    }
}

// MARK: - Extensions

extension EqualizerViewModel {
    func saveCustomPreset(name: String) -> EqualizerPreset {
        return EqualizerPreset(name: name, gains: gains)
    }
}

extension EqualizerPreset {
    init(name: String, gains: [Float]) {
        // This would be extended in a real app to support custom presets
        // For now, we'll just return normal since we can't add cases dynamically
        self = .normal
    }
}
