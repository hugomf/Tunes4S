import SwiftUI

struct WinampBackground: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: Color(hex: "3C5068"), location: 0),
                .init(color: Color(hex: "5A768E"), location: 0.5),
                .init(color: Color(hex: "3C5068"), location: 1),
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
