import SwiftUI

// MARK: - Equalizer Section
struct WinampEqualizerSection: View {
  @Binding var gains: [Float]
  let frequencies: [String] = ["32", "64", "125", "250", "500", "1K", "2K", "4K", "8K", "16K"]
  @State private var selectedPreset: EqualizerPreset = .normal

  var body: some View {
    VStack(spacing: 4) {
      // EQ Title
      HStack {
        Text("EQUALIZER")
          .font(.system(size: 9, weight: .bold))
          .foregroundColor(Color(hex: "00FF00"))

        Menu(selectedPreset.rawValue) {
          ForEach(EqualizerPreset.allCases, id: \.self) { preset in
            Button(preset.rawValue) {
              selectedPreset = preset
              applyPreset(preset)
            }
          }
        }
        .font(.system(size: 8))
        .foregroundColor(Color(hex: "00FF00"))
        .frame(width: 60)

        Spacer()

        Text("PREAMP")
          .font(.system(size: 9, weight: .bold))
          .foregroundColor(Color(hex: "00FF00"))
      }
      .padding(.horizontal, 12)
      .padding(.top, 4)

      // EQ Sliders
      HStack(spacing: 6) {
        ForEach(0..<gains.count, id: \.self) { index in
          VStack(spacing: 2) {
            // Slider Track
            ZStack(alignment: .center) {
              // Track background with color based on position
              let normalizedGain = (gains[index] + 12) / 24  // Normalize to 0-1
              let trackColor = trackColorForPosition(normalizedGain)

              RoundedRectangle(cornerRadius: 2)
                .fill(trackColor)
                .frame(width: 20, height: 140)
                .overlay(
                  RoundedRectangle(cornerRadius: 2)
                    .stroke(Color(hex: "0A0A0A"), lineWidth: 1)
                )
                .shadow(color: trackColor, radius: 4, x: 0, y: 0)

              // Center line
              Rectangle()
                .fill(Color.black.opacity(0.3))
                .frame(width: 20, height: 1)

              // Slider handle - always gray
              let sliderY = 140 * (1 - CGFloat(normalizedGain))  // Calculate Y position

              RoundedRectangle(cornerRadius: 1)
                .fill(
                  LinearGradient(
                    gradient: Gradient(colors: [
                      Color(hex: "EEEEEE"),
                      Color(hex: "999999"),
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                  )
                )
                .frame(width: 18, height: 6)
                .position(x: 10, y: sliderY)
                .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
                .gesture(
                  DragGesture()
                    .onChanged { value in
                      let newY = max(0, min(value.location.y, 140))
                      let normalizedValue = 1 - (newY / 140)
                      gains[index] = Float(normalizedValue * 24 - 12)
                    }
                )
            }
            .frame(width: 20, height: 140)

            // Frequency label
            Text(frequencies[index])
              .font(.system(size: 7, weight: .bold))
              .foregroundColor(Color(hex: "00FF00"))
          }
        }
      }
    }
  }

  // Calculate track color based on position (0-1)
  private func trackColorForPosition(_ position: Float) -> Color {
    if position < 0.5 {
      // Green to Yellow transition (bottom to middle)
      let t = position * 2  // Scale to 0-1 range
      return Color(
        red: Double(t),  // Red increases from 0 to 1
        green: 1.0,  // Green stays at 1
        blue: 0.0  // Blue stays at 0
      )
    } else {
      // Yellow to Red transition (middle to top)
      let t = (position - 0.5) * 2  // Scale to 0-1 range
      return Color(
        red: 1.0,  // Red stays at 1
        green: Double(1.0 - t),  // Green decreases from 1 to 0
        blue: 0.0  // Blue stays at 0
      )
    }
  }

  private func applyPreset(_ preset: EqualizerPreset) {
    for i in 0..<gains.count {
      gains[i] = preset.gains[i]
    }
  }
}

// MARK: - Preview
#Preview {
  WinampEqualizerSection(gains: .constant(Array(repeating: 0, count: 10)))
}
