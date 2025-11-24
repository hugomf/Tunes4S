import Foundation
import Combine

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
                peakHeights[i] = binValue  // Update peak if spectrum value is higher
            }
        }
    }

    private func startPeakDecay() {
        peakTimer?.invalidate()
        peakTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            for i in 0..<self.peakHeights.count {
                self.peakHeights[i] = max(0.0, self.peakHeights[i] - 0.05)  // Decay by 0.05 per tick
            }
        }
    }

    private func stopPeakDecay() {
        peakTimer?.invalidate()
        peakTimer = nil
        peakHeights = Array(repeating: 0.0, count: 20)  // Reset peaks when stopped
    }
}
