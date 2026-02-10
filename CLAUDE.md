# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Riff Reader is a native iOS app that listens to music through the microphone, analyzes guitar melodies in real-time, and displays notes in a Guitar Hero-style game interface. Users can learn guitar by playing along with visualized notes.

**Tech Stack:**
- SwiftUI for UI
- AVFoundation for audio capture
- Accelerate framework for DSP (pitch detection via autocorrelation)
- Hybrid analysis: on-device pitch detection + optional cloud-based melody extraction

## Architecture

### Core Components

**Audio Pipeline (Core/Audio/):**
- `AudioEngine`: Main audio manager, handles AVAudioEngine setup, microphone input tap, publishes detected pitches
- `PitchDetector`: DSP algorithms for pitch detection using autocorrelation and FFT via Accelerate framework
- Audio flows: Microphone → AVAudioEngine → Buffer processing → Pitch detection → Note conversion

**Analysis Pipeline (Core/Analysis/):**
- `MelodyExtractor`: Separates melody from polyphonic audio, maps detected notes to guitar fretboard positions
- Algorithm: Time-window based highest-note selection (can be enhanced with ML/cloud API)
- Outputs: Array of `GuitarNote` with string/fret positions optimized for playability

**Data Models (Core/Models/):**
- `Note`: Musical note with pitch, frequency, timing, velocity
- `GuitarNote`: Note mapped to specific guitar string (1-6) and fret position
- `Pitch`: Note name + octave, with frequency/MIDI conversions
- `GuitarString`: Enum for 6 strings with open string frequencies (E2=82.41Hz to E4=329.63Hz)

**Feature Modules:**
- `Recording`: UI for capturing audio, real-time pitch display, waveform visualization
- `Gameplay`: Guitar Hero-style game view with 6 strings, scrolling notes from right to left, hit zone on left side
- `Settings`: Audio config, gameplay difficulty, cloud analysis toggle

### App Flow

1. **Recording Phase**: User taps mic → AudioEngine starts capturing → Real-time pitch detection → Notes accumulated
2. **Analysis Phase**: Recorded notes → MelodyExtractor → Guitar positions calculated → Gameplay sequence prepared
3. **Gameplay Phase**: Notes scroll from right to left → User plays along → Audio monitoring verifies correct notes (TODO)

## Development Commands

This is a standard Xcode project. No package manager files are included yet.

**Build & Run:**
```bash
# Open in Xcode
open RiffReader.xcodeproj  # (after project is created)

# Or use xcodebuild
xcodebuild -scheme RiffReader -destination 'platform=iOS Simulator,name=iPhone 15' build
```

**Testing:**
```bash
xcodebuild test -scheme RiffReader -destination 'platform=iOS Simulator,name=iPhone 15'
```

**Create Xcode Project:**
The project structure exists but needs Xcode project file creation:
1. Open Xcode → Create new project → iOS App
2. Name: "RiffReader", SwiftUI interface, Swift language
3. Replace generated files with existing source files in RiffReader/ directory
4. Add microphone permission in Info.plist: `NSMicrophoneUsageDescription`

## Key Implementation Notes

**Pitch Detection Algorithm:**
- Uses autocorrelation in time domain (more CPU efficient than FFT for monophonic pitch)
- Frequency range: 80-1000 Hz (covers guitar range from low E to high frets)
- Buffer size: 4096 samples for good frequency resolution
- Sample rate: 44.1 kHz (standard iOS audio)

**Guitar Mapping Logic:**
- Each note frequency is compared against all 6 strings across 22 frets
- Optimal position chosen by minimizing stretch (prefers middle positions around 5th fret)
- Open strings: E2(82.41), A2(110.00), D3(146.83), G3(196.00), B3(246.94), E4(329.63)
- Fret calculation: `fret = round(12 * log2(note_freq / open_string_freq))`

**Gameplay Mechanics:**
- Notes scroll horizontally (right to left) over 3 seconds
- Hit zone: 100pt wide zone on left side of screen (green overlay)
- String positions: Screen divided into 6 equal horizontal lanes
- Timing window: Notes must be played when they reach hit zone (±100ms tolerance - TODO)

**Performance Considerations:**
- Audio processing runs on background thread (handled by AVAudioEngine)
- UI updates dispatched to main thread via @Published properties
- Pitch detection runs every 4096 samples (~93ms at 44.1kHz) - real-time capable

**Cloud Integration (Future):**
- For hybrid approach: send audio buffer to cloud API for advanced source separation
- Use case: Extract clean guitar track from complex mix with multiple instruments
- Local fallback: Always available when offline
- Potential APIs: Spleeter, Demucs, or custom ML models

## Critical Code Patterns

**Audio Session Setup:**
Always configure AVAudioSession before starting engine:
```swift
try AVAudioSession.sharedInstance().setCategory(.record, mode: .measurement)
```

**Thread Safety:**
Audio buffers processed on audio thread - use `DispatchQueue.main.async` for UI updates:
```swift
DispatchQueue.main.async {
    self.detectedPitch = pitch
}
```

**Note-to-Frequency Conversion:**
Uses equal temperament: `freq = 440 * 2^((midi_note - 69)/12)`

**Memory Management:**
Remove audio tap when stopping: `inputNode.removeTap(onBus: 0)` to prevent memory leaks

## TODO/Not Yet Implemented

- Xcode project file creation
- Info.plist with microphone permission
- Real-time note verification (listening to user playing)
- Scoring system and streak tracking
- Proper waveform visualization with real audio data
- Note animation timing and synchronization
- Cloud API integration for melody extraction
- Audio file import (currently microphone only)
- Persistence of recorded sessions
- Multiple difficulty levels
- Calibration for different guitars/tunings
