import Foundation
import Accelerate

/// Detects pitch from audio samples using autocorrelation and FFT
class PitchDetector {
    private let minFrequency: Double = 80.0  // Low E on guitar
    private let maxFrequency: Double = 1000.0 // High notes on guitar

    func detectPitch(samples: [Float], sampleRate: Double) -> Double? {
        guard samples.count > 0 else { return nil }

        // Use autocorrelation for pitch detection
        let pitch = autocorrelation(samples: samples, sampleRate: sampleRate)

        // Validate pitch is in guitar range
        if let pitch = pitch, pitch >= minFrequency && pitch <= maxFrequency {
            return pitch
        }

        return nil
    }

    private func autocorrelation(samples: [Float], sampleRate: Double) -> Double? {
        let count = samples.count
        var correlations = [Float](repeating: 0, count: count)

        // Calculate autocorrelation
        vDSP_conv(samples, 1, samples, 1, &correlations, 1, vDSP_Length(count), vDSP_Length(count))

        // Find the first peak after the zero lag
        let minLag = Int(sampleRate / maxFrequency)
        let maxLag = Int(sampleRate / minFrequency)

        guard maxLag < count else { return nil }

        var maxCorrelation: Float = 0
        var maxLagIndex = 0

        for i in minLag..<maxLag {
            if correlations[i] > maxCorrelation {
                maxCorrelation = correlations[i]
                maxLagIndex = i
            }
        }

        guard maxLagIndex > 0 else { return nil }

        let frequency = sampleRate / Double(maxLagIndex)
        return frequency
    }

    /// Convert frequency to nearest note
    func frequencyToNote(_ frequency: Double) -> Pitch? {
        // A4 = 440 Hz = MIDI note 69
        let midiNote = 69 + 12 * log2(frequency / 440.0)
        let roundedMidi = Int(round(midiNote))

        let octave = (roundedMidi / 12) - 1
        let noteIndex = roundedMidi % 12

        guard let noteName = NoteName.allCases.first(where: { $0.chromaticIndex == noteIndex }) else {
            return nil
        }

        return Pitch(noteName: noteName, octave: octave)
    }
}
