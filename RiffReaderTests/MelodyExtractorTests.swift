import XCTest
@testable import RiffReader

final class MelodyExtractorTests: XCTestCase {
    var melodyExtractor: MelodyExtractor!

    override func setUp() {
        super.setUp()
        melodyExtractor = MelodyExtractor()
    }

    override func tearDown() {
        melodyExtractor = nil
        super.tearDown()
    }

    // MARK: - Melody Extraction Tests

    func testExtractMelody_WithMultipleNotes_ReturnsHighestInEachWindow() {
        let notes = [
            createNote(frequency: 200.0, startTime: 0.0),
            createNote(frequency: 300.0, startTime: 0.05),
            createNote(frequency: 400.0, startTime: 0.15),
            createNote(frequency: 350.0, startTime: 0.20),
        ]

        let melody = melodyExtractor.extractMelody(from: notes)

        XCTAssertGreaterThan(melody.count, 0, "Should extract melody notes")
        // The highest notes in each window should be selected
        XCTAssertTrue(melody.contains(where: { $0.frequency == 300.0 }), "Should include highest note from first window")
        XCTAssertTrue(melody.contains(where: { $0.frequency == 400.0 }), "Should include highest note from second window")
    }

    func testExtractMelody_WithEmptyArray_ReturnsEmpty() {
        let notes: [Note] = []
        let melody = melodyExtractor.extractMelody(from: notes)

        XCTAssertEqual(melody.count, 0, "Should return empty array for empty input")
    }

    func testExtractMelody_WithSingleNote_ReturnsSingleNote() {
        let notes = [createNote(frequency: 440.0, startTime: 0.0)]
        let melody = melodyExtractor.extractMelody(from: notes)

        XCTAssertEqual(melody.count, 1, "Should return single note")
        XCTAssertEqual(melody.first?.frequency, 440.0)
    }

    // MARK: - Guitar Mapping Tests

    func testMapToGuitar_LowE_MapsToSixthString() {
        let pitch = Pitch(noteName: .E, octave: 2)
        let note = Note(pitch: pitch, frequency: 82.41, startTime: 0.0, duration: 1.0)
        let guitarNotes = melodyExtractor.mapToGuitar(notes: [note])

        XCTAssertEqual(guitarNotes.count, 1)
        XCTAssertEqual(guitarNotes.first?.string, .sixth)
        XCTAssertEqual(guitarNotes.first?.fret, 0)
    }

    func testMapToGuitar_HighE_MapsToFirstString() {
        let pitch = Pitch(noteName: .E, octave: 4)
        let note = Note(pitch: pitch, frequency: 329.63, startTime: 0.0, duration: 1.0)
        let guitarNotes = melodyExtractor.mapToGuitar(notes: [note])

        XCTAssertEqual(guitarNotes.count, 1)
        XCTAssertEqual(guitarNotes.first?.string, .first)
        XCTAssertEqual(guitarNotes.first?.fret, 0)
    }

    func testMapToGuitar_A440_MapsCorrectly() {
        let pitch = Pitch(noteName: .A, octave: 4)
        let note = Note(pitch: pitch, frequency: 440.0, startTime: 0.0, duration: 1.0)
        let guitarNotes = melodyExtractor.mapToGuitar(notes: [note])

        XCTAssertEqual(guitarNotes.count, 1)
        XCTAssertNotNil(guitarNotes.first)
        // A440 can be played on multiple strings, just verify it maps somewhere
        XCTAssertTrue((0...22).contains(guitarNotes.first!.fret), "Fret should be in valid range")
    }

    func testMapToGuitar_MultipleNotes_MapsAll() {
        let notes = [
            createNote(frequency: 82.41, startTime: 0.0),   // Low E
            createNote(frequency: 110.0, startTime: 0.5),    // A
            createNote(frequency: 146.83, startTime: 1.0),   // D
        ]

        let guitarNotes = melodyExtractor.mapToGuitar(notes: notes)

        XCTAssertEqual(guitarNotes.count, 3, "Should map all notes")
    }

    func testMapToGuitar_WithEmptyArray_ReturnsEmpty() {
        let notes: [Note] = []
        let guitarNotes = melodyExtractor.mapToGuitar(notes: notes)

        XCTAssertEqual(guitarNotes.count, 0)
    }

    // MARK: - Helper Methods

    private func createNote(frequency: Double, startTime: TimeInterval) -> Note {
        let pitch = Pitch(noteName: .A, octave: 4)
        return Note(pitch: pitch, frequency: frequency, startTime: startTime, duration: 0.1)
    }
}
