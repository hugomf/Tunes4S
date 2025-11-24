// MARK: - Winamp Main Display – Big Art + Spectrum + Volume/Balance Sliders
import SwiftUI

// MARK: - Winamp Balance Control (used in DisplaySection)
struct WinampBalanceControl: View {

    // MARK: - Configurable Dimensions (Same as volume control for consistency)
    static let sliderWidth: CGFloat = 60         // Overall slider width
    static let sliderHeight: CGFloat = 8         // Overall slider height
    static let trackHeight: CGFloat = 6         // Track background height
    static let handleWidth: CGFloat = 8          // Handle button width
    static let handleHeight: CGFloat = 10        // Handle button height

    @Binding var balance: Float
    @ObservedObject var audioService: AudioService

    var body: some View {
        HStack(spacing: 4) {
            Text("Bal")
                .font(.system(size: 7, weight: .bold))
                .foregroundColor(Color(hex: "00FF00"))

            // Compact balance slider (same as volume control)
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Narrow track background
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color(hex: "002200"))
                        .frame(height: Self.trackHeight)
                        .overlay(
                          RoundedRectangle(cornerRadius: 1)
                            .stroke(Color(hex: "0A0A0A"), lineWidth: 0.5)
                        )

                    // Balance level bar
                    Rectangle()
                        .fill(balanceBarColor)
                        .frame(width: CGFloat(balance + 1) * 0.5 * geometry.size.width, height: Self.trackHeight)

                    // Handle button
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color(hex: "EEEEEE"))
                        .frame(width: Self.handleWidth, height: Self.handleHeight)
                        .overlay(
                          Text("|||")
                            .font(.system(size: 6, weight: .bold))
                            .foregroundColor(Color(hex: "666666"))
                        )
                        .position(
                          x: CGFloat(balance + 1) * 0.5 * geometry.size.width,
                          y: Self.trackHeight / 2  // Center vertically in track
                        )
            .gesture(
              DragGesture(minimumDistance: 0)
                .onChanged { value in
                  let newX = max(0, min(value.location.x, geometry.size.width))
                  let newBalance = Float((newX / geometry.size.width) * 2.0 - 1.0)

                  // Update binding which triggers didSet
                  balance = max(-1.0, min(1.0, newBalance))

                  // Also directly update audioService to ensure it's applied
                  audioService.balance = balance
                }
            )
                }
            }
            .frame(width: Self.sliderWidth, height: Self.sliderHeight)

            Text(balance < 0 ? "L\(String(format: "%.1f", abs(balance)))" : "R\(String(format: "%.1f", balance))")
                .font(.system(size: 6, weight: .bold))
                .foregroundColor(Color(hex: "00FF00"))
        }
    }

    private var balanceBarColor: Color {
        let absBalance = abs(balance)
        if balance < 0 {
            // Left channel dominant - green (like volume control)
            return Color(hex: "00FF00")
        } else if balance > 0 {
            // Right channel dominant - red (like volume end)
            return Color(hex: "FFFF00")
        } else {
            // Center - neutral green (full stereo)
            return Color(hex: "00FF00")
        }
    }
}

struct WinampDisplaySection: View {
    @Binding var currentSong: Song?
    @Binding var isPlaying: Bool
    @Binding var progress: Double
    @Binding var duration: Double
    @Binding var volume: Float
    @ObservedObject var audioService: AudioService
    @StateObject private var spectrumModel = SpectrumViewModel()
    @State private var showElapsedTime = true

    var body: some View {
        VStack(spacing: 0) {
            // ── Top Bar: 128 kbps · 44 kHz · STEREO ──
            HStack(spacing: 8) {
                WinampLEDText(text: "128", width: 36, color: .green)
                Text("kbps").font(.system(size: 8)).foregroundColor(.green)
                WinampLEDText(text: "44", width: 28, color: .green)
                Text("kHz").font(.system(size: 8)).foregroundColor(.green)
                Spacer()

                Text(audioService.isStereo ? "STEREO" : "MONO")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(
                        Rectangle()
                            .fill(Color(hex: "00FF00"))
                            .glow(Color(hex: "00FF00"), radius: 6)
                    )
            }
            .padding(.horizontal, 12)
            .padding(.top, 6)
            .padding(.bottom, 4)

            // ── Song Info + Timer ──
            HStack {
                ScrollingText(
                    text: currentSong.map { "\($0.artist ?? "") - \($0.title ?? "") - \($0.album ?? "")" }
                          ?? "Winamp 2.95 – Really Rare",
                    isPlaying: isPlaying
                )
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(Color(hex: "00FF00"))

                Spacer()

                Text(showElapsedTime ? formatTime(progress) : "-\(formatTime(duration - progress))")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(hex: "00FF00"))
                    .padding(.horizontal, 10)
                    .onTapGesture { showElapsedTime.toggle() }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 6)

            // ── Bottom Row: Art | Spectrum | Volume + Balance ──
            HStack(spacing: 6) {
                // Big Album Art (68×68)
                ZStack {
                    Rectangle().fill(Color.black).frame(width: 68, height: 68)
                    if let imgData = currentSong?.songImage,
                       let ns = NSImage(data: imgData) {
                        Image(nsImage: ns)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 68, height: 68)
                            .clipped()
                    } else {
                        Image(systemName: "music.note")
                            .font(.system(size: 32))
                            .foregroundColor(Color(hex: "00FF00"))
                    }
                }
                .overlay(Rectangle().stroke(Color(hex: "222222"), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 2))

                // LED Spectrum – super close to artwork
                WinampLEDSpectrumAnalyzer(
                    isPlaying: $isPlaying,
                    spectrumData: spectrumModel.spectrumData,
                    peakHeights: spectrumModel.peakHeights,
                    compact: false
                )
                .onReceive(audioService.$spectrumData) { spectrumModel.updateSpectrum($0) }

                // Volume & Balance Sliders (using extracted components, identical to ControlPanel)
                VStack(spacing: 6) {
                    // Volume Control (matches ControlPanel exactly)
                    WinampVolumeControl(volume: Binding(
                        get: { self.audioService.volume },
                        set: { self.audioService.volume = $0 }
                    ), audioService: audioService)

                    // Balance Control (identical component/usage pattern)
                    WinampBalanceControl(balance: Binding(
                        get: { self.audioService.balance },
                        set: { self.audioService.balance = $0 }
                    ), audioService: audioService)
                }
                .padding(.trailing, 6)
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 8)
        }
        .frame(height: 124)
        .background(Color.black)
        .overlay(Rectangle().stroke(Color(hex: "00FF00"), lineWidth: 1).opacity(0.6))
        .overlay(Rectangle().stroke(Color(hex: "003300"), lineWidth: 1).padding(1))
    }

    private func formatTime(_ time: Double) -> String {
        let m = Int(time) / 60
        let s = Int(time) % 60
        return String(format: "%d:%02d", m, s)
    }

    private func volumeBarColor(_ volume: Float) -> Color {
        if volume < 0.5 {
            return Color(hex: "00FF00")
        } else if volume < 0.75 {
            let transitionProgress = (volume - 0.5) / 0.25
            let green = UInt8(255 - transitionProgress * 0)
            let red = UInt8(transitionProgress * 255)
            let blue = UInt8(transitionProgress * 0)
            return Color(red: Double(red) / 255, green: Double(green) / 255, blue: Double(blue) / 255)
        } else if volume < 0.8 {
            return Color(hex: "FFFF00")
        } else if volume < 0.95 {
            let transitionProgress = (volume - 0.8) / 0.15
            let green = UInt8(255 - transitionProgress * 255)
            let red = UInt8(255)
            let blue = UInt8(transitionProgress * 0)
            return Color(red: Double(red) / 255, green: Double(green) / 255, blue: Double(blue) / 255)
        } else {
            return Color(hex: "FF0000")
        }
    }

    private var balanceBarColor: Color {
        let absBalance = abs(audioService.balance)
        if audioService.balance < 0 {
            // Left channel dominant - blue/green
            return Color(hex: "0080FF")
        } else if audioService.balance > 0 {
            // Right channel dominant - red/yellow
            return Color(hex: "FF8000")
        } else {
            // Center - neutral green
            return Color(hex: "00FF00")
        }
    }
}

// Optional: Add this glow modifier for extra retro feel
extension View {
    func glow(_ color: Color, radius: CGFloat) -> some View {
        self.shadow(color: color.opacity(0.8), radius: radius / 3)
            .shadow(color: color.opacity(0.5), radius: radius / 2)
            .shadow(color: color.opacity(0.3), radius: radius)
    }
}
