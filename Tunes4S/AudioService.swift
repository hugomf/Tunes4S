//
//  AudioService.swift
//  Tunes4S
//
//  Created by Jules on 11/18/25.
//

import Foundation
import AVFoundation
import Combine
import Accelerate

public class AudioService: ObservableObject {
    private var engine = AVAudioEngine()
    private var playerNode = AVAudioPlayerNode()
    private var eqNode = AVAudioUnitEQ(numberOfBands: 10)

    private let frequencies: [Float] = [32, 64, 125, 250, 500, 1000, 2000, 4000, 8000, 16000]
    private var savedGains: [Float] = [Float](repeating: 0.0, count: 10) // Store EQ gains persistently
    private var currentSong: Song?
    private var currentFile: AVAudioFile?
    private var playbackStartTime: Date?
    private var progressUpdateTimer: Timer?
    private var currentVolume: Float = 0.8 // Store current volume
    private var currentPosition: Double = 0.0 // Track actual current position for seeking

    // FFT Analysis - Simple spectrum using audio buffer magnitude
    private let spectrumBins = 20
    private var frequencyBins: [Float] = Array(repeating: 0, count: 20)

    // Published progress values
    @Published public var currentTime: Double = 0.0
    @Published public var duration: Double = 1.0
    @Published public var isPlaying: Bool = false
    @Published public var spectrumData: [Float] = Array(repeating: 0, count: 20)

    init() {
        setupFFT()
        setupAudioEngine()
        setupAppTerminationObserver()
    }

    private func setupAppTerminationObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppTermination),
            name: NSNotification.Name("AppWillTerminate"),
            object: nil
        )
    }

    @objc private func handleAppTermination() {
        stop()
    }

    private func setupAudioEngine() {
        engine.attach(playerNode)
        engine.attach(eqNode)

        for i in 0..<eqNode.bands.count {
            eqNode.bands[i].frequency = frequencies[i]
            eqNode.bands[i].bypass = false
            eqNode.bands[i].filterType = .parametric
        }

        let format = engine.outputNode.outputFormat(forBus: 0)
        engine.connect(playerNode, to: eqNode, format: format)
        engine.connect(eqNode, to: engine.mainMixerNode, format: format)

        do {
            try engine.start()
        } catch {
            print("Error starting audio engine: \(error)")
        }
    }

    public func play(song: Song) {
        // Stop current playback if any
        stop()

        currentSong = song
        isPlaying = true

        do {
            let fileURL = URL(fileURLWithPath: song.file)
            currentFile = try AVAudioFile(forReading: fileURL)

            // Set duration
            duration = Double(currentFile!.length) / currentFile!.processingFormat.sampleRate
            currentPosition = 0.0
            currentTime = 0.0
            playbackStartTime = Date()

            // Set volume and EQ gains before starting playback
            engine.mainMixerNode.outputVolume = currentVolume
            restoreEQGains()

            // Start progress tracking timer
            startProgressTracking()

            // Start spectrum analysis
            startSpectrumAnalysis()

            // Schedule the buffer for playback
            playerNode.scheduleFile(currentFile!, at: nil, completionHandler: { [weak self] in
                // When playback completes
                DispatchQueue.main.async {
                    self?.stop()
                }
            })

            playerNode.play()
        } catch {
            print("Error playing song: \(error)")
            stop()
        }
    }

    public func stop() {
        isPlaying = false
        currentSong = nil
        currentFile = nil
        playbackStartTime = nil

        // Stop progress tracking
        progressUpdateTimer?.invalidate()
        progressUpdateTimer = nil

        // Stop spectrum analysis
        stopSpectrumAnalysis()

        playerNode.stop()

        // Reset progress and spectrum
        currentTime = 0.0
        spectrumData = Array(repeating: 0, count: 20)
    }

    public func startProgressTracking() {
        progressUpdateTimer?.invalidate()

        // Reset playback start time for current segment
        playbackStartTime = Date()

        progressUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, self.isPlaying, let startTime = self.playbackStartTime else { return }

            let elapsedInSegment = Date().timeIntervalSince(startTime)
            self.currentTime = min(self.currentPosition + elapsedInSegment, self.duration)
        }
    }

    public func seek(to time: Double) {
        guard let file = currentFile else {
            print("Cannot seek: no file loaded")
            return
        }

        // Clamp time to valid range
        let clampedTime = max(0, min(time, duration))

        print("Seeking to \(clampedTime) seconds (duration: \(duration))")

        // Stop current playback and progress tracking
        playerNode.stop()
        progressUpdateTimer?.invalidate()

        // Update position variables
        currentPosition = clampedTime
        currentTime = clampedTime

        // If we were playing, restart playback from new position
        if isPlaying {
            let sampleRate = file.processingFormat.sampleRate
            let seekSample = AVAudioFramePosition(clampedTime * sampleRate)
            let totalSamples = AVAudioFrameCount(file.length)
            let remainingSamples = totalSamples - AVAudioFrameCount(seekSample)

            // Restore volume and EQ gains before restarting playback
            engine.mainMixerNode.outputVolume = currentVolume
            restoreEQGains()

            // Schedule segment starting from seek position
            playerNode.scheduleSegment(file, startingFrame: seekSample, frameCount: remainingSamples, at: nil, completionHandler: { [weak self] in
                // When the segment finishes (end of song)
                DispatchQueue.main.async {
                    self?.stop()
                }
            })

            // Start playing from seek position
            playerNode.play()

            // Reset playback start time and restart progress tracking
            playbackStartTime = Date()
            startProgressTracking()
        }
    }

    private func restoreEQGains() {
        for i in 0..<savedGains.count {
            eqNode.bands[i].gain = savedGains[i]
        }
        print("EQ gains restored from saved state")
    }

    public func setGain(_ gain: Float, forBandAt index: Int) {
        guard index >= 0 && index < eqNode.bands.count else { return }

        // Store gain persistently
        savedGains[index] = gain

        // Debug: print gain change
        print("Setting EQ gain for band \(index) to \(gain) dB")

        // Apply the gain change in real-time - AVAudioUnitEQ supports this
        eqNode.bands[index].gain = gain

        print("Real-time EQ adjustment applied successfully")
    }

    public func setVolume(_ volume: Float) {
        currentVolume = volume

        // Apply volume to the main mixer node
        engine.mainMixerNode.outputVolume = volume
        print("Volume set to \(volume)")
    }

    // MARK: - Spectrum Analysis (Simplified audio energy-based approach)

    private func setupFFT() {
        // No FFT setup needed for the simplified approach
    }

    private func startSpectrumAnalysis() {
        let format = engine.outputNode.outputFormat(forBus: 0)

        // Install tap on the main mixer node to capture audio for analysis
        engine.mainMixerNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] (buffer, _) in
            guard let self = self, self.isPlaying else { return }
            self.analyzeAudio(buffer: buffer)
        }
    }

    private func stopSpectrumAnalysis() {
        engine.mainMixerNode.removeTap(onBus: 0)
    }

    private func analyzeAudio(buffer: AVAudioPCMBuffer) {
        guard let pcmBuffer = buffer.floatChannelData else { return }

        // Simple spectrum analysis: divide the buffer into chunks and calculate energy
        let frameCount = Int(buffer.frameLength)
        let channelData = pcmBuffer[0]

        // Create a simple spectrum by analyzing different sections
        for bin in 0..<spectrumBins {
            let segmentSize = frameCount / spectrumBins
            let startIndex = bin * segmentSize
            let endIndex = min((bin + 1) * segmentSize, frameCount)

            if endIndex > startIndex {
                // Calculate RMS (Root Mean Square) energy for this segment
                let segment = UnsafeBufferPointer(start: channelData + startIndex, count: endIndex - startIndex)

                // Calculate RMS energy (simplified spectrum analysis)
                var sumSquares: Float = 0
                for i in 0..<segment.count {
                    let sample = segment[i]
                    sumSquares += sample * sample
                }
                let rms = sqrt(sumSquares / Float(segment.count))

                // Normalize and smooth the value (reduced amplification for realistic bar heights)
                frequencyBins[bin] = min(1.0, rms * 2.0) // Amplify for visibility
            }
        }

        // Publish the spectrum data
        DispatchQueue.main.async { [weak self] in
            self?.spectrumData = self?.frequencyBins ?? []
        }
    }

    deinit {
        stop()
    }
}
