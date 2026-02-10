import XCTest
@testable import RiffReader

final class PitchDetectorTests: XCTestCase {
    var pitchDetector: PitchDetector!

    override func setUp() {
        super.setUp()
        pitchDetector = PitchDetector()
    }

    override func tearDown() {
        pitchDetector = nil
        super.tearDown()
    }

    // MARK: - Frequency Detection Tests

    func testDetectPitch_WithValidSineWave_ReturnsCorrectFrequency() {
        // Test A4 (440 Hz)
        let sampleRate = 44100.0
        let frequency = 440.0
        let duration = 0.1 // 100ms
        let samples = generateSineWave(frequency: frequency, sampleRate: sampleRate, duration: duration)

        let detectedPitch = pitchDetector.detectPitch(samples: samples, sampleRate: sampleRate)

        XCTAssertNotNil(detectedPitch, "Should detect pitch from valid sine wave")
        XCTAssertEqual(detectedPitch!, frequency, accuracy: 10.0, "Detected frequency should be within 10Hz of target")
    }

    func testDetectPitch_WithLowE_ReturnsCorrectFrequency() {
        // Test Low E (82.41 Hz) - lowest guitar string
        let sampleRate = 44100.0
        let frequency = 82.41
        let duration = 0.2 // Need longer duration for low frequencies
        let samples = generateSineWave(frequency: frequency, sampleRate: sampleRate, duration: duration)

        let detectedPitch = pitchDetector.detectPitch(samples: samples, sampleRate: sampleRate)

        XCTAssertNotNil(detectedPitch, "Should detect low E frequency")
        XCTAssertEqual(detectedPitch!, frequency, accuracy: 5.0, "Low E detection should be accurate")
    }

    func testDetectPitch_WithHighE_ReturnsCorrectFrequency() {
        // Test High E (329.63 Hz) - highest guitar string
        let sampleRate = 44100.0
        let frequency = 329.63
        let duration = 0.1
        let samples = generateSineWave(frequency: frequency, sampleRate: sampleRate, duration: duration)

        let detectedPitch = pitchDetector.detectPitch(samples: samples, sampleRate: sampleRate)

        XCTAssertNotNil(detectedPitch, "Should detect high E frequency")
        XCTAssertEqual(detectedPitch!, frequency, accuracy: 10.0, "High E detection should be accurate")
    }

    func testDetectPitch_WithEmptySamples_ReturnsNil() {
        let samples: [Float] = []
        let detectedPitch = pitchDetector.detectPitch(samples: samples, sampleRate: 44100.0)

        XCTAssertNil(detectedPitch, "Should return nil for empty samples")
    }

    func testDetectPitch_WithSilence_ReturnsNil() {
        let samples = [Float](repeating: 0.0, count: 4096)
        let detectedPitch = pitchDetector.detectPitch(samples: samples, sampleRate: 44100.0)

        XCTAssertNil(detectedPitch, "Should return nil for silence")
    }

    func testDetectPitch_WithFrequencyTooLow_ReturnsNil() {
        // Test 50 Hz - below guitar range (80 Hz minimum)
        let sampleRate = 44100.0
        let frequency = 50.0
        let samples = generateSineWave(frequency: frequency, sampleRate: sampleRate, duration: 0.2)

        let detectedPitch = pitchDetector.detectPitch(samples: samples, sampleRate: sampleRate)

        XCTAssertNil(detectedPitch, "Should return nil for frequency below guitar range")
    }

    func testDetectPitch_WithFrequencyTooHigh_ReturnsNil() {
        // Test 1500 Hz - above guitar range (1000 Hz maximum)
        let sampleRate = 44100.0
        let frequency = 1500.0
        let samples = generateSineWave(frequency: frequency, sampleRate: sampleRate, duration: 0.1)

        let detectedPitch = pitchDetector.detectPitch(samples: samples, sampleRate: sampleRate)

        XCTAssertNil(detectedPitch, "Should return nil for frequency above guitar range")
    }

    // MARK: - Frequency to Note Conversion Tests

    func testFrequencyToNote_A440_ReturnsA4() {
        let pitch = pitchDetector.frequencyToNote(440.0)

        XCTAssertNotNil(pitch)
        XCTAssertEqual(pitch?.noteName, .A)
        XCTAssertEqual(pitch?.octave, 4)
    }

    func testFrequencyToNote_C261_ReturnsC4() {
        let pitch = pitchDetector.frequencyToNote(261.63) // Middle C

        XCTAssertNotNil(pitch)
        XCTAssertEqual(pitch?.noteName, .C)
        XCTAssertEqual(pitch?.octave, 4)
    }

    func testFrequencyToNote_E82_ReturnsE2() {
        let pitch = pitchDetector.frequencyToNote(82.41) // Low E

        XCTAssertNotNil(pitch)
        XCTAssertEqual(pitch?.noteName, .E)
        XCTAssertEqual(pitch?.octave, 2)
    }

    // MARK: - Helper Methods

    private func generateSineWave(frequency: Double, sampleRate: Double, duration: Double) -> [Float] {
        let sampleCount = Int(sampleRate * duration)
        var samples = [Float](repeating: 0, count: sampleCount)

        for i in 0..<sampleCount {
            let time = Double(i) / sampleRate
            samples[i] = Float(sin(2.0 * .pi * frequency * time))
        }

        return samples
    }
}
