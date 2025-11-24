import SwiftUI

struct WinampButton: View {
    let icon: String
    let size: CGFloat
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            ZStack {
                // Button background with more realistic gradient
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(
                                colors: isPressed
                                  ? [
                                    Color(hex: "4A6A82"),
                                    Color(hex: "5A7A92"),
                                  ]
                                  : [
                                    Color(hex: "5A7A92"),
                                    Color(hex: "4A6A82"),
                                  ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(Color(hex: "2A4A62"), lineWidth: 1)
                    )

                Image(systemName: icon)
                    .font(.system(size: size * 0.4))
                    .foregroundColor(Color(hex: "00FF00"))
            }
            .frame(width: size, height: size)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}
