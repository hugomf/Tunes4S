import SwiftUI

// MARK: - Visual Time Progress Section
struct WinampProgressSection: View {
  @Binding var progress: Double
  @Binding var duration: Double
  var onSeek: (Double) -> Void
  @State private var isDragging = false
  @State private var dragProgress: Double = 0

  var body: some View {
    GeometryReader { geometry in
      VStack(spacing: 4) {
        // Calculate responsive number of dots based on width
        let availableWidth = geometry.size.width - 32  // Subtract padding
        let dotWidth: CGFloat = max(2, min(6, availableWidth / 50))  // Scale dot width 2-6px
        let spacing: CGFloat = max(1, min(4, (availableWidth - (dotWidth * 50)) / 49))  // Scale spacing
        let actualDots = max(20, min(100, Int(availableWidth / (dotWidth + 2))))  // 20-100 dots

        // Visual progress bar with responsive dots
        HStack(spacing: spacing) {
          ForEach(0..<actualDots, id: \.self) { index in
            let progressRatio = (isDragging ? dragProgress : progress) / max(duration, 1)
            let isActive = Double(index) / Double(actualDots) <= progressRatio

            Rectangle()
              .fill(isActive ? Color(hex: "00FF00") : Color(hex: "003300"))
              .frame(width: dotWidth, height: 8)
          }
        }
        .padding(.horizontal, 16)
        .frame(width: geometry.size.width, alignment: .leading)
        .clipped()
      }
      .padding(.vertical, 8)
      .contentShape(Rectangle())
      .gesture(
        DragGesture(minimumDistance: 0)
          .onChanged { value in
            isDragging = true
            // Account for 16px padding on each side
            let effectiveWidth = geometry.size.width - 32
            let adjustedX = value.location.x - 16
            let clampedX = max(0, min(adjustedX, effectiveWidth))
            let ratio = clampedX / effectiveWidth
            dragProgress = ratio * duration
          }
          .onEnded { value in
            let effectiveWidth = geometry.size.width - 32
            let adjustedX = value.location.x - 16
            let clampedX = max(0, min(adjustedX, effectiveWidth))
            let ratio = clampedX / effectiveWidth
            let seekTime = ratio * duration
            onSeek(seekTime)
            isDragging = false
          }
      )
    }
    .clipShape(RoundedRectangle(cornerRadius: 0))  // Ensure no overflow beyond bounds
  }
}

// MARK: - Preview
#Preview {
  WinampProgressSection(
    progress: .constant(45.0),
    duration: .constant(180.0),
    onSeek: { time in print("Seek to: \(time)") }
  )
  .frame(width: 275, height: 32)
}
