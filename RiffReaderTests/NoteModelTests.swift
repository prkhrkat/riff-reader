import XCTest
@testable import RiffReader

final class NoteModelTests: XCTestCase {

    // MARK: - Pitch Tests

    func testPitch_MIDINoteConversion_A440() {
        let pitch = Pitch(noteName: .A, octave: 4)
        XCTAssertEqual(pitch.midiNote, 69, "A4 should be MIDI note 69")
    }

    func testPitch_FrequencyConversion_A440() {
        let pitch = Pitch(noteName: .A, octave: 4)
        XCTAssertEqual(pitch.frequency, 440.0, accuracy: 0.01, "A4 should be 440 Hz")
    }

    func testPitch_FrequencyConversion_MiddleC() {
        let pitch = Pitch(noteName: .C, octave: 4)
        XCTAssertEqual(pitch.frequency, 261.63, accuracy: 0.1, "C4 should be ~261.63 Hz")
    }

    func testPitch_FrequencyConversion_LowE() {
        let pitch = Pitch(noteName: .E, octave: 2)
        XCTAssertEqual(pitch.frequency, 82.41, accuracy: 0.1, "E2 should be ~82.41 Hz")
    }

    // MARK: - Guitar String Tests

    func testGuitarString_OpenStringFrequencies() {
        XCTAssertEqual(GuitarString.first.openStringFrequency, 329.63, accuracy: 0.01, "High E string")
        XCTAssertEqual(GuitarString.second.openStringFrequency, 246.94, accuracy: 0.01, "B string")
        XCTAssertEqual(GuitarString.third.openStringFrequency, 196.00, accuracy: 0.01, "G string")
        XCTAssertEqual(GuitarString.fourth.openStringFrequency, 146.83, accuracy: 0.01, "D string")
        XCTAssertEqual(GuitarString.fifth.openStringFrequency, 110.00, accuracy: 0.01, "A string")
        XCTAssertEqual(GuitarString.sixth.openStringFrequency, 82.41, accuracy: 0.01, "Low E string")
    }

    func testGuitarString_Names() {
        XCTAssertEqual(GuitarString.first.name, "E")
        XCTAssertEqual(GuitarString.second.name, "B")
        XCTAssertEqual(GuitarString.third.name, "G")
        XCTAssertEqual(GuitarString.fourth.name, "D")
        XCTAssertEqual(GuitarString.fifth.name, "A")
        XCTAssertEqual(GuitarString.sixth.name, "E")
    }

    // MARK: - Note Creation Tests

    func testNote_Creation() {
        let pitch = Pitch(noteName: .A, octave: 4)
        let note = Note(pitch: pitch, frequency: 440.0, startTime: 0.0, duration: 1.0, velocity: 100)

        XCTAssertEqual(note.pitch.noteName, .A)
        XCTAssertEqual(note.pitch.octave, 4)
        XCTAssertEqual(note.frequency, 440.0)
        XCTAssertEqual(note.startTime, 0.0)
        XCTAssertEqual(note.duration, 1.0)
        XCTAssertEqual(note.velocity, 100)
    }

    func testGuitarNote_Creation() {
        let pitch = Pitch(noteName: .E, octave: 2)
        let note = Note(pitch: pitch, frequency: 82.41, startTime: 0.0, duration: 1.0)
        let guitarNote = GuitarNote(note: note, string: .sixth, fret: 0)

        XCTAssertEqual(guitarNote.string, .sixth)
        XCTAssertEqual(guitarNote.fret, 0)
        XCTAssertEqual(guitarNote.note.frequency, 82.41)
    }

    // MARK: - NoteName Tests

    func testNoteName_ChromaticIndices() {
        XCTAssertEqual(NoteName.C.chromaticIndex, 0)
        XCTAssertEqual(NoteName.Cs.chromaticIndex, 1)
        XCTAssertEqual(NoteName.D.chromaticIndex, 2)
        XCTAssertEqual(NoteName.Ds.chromaticIndex, 3)
        XCTAssertEqual(NoteName.E.chromaticIndex, 4)
        XCTAssertEqual(NoteName.F.chromaticIndex, 5)
        XCTAssertEqual(NoteName.Fs.chromaticIndex, 6)
        XCTAssertEqual(NoteName.G.chromaticIndex, 7)
        XCTAssertEqual(NoteName.Gs.chromaticIndex, 8)
        XCTAssertEqual(NoteName.A.chromaticIndex, 9)
        XCTAssertEqual(NoteName.As.chromaticIndex, 10)
        XCTAssertEqual(NoteName.B.chromaticIndex, 11)
    }

    func testNoteName_DisplayNames() {
        XCTAssertEqual(NoteName.C.displayName, "C")
        XCTAssertEqual(NoteName.Cs.displayName, "C#")
        XCTAssertEqual(NoteName.Fs.displayName, "F#")
    }
}
