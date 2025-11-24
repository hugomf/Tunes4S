//
//  WinampVolumeControl.swift
//  Tunes4S
//
//  Created by Hugo Martinez Fernandez
//

import SwiftUI

struct WinampVolumeControl: View {

  // MARK: - Configurable Dimensions
  static let sliderWidth: CGFloat = 60         // Overall slider width
  static let sliderHeight: CGFloat = 8         // Overall slider height
  static let trackHeight: CGFloat = 6         // Track background height
  static let handleWidth: CGFloat = 8          // Handle button width
  static let handleHeight: CGFloat = 10        // Handle button height

  @Binding var volume: Float
  @ObservedObject var audioService: AudioService

  var body: some View {
    HStack(spacing: 4) {
      Text("VOL")
        .font(.system(size: 7, weight: .bold))
        .foregroundColor(Color(hex: "00FF00"))

      // Compact volume slider
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

          // Volume level bar
          Rectangle()
            .fill(volumeBarColor)
            .frame(width: CGFloat(volume) * geometry.size.width, height: Self.trackHeight)

          // Handle button (configurable size)
          RoundedRectangle(cornerRadius: 1)
            .fill(Color(hex: "EEEEEE"))
            .frame(width: Self.handleWidth, height: Self.handleHeight)
            .overlay(
              Text("|||")
                .font(.system(size: 6, weight: .bold))
                .foregroundColor(Color(hex: "666666"))
            )
            .position(
              x: CGFloat(volume) * geometry.size.width,
              y: Self.trackHeight / 2  // Center vertically in track
            )
            .gesture(
              DragGesture()
                .onChanged { value in
                  let newX = max(0, min(value.location.x, geometry.size.width))
                  volume = Float(newX / geometry.size.width)
                }
            )
        }
      }
      .frame(width: Self.sliderWidth, height: Self.sliderHeight)

      Text("\(Int(volume * 100))")
        .font(.system(size: 6, weight: .bold))
        .foregroundColor(Color(hex: "00FF00"))
    }
  }

  private var volumeBarColor: Color {
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
}

// MARK: - Preview
#Preview("Winamp Volume Control") {
  WinampVolumeControl(
    volume: .constant(0.6),
    audioService: AudioService()
  )
  .frame(width: 200)
  .padding()
  .background(Color(hex: "2A2A2A"))
}

