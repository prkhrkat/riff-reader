#!/usr/bin/env swift

import Foundation
import Accelerate

// YIN Algorithm PitchDetector for testing
class TestPitchDetector {
    private let minFrequency: Double = 80.0
    private let maxFrequency: Double = 1000.0
    private let threshold: Float = 0.1

    func detectPitch(samples: [Float], sampleRate: Double) -> Double? {
        guard samples.count > 100 else { return nil }

        let count = samples.count
        let minLag = Int(sampleRate / maxFrequency)
        let maxLag = min(Int(sampleRate / minFrequency), count / 2)

        guard maxLag > minLag else { return nil }

        // Calculate difference function
        var differenceFunction = [Float](repeating: 0, count: maxLag)

        for lag in 0..<maxLag {
            var sum: Float = 0.0
            let effectiveCount = min(count - lag, 1000)

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
                if lag + 1 < maxLag && cmndf[lag] < cmndf[lag + 1] {
                    let frequency = parabolicInterpolation(lag: lag, cmndf: cmndf, sampleRate: sampleRate)
                    if frequency >= minFrequency && frequency <= maxFrequency {
                        return frequency
                    }
                }
            }
        }

        // Find global minimum
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

        if frequency >= minFrequency && frequency <= maxFrequency {
            return frequency
        }

        return nil
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
}

// Test helper
func generateSineWave(frequency: Double, sampleRate: Double, duration: Double) -> [Float] {
    let sampleCount = Int(sampleRate * duration)
    var samples = [Float](repeating: 0, count: sampleCount)

    for i in 0..<sampleCount {
        let time = Double(i) / sampleRate
        samples[i] = Float(sin(2.0 * .pi * frequency * time))
    }

    return samples
}

// Run tests
print("🧪 Testing Pitch Detector...")
print("============================")

let detector = TestPitchDetector()
var passedTests = 0
var failedTests = 0

// Test 1: A440
print("\n Test 1: Detecting A440 (440 Hz)...")
let samples440 = generateSineWave(frequency: 440.0, sampleRate: 44100.0, duration: 0.1)
if let detected = detector.detectPitch(samples: samples440, sampleRate: 44100.0) {
    let error = abs(detected - 440.0)
    if error < 10.0 {
        print("✅ PASS: Detected \(String(format: "%.1f", detected)) Hz (error: \(String(format: "%.1f", error)) Hz)")
        passedTests += 1
    } else {
        print("❌ FAIL: Detected \(String(format: "%.1f", detected)) Hz (error too large: \(String(format: "%.1f", error)) Hz)")
        failedTests += 1
    }
} else {
    print("❌ FAIL: No pitch detected")
    failedTests += 1
}

// Test 2: Low E (82.41 Hz)
print("\n📝 Test 2: Detecting Low E (82.41 Hz)...")
let samplesLowE = generateSineWave(frequency: 82.41, sampleRate: 44100.0, duration: 0.2)
if let detected = detector.detectPitch(samples: samplesLowE, sampleRate: 44100.0) {
    let error = abs(detected - 82.41)
    if error < 5.0 {
        print("✅ PASS: Detected \(String(format: "%.2f", detected)) Hz (error: \(String(format: "%.2f", error)) Hz)")
        passedTests += 1
    } else {
        print("❌ FAIL: Detected \(String(format: "%.2f", detected)) Hz (error too large: \(String(format: "%.2f", error)) Hz)")
        failedTests += 1
    }
} else {
    print("❌ FAIL: No pitch detected")
    failedTests += 1
}

// Test 3: High E (329.63 Hz)
print("\n📝 Test 3: Detecting High E (329.63 Hz)...")
let samplesHighE = generateSineWave(frequency: 329.63, sampleRate: 44100.0, duration: 0.1)
if let detected = detector.detectPitch(samples: samplesHighE, sampleRate: 44100.0) {
    let error = abs(detected - 329.63)
    if error < 10.0 {
        print("✅ PASS: Detected \(String(format: "%.2f", detected)) Hz (error: \(String(format: "%.2f", error)) Hz)")
        passedTests += 1
    } else {
        print("❌ FAIL: Detected \(String(format: "%.2f", detected)) Hz (error too large: \(String(format: "%.2f", error)) Hz)")
        failedTests += 1
    }
} else {
    print("❌ FAIL: No pitch detected")
    failedTests += 1
}

// Test 4: Silence
print("\n📝 Test 4: Silence (should return nil)...")
let silentSamples = [Float](repeating: 0.0, count: 4096)
if detector.detectPitch(samples: silentSamples, sampleRate: 44100.0) == nil {
    print("✅ PASS: Correctly returned nil for silence")
    passedTests += 1
} else {
    print("❌ FAIL: Should not detect pitch in silence")
    failedTests += 1
}

// Summary
print("\n============================")
print("📊 Test Results:")
print("  Passed: \(passedTests)")
print("  Failed: \(failedTests)")
print("============================")

if failedTests == 0 {
    print("✅ All tests passed!")
    exit(0)
} else {
    print("❌ Some tests failed!")
    exit(1)
}
