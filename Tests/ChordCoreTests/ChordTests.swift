@testable import ChordCore
import Testing

@Suite("코드 구성음")
struct ChordTests {
    @Test("메이저 3화음은 루트, 장3도, 완전5도로 이뤄진다")
    func majorTriad() {
        let chord = Chord(root: .c, quality: .major)
        #expect(chord.pitches == [.c, .e, .g])
        #expect(chord.symbol == "C")
        #expect(chord.midiNotes(octave: 4) == [60, 64, 67])
    }

    @Test("마이너 세븐스는 네 음이고 심볼에 m7이 붙는다")
    func minorSeventh() {
        let chord = Chord(root: .a, quality: .minorSeventh)
        #expect(chord.pitches == [.a, .c, .e, .g])
        #expect(chord.symbol == "Am7")
        #expect(chord.midiNotes(octave: 4) == [69, 72, 76, 79])
    }

    @Test("샤프와 플랫은 같은 소리라도 다른 코드로 적는다")
    func enharmonicSpelling() {
        let sharp = Chord(root: .aSharp, quality: .major)
        let flat = Chord(root: .bFlat, quality: .major)

        #expect(sharp.symbol == "A♯")
        #expect(flat.symbol == "B♭")
        // 적는 법만 다르고 울리는 소리는 같다.
        #expect(sharp.midiNotes() == flat.midiNotes())
        #expect(sharp != flat)

        #expect(Chord(root: .cSharp, quality: .minorSeventh).symbol == "C♯m7")
        #expect(Chord(root: .dFlat, quality: .minorSeventh).symbol == "D♭m7")
        #expect(Chord(root: .gSharp, quality: .major).symbol == "G♯")
        #expect(Chord(root: .aFlat, quality: .major).symbol == "A♭")
    }

    @Test("전위는 아래 음을 한 옥타브씩 올린다")
    func inversions() {
        let chord = Chord(root: .c, quality: .major)
        #expect(chord.midiNotes(octave: 4, inversion: 1) == [64, 67, 72])
        #expect(chord.midiNotes(octave: 4, inversion: 2) == [67, 72, 76])
        #expect(chord.symbol(inversion: 1) == "C/E")
        #expect(chord.symbol(inversion: 2) == "C/G")
    }

    @Test("전위 번호가 범위를 넘으면 마지막 전위로 고정된다")
    func inversionClamping() {
        let chord = Chord(root: .c, quality: .major)
        #expect(chord.inversionCount == 3)
        #expect(chord.midiNotes(inversion: 9) == chord.midiNotes(inversion: 2))
        #expect(chord.midiNotes(inversion: -3) == chord.midiNotes(inversion: 0))
    }

    @Test("텐션 코드는 옥타브 위 음까지 포함한다")
    func tensionChord() {
        let chord = Chord(root: .c, quality: .ninth)
        #expect(chord.midiNotes(octave: 4) == [60, 64, 67, 70, 74])
        // 9도(D)는 루트와 같은 피치 클래스가 아니므로 구성음에 그대로 남는다.
        #expect(chord.pitches == [.c, .e, .g, .aSharp, .d])
    }

    @Test("6/9 코드처럼 중복되는 피치 클래스는 한 번만 센다")
    func deduplicatesPitches() {
        let chord = Chord(root: .c, quality: .sixNine)
        #expect(chord.pitches.count == chord.quality.intervals.count)
        #expect(Set(chord.pitches).count == chord.pitches.count)
    }

    @Test("코드의 계이름은 음이름 표기를 따라간다")
    func chordSolfege() {
        #expect(Chord(root: .fSharp, quality: .major).pitchNames == ["F♯", "A♯", "C♯"])
        #expect(Chord(root: .fSharp, quality: .major).solfegeNames == ["파♯", "라♯", "도♯"])
        #expect(Chord(root: .bFlat, quality: .major).pitchNames == ["B♭", "D", "F"])
        #expect(Chord(root: .bFlat, quality: .major).solfegeNames == ["시♭", "레", "파"])
        // 루트를 A♯으로 적으면 구성음도 샤프로 적는다.
        #expect(Chord(root: .aSharp, quality: .major).pitchNames == ["A♯", "D", "F"])
    }

    @Test("구성음으로 코드를 되찾을 수 있다")
    func reverseLookup() {
        let matches = Chord.matching(midiNotes: [60, 64, 67])
        #expect(matches.contains(Chord(root: .c, quality: .major)))
        #expect(matches.first?.quality == .major)
    }

    @Test("도수 표기는 반음 간격을 따른다")
    func degreeLabels() {
        #expect(ChordQuality.minorSeventh.degreeLabels == ["R", "♭3", "5", "♭7"])
        #expect(ChordQuality.halfDiminished.degreeLabels == ["R", "♭3", "♭5", "♭7"])
        #expect(ChordQuality.thirteenth.degreeLabels == ["R", "3", "5", "♭7", "9", "13"])
    }
}

@Suite("음이름")
struct PitchClassTests {
    @Test("이조는 12음을 순환한다")
    func transposition() {
        #expect(PitchClass.b.transposed(by: 1) == .c)
        #expect(PitchClass.c.transposed(by: -1) == .b)
        #expect(PitchClass.c.transposed(by: 12) == .c)
    }

    @Test("MIDI 노트 번호를 음이름으로 바꾼다")
    func midiNaming() {
        #expect(60.midiNoteName() == "C4")
        #expect(69.midiNoteName() == "A4")
        #expect(61.midiNoteName(preferringFlats: true) == "D♭4")
    }

    @Test("계이름은 음이름과 같은 표기 규칙을 따른다")
    func solfegeSpelling() {
        // D♭이면 계이름도 도♯이 아니라 레♭으로 읽는다.
        #expect(PitchClass.cSharp.flatName == "D♭")
        #expect(PitchClass.cSharp.solfege == "레♭")
        #expect(PitchClass.cSharp.solfege(preferringFlats: false) == "도♯")
        #expect(PitchClass.fSharp.solfege == "파♯")
    }

    @Test("A4는 440Hz다")
    func frequency() {
        #expect(abs(69.midiFrequency - 440.0) < 0.0001)
        #expect(abs(81.midiFrequency - 880.0) < 0.0001)
    }
}

@Suite("코드 진행")
struct ChordProgressionTests {
    @Test("C 키의 팝 진행은 C–G–Am–F다")
    func popInC() {
        let chords = ChordProgression.pop.chords(inKey: .c)
        #expect(chords.map(\.symbol) == ["C", "G", "Am", "F"])
    }

    @Test("조를 옮기면 모든 코드가 함께 이조된다")
    func transposedProgression() {
        let chords = ChordProgression.pop.chords(inKey: .g)
        #expect(chords.map(\.symbol) == ["G", "D", "Em", "C"])
    }

    @Test("투 파이브 원은 세븐스 코드로 이뤄진다")
    func twoFiveOne() {
        let chords = ChordProgression.twoFiveOne.chords(inKey: .c)
        #expect(chords.map(\.symbol) == ["Dm7", "G7", "Cmaj7"])
        #expect(ChordProgression.twoFiveOne.numeralDescription == "ii7 – V7 – IΔ7")
    }

    @Test("음이름 17개가 모두 코드 루트로 쓰인다")
    func everyNoteNameIsAvailable() {
        #expect(NoteName.allCases.count == 17)
        // 검은 건반은 샤프와 플랫 두 가지로 적을 수 있다.
        let blackKeyNames = NoteName.allCases.filter(\.isAccidental)
        #expect(blackKeyNames.count == 10)
        #expect(Set(NoteName.allCases.map(\.pitch)).count == 12)
        #expect(NoteName.allCases.map(\.name).contains("C♯"))
        #expect(NoteName.allCases.map(\.name).contains("G♯"))
        #expect(NoteName.allCases.map(\.name).contains("G♭"))
    }

    @Test("검은 건반은 짝이 되는 표기를 안다")
    func enharmonicPairs() {
        #expect(NoteName.cSharp.enharmonic == .dFlat)
        #expect(NoteName.dFlat.enharmonic == .cSharp)
        #expect(NoteName.gSharp.enharmonic == .aFlat)
        #expect(NoteName.c.enharmonic == nil)
        #expect(NoteName.f.enharmonic == nil)
        // 두 표기는 늘 샤프, 플랫 순서로 나온다.
        #expect(PitchClass.gSharp.noteNames == [.gSharp, .aFlat])
        #expect(PitchClass.g.noteNames == [.g])
    }

    @Test("이조하면 샤프는 샤프로, 플랫은 플랫으로 남는다")
    func transposeKeepsSpelling() {
        #expect(NoteName.cSharp.transposed(by: 2) == .dSharp)
        #expect(NoteName.dFlat.transposed(by: 2) == .eFlat)
        #expect(NoteName.c.transposed(by: 1) == .cSharp)
        #expect(NoteName.g.transposed(by: 7) == .d)
    }

    @Test("모든 진행의 id는 겹치지 않는다")
    func uniqueIDs() {
        #expect(Set(ChordProgression.all.map(\.id)).count == ChordProgression.all.count)
    }
}
