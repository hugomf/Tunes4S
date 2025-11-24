import SwiftUI

struct WinampLEDText: View {
    let text: String
    let width: CGFloat
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundColor(color == .green ? Color(hex: "00FF00") : Color(hex: "FF6600"))
            .frame(width: width, height: 12)
            .background(Color.black)
            .overlay(Rectangle().stroke(Color(hex: "333333"), lineWidth: 1))
    }
}
