//
//  Components.swift
//  Tunes4S
//
//  Created by Hugo Martinez Fernandez on 11/20/25.
//  
//  This file contains all extracted UI components: spectrum, equalizer, etc.
//

import SwiftUI
import Combine

// MARK: - Spectrum Components

class SpectrumViewModel: ObservableObject {
    var spectrumData: [Float] = Array(repeating: 0, count: 20)
    var peakHeights: [Float] = Array(repeating: 0, count: 20)
    private var peakTimer: Timer?

    init() {
        startPeakDecay()
    }

    deinit {
        stopPeakDecay()
    }

    func updateSpectrum(_ newSpectrumData: [Float]) {
        spectrumData = newSpectrumData

        // Update peak heights when new spectrum data arrives
        for i in 0..<newSpectrumData.count {
            let binValue = newSpectrumData[i]
            if binValue > peakHeights[i] {
                peakHeights[i] = binValue // Update peak if spectrum value is higher
            }
        }
    }

    private func startPeakDecay() {
        peakTimer?.invalidate()
        peakTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            for i in 0..<self.peakHeights.count {
                self.peakHeights[i] = max(0.0, self.peakHeights[i] - 0.05) // Decay by 0.05 per tick
            }
        }
    }

    private func stopPeakDecay() {
        peakTimer?.invalidate()
        peakTimer = nil
        peakHeights = Array(repeating: 0.0, count: 20) // Reset peaks when stopped
    }
}

struct WinampLEDSpectrumAnalyzer: View {
    @Binding var isPlaying: Bool
    let spectrumData: [Float]
    let peakHeights: [Float]
    private let spectrumBins = 20
    private let verticalLeds = 16 // More vertical LED bars
    let compact: Bool

    init(isPlaying: Binding<Bool>, spectrumData: [Float], peakHeights: [Float], compact: Bool = false) {
        self._isPlaying = isPlaying
        self.spectrumData = spectrumData
        self.peakHeights = peakHeights
        self.compact = compact
    }

    var body: some View {
        ZStack {
            // Spectrum bars (background)
            VStack(spacing: 0.5) {
                ForEach(0..<verticalLeds, id: \.self) { row in
                    HStack(spacing: 0.5) {
                        ForEach(0..<spectrumBins, id: \.self) { column in
                            RoundedRectangle(cornerRadius: 0.25)
                                .fill(getLEDColor(for: row, column: column))
                                .frame(width: compact ? 2 : 3, height: compact ? 2 : 3)
                        }
                    }
                }
            }

            // Peak dots (foreground) - white bouncing dots on top
            VStack(spacing: 0.5) {
                ForEach(0..<verticalLeds, id: \.self) { row in
                    HStack(spacing: 0.5) {
                        ForEach(0..<spectrumBins, id: \.self) { column in
                            RoundedRectangle(cornerRadius: 0.25)
                                .fill(getPeakColor(for: row, column: column))
                                .frame(width: compact ? 2 : 3, height: compact ? 2 : 3)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 6)
    }

    private func getLEDColor(for row: Int, column: Int) -> Color {
        guard isPlaying else { return Color(hex: "001100") } // Darker off color

        // Get the frequency bin value (0-1, linear)
        let binValue = column < spectrumData.count ? spectrumData[column] : 0.0

        // Convert bin value to LED intensity (0-verticalLeds bars depending on value)
        let ledIntensity = Int(binValue * Float(verticalLeds))

        // Row logic: higher frequencies (smaller row numbers) get more active LEDs
        // Reverse the row logic so bars grow upward from the bottom
        let reversedRowIndex = verticalLeds - 1 - row
        let isActive = reversedRowIndex < ledIntensity

        if !isActive {
            return Color(hex: "003300")
        }

        // Color based on row position (0-15) for gradient effect within columns
        // Classic Winamp: bottom = green, middle = yellow, top = red
        // row 0-7: top quarter, red
        // row 8-11: middle half, yellow
        // row 12-15: bottom quarter, green
        if row < 4 {
            // Top 25% of display: red when active (reaches max height)
            return Color(hex: "FF0000")
        } else if row < 10 {
            // Middle 50% of display: yellow when active (bars must reach 62.5%+ height)
            return Color(hex: "FFFF00")
        } else {
            // Bottom 25% of display: green when active (lower amplitude = green tones)
            return Color(hex: "00FF00")
        }
    }

    private func getPeakColor(for row: Int, column: Int) -> Color {
        guard isPlaying else { return Color.clear } // No peaks when not playing

        // Get the peak height value (0-1, linear)
        let peakValue = column < peakHeights.count ? peakHeights[column] : 0.0

        // Convert peak value to LED position (which row should show the peak)
        let peakRow = Int(peakValue * Float(verticalLeds))

        // Row logic: higher frequencies get peaks at lower row numbers
        let reversedPeakRowIndex = verticalLeds - 1 - peakRow

        // Show white peak dot if this row is at the exact peak position
        if row == reversedPeakRowIndex && peakValue > 0.0 {
            return Color.white // Winamp-style bouncing peak dot
        } else {
            return Color.clear // Transparent (no peak here)
        }
    }
}

// MARK: - Previews
#if DEBUG
struct WinampLEDSpectrumAnalyzer_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            WinampLEDSpectrumAnalyzer(
                isPlaying: .constant(true),
                spectrumData: Array(repeating: 0.8, count: 20),
                peakHeights: [0.9, 0.8, 0.7, 0.6, 0.5, 0.4, 0.3, 0.2, 0.1, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
                compact: true
            )
            .frame(height: 60)
        }
        .background(Color.black)
    }
}
#endif
