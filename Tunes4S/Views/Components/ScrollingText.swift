import SwiftUI

struct ScrollingText: View {
    let text: String
    let isPlaying: Bool
    @State private var offset: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            Text(text + "  ***  ")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(Color(hex: "00FF00"))
                .offset(x: offset)
                .onAppear {
                    if isPlaying {
                        withAnimation(Animation.linear(duration: 10).repeatForever(autoreverses: false)) {
                            offset = -200
                        }
                    }
                }
                .onChange(of: isPlaying) { playing in
                    if playing {
                        offset = geometry.size.width
                        withAnimation(Animation.linear(duration: 10).repeatForever(autoreverses: false)) {
                            offset = -200
                        }
                    } else {
                        offset = 0
                    }
                }
        }
        .frame(height: 16)
        .background(Color.black)
        .clipped()
    }
}
