//
//  AudioService.swift
//  Tunes4S
//
//  Created by Jules on 11/18/25.
//

import Foundation
import AVFoundation
import Combine

class AudioService: ObservableObject {
    private var engine = AVAudioEngine()
    private var playerNode = AVAudioPlayerNode()
    private var eqNode: AVAudioNode? // optional to handle possible API changes

    private let frequencies: [Float] = [32, 64, 125, 250, 500, 1000, 2000, 4000, 8000, 16000]

    init() {
        setupAudioEngine()
    }

    private func setupAudioEngine() {
        eqNode = AVAudioUnitEQ(numberOfBands: 10)
        guard let eq = eqNode as? AVAudioUnitEQ else { return }
        engine.attach(playerNode)
        engine.attach(eq)

        for i in 0..<eq.bands.count {
            eq.bands[i].frequency = frequencies[i]
            eq.bands[i].bypass = false
            eq.bands[i].filterType = .parametric
        }

        engine.connect(playerNode, to: eq, format: nil)
        engine.connect(eq, to: engine.mainMixerNode, format: nil)

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
        if let eq = eqNode as? AVAudioUnitEQ, index < eq.bands.count {
            eq.bands[index].gain = gain
        }
    }
}
