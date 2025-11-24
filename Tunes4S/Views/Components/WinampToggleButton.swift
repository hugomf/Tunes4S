import SwiftUI

struct WinampToggleButton: View {
    let icon: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(
                                colors: isActive
                                  ? [
                                    Color(hex: "4A6A82"),
                                    Color(hex: "5A7A92"),
                                  ]
                                  : [
                                    Color(hex: "2A2A2A"),
                                    Color(hex: "3A3A3A"),
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
                    .font(.system(size: 12))
                    .foregroundColor(isActive ? Color(hex: "00FF00") : Color(hex: "666666"))
            }
            .frame(width: 28, height: 16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
