import SwiftUI
import AppKit

struct WinampTitleBar: View {
    @Binding var showPlaylist: Bool
    @Binding var showEqualizer: Bool
    @State private var dragOffset = CGSize.zero

    var body: some View {
        HStack(spacing: 0) {
            // Close Button
            Button(action: {
                NSApp.terminate(nil)
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(Color(hex: "00FF00"))
                    .frame(width: 14, height: 10)
                    .background(Color(hex: "333333"))
                    .clipShape(RoundedRectangle(cornerRadius: 1))
            }
            .buttonStyle(BorderlessButtonStyle())
            .padding(.leading, 4)

            // Winamp Logo/Text
            Text("Winamp")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(hex: "00FF00"))
                .padding(.leading, 4)

            Spacer()

            // Window Control Buttons
            HStack(spacing: 2) {
                Button(action: { showPlaylist.toggle() }) {
                    Text("PL")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 18, height: 12)
                        .background(Color(hex: "2A2A2A"))
                        .overlay(Rectangle().stroke(Color(hex: "666666"), lineWidth: 1))
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: { showEqualizer.toggle() }) {
                    Text("EQ")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 18, height: 12)
                        .background(Color(hex: "2A2A2A"))
                        .overlay(Rectangle().stroke(Color(hex: "666666"), lineWidth: 1))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.trailing, 8)
        }
        .frame(height: 14)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "1E3A52"), Color(hex: "2B4A62")]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(
            Rectangle()
                .stroke(Color.black.opacity(0.5), lineWidth: 1)
        )
        .gesture(
            DragGesture()
                .onChanged { value in
                    if let window = NSApplication.shared.windows.first {
                        dragOffset = value.translation
                        window.setFrameOrigin(
                            NSPoint(
                                x: window.frame.origin.x + dragOffset.width,
                                y: window.frame.origin.y - dragOffset.height
                            )
                        )
                    }
                }
        )
    }
}
