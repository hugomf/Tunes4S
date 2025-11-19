//
//  AudioService.swift
//  Tunes4S
//
//  Created by Jules on 11/18/25.
//

import Foundation
import AVFoundation

class AudioService: ObservableObject {
    private var engine = AVAudioEngine()
    private var playerNode = AVAudioPlayerNode()
    private var eqNode = AVAudioUnitEQ(numberOfBands: 10)

    private let frequencies: [Float] = [32, 64, 125, 250, 500, 1000, 2000, 4000, 8000, 16000]

    init() {
        setupAudioEngine()
    }

    private func setupAudioEngine() {
        engine.attach(playerNode)
        engine.attach(eqNode)

        for i in 0..<eqNode.bands.count {
            eqNode.bands[i].frequency = frequencies[i]
            eqNode.bands[i].bypass = false
            eqNode.bands[i].filterType = .parametric
        }

        engine.connect(playerNode, to: eqNode, format: nil)
        engine.connect(eqNode, to: engine.mainMixerNode, format: nil)

        do {
            try engine.start()
        } catch {
            print("Error starting audio engine: \(error)")
        }
    }

    func play(song: Song) {
        let fileURL = URL(fileURLWithPath: song.file)

        do {
            let audioFile = try AVAudioFile(forReading: fileURL)
            playerNode.scheduleFile(audioFile, at: nil)
            playerNode.play()
        } catch {
            print("Error playing song: \(error)")
        }
    }

    func stop() {
        playerNode.stop()
    }

    func setGain(_ gain: Float, forBandAt index: Int) {
        eqNode.bands[index].gain = gain
    }
}
