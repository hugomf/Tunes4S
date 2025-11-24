import SwiftUI

struct WinampTimeDisplay: View {
    let time: Double
    let isRemaining: Bool

    init(time: Double, isRemaining: Bool = false) {
        self.time = time
        self.isRemaining = isRemaining
    }

    var body: some View {
        HStack(spacing: 1) {
            ForEach(Array(formatTime(time).enumerated()), id: \.offset) { index, char in
                Text(String(char))
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(hex: "00FF00"))
                    .frame(width: 10, height: 18)
            }
        }
        .padding(2)
        .background(Color.black)
        .overlay(Rectangle().stroke(Color(hex: "1A1A1A"), lineWidth: 1))
    }

    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: isRemaining ? "-%d:%02d" : "%d:%02d", minutes, seconds)
    }
}
