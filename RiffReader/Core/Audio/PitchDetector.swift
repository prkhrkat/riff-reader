import Foundation
import Accelerate

/// Detects pitch from audio samples using autocorrelation
class PitchDetector {
    private let minFrequency: Double = 80.0  // Low E on guitar
    private let maxFrequency: Double = 1000.0 // High notes on guitar
    private let threshold: Float = 0.1 // Minimum correlation threshold

    func detectPitch(samples: [Float], sampleRate: Double) -> Double? {
        guard samples.count > 0 else { return nil }

        // Use autocorrelation for pitch detection
        let pitch = autocorrelationYIN(samples: samples, sampleRate: sampleRate)

        // Validate pitch is in guitar range
        if let pitch = pitch, pitch >= minFrequency && pitch <= maxFrequency {
            return pitch
        }

        return nil
    }

    /// YIN algorithm for improved pitch detection
    private func autocorrelationYIN(samples: [Float], sampleRate: Double) -> Double? {
        let count = samples.count
        guard count > 100 else { return nil }

        let minLag = Int(sampleRate / maxFrequency)
        let maxLag = min(Int(sampleRate / minFrequency), count / 2)

        guard maxLag > minLag else { return nil }

        // Calculate difference function
        var differenceFunction = [Float](repeating: 0, count: maxLag)

        for lag in 0..<maxLag {
            var sum: Float = 0.0
            let effectiveCount = min(count - lag, 1000) // Limit for performance

            for i in 0..<effectiveCount {
                let diff = samples[i] - samples[i + lag]
                sum += diff * diff
            }

            differenceFunction[lag] = sum
        }

        // Calculate cumulative mean normalized difference function
        var cmndf = [Float](repeating: 1.0, count: maxLag)
        cmndf[0] = 1.0
        var runningSum: Float = 0.0

        for lag in 1..<maxLag {
            runningSum += differenceFunction[lag]
            if runningSum > 0 {
                cmndf[lag] = differenceFunction[lag] / (runningSum / Float(lag))
            }
        }

        // Find first minimum below threshold
        for lag in minLag..<maxLag {
            if cmndf[lag] < threshold {
                // Look for local minimum
                if lag + 1 < maxLag && cmndf[lag] < cmndf[lag + 1] {
                    // Parabolic interpolation for better accuracy
                    let frequency = parabolicInterpolation(lag: lag, cmndf: cmndf, sampleRate: sampleRate)
                    return frequency
                }
            }
        }

        // If no clear minimum, find global minimum
        var minValue: Float = Float.infinity
        var bestMinLag = 0

        for lag in minLag..<maxLag {
            if cmndf[lag] < minValue {
                minValue = cmndf[lag]
                bestMinLag = lag
            }
        }

        guard bestMinLag > 0, minValue < 1.0 else { return nil }

        let frequency = sampleRate / Double(bestMinLag)
        return frequency
    }

    private func parabolicInterpolation(lag: Int, cmndf: [Float], sampleRate: Double) -> Double {
        guard lag > 0, lag < cmndf.count - 1 else {
            return sampleRate / Double(lag)
        }

        let alpha = cmndf[lag - 1]
        let beta = cmndf[lag]
        let gamma = cmndf[lag + 1]

        let peak = 0.5 * (alpha - gamma) / (alpha - 2 * beta + gamma)
        let interpolatedLag = Double(lag) + Double(peak)

        return sampleRate / interpolatedLag
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
