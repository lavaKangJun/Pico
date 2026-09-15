import ChordCore
import SwiftUI

/// 코드 구성음을 짚어서 보여 주는 피아노 건반.
public struct PianoKeyboardView: View {
    /// 강조할 MIDI 노트.
    let highlighted: [Int]
    /// 루트 음. 다른 색으로 칠한다.
    let rootPitch: PitchClass?
    /// 플랫 표기를 쓸지 여부.
    let prefersFlats: Bool
    /// 건반을 눌렀을 때.
    let onKeyTap: (@Sendable (Int) -> Void)?

    public init(
        highlighted: [Int],
        rootPitch: PitchClass? = nil,
        prefersFlats: Bool = false,
        onKeyTap: (@Sendable (Int) -> Void)? = nil
    ) {
        self.highlighted = highlighted
        self.rootPitch = rootPitch
        self.prefersFlats = prefersFlats
        self.onKeyTap = onKeyTap
    }

    private var highlightedSet: Set<Int> { Set(highlighted) }

    /// 강조할 음이 모두 들어가도록 표시 구간을 잡는다. (최소 2옥타브)
    private var range: Range<Int> {
        let lowest = highlighted.min() ?? 60
        let highest = highlighted.max() ?? 71
        let start = (lowest / 12) * 12
        let neededOctaves = Int(ceil(Double(highest - start + 1) / 12.0))
        return start ..< (start + 12 * max(2, neededOctaves))
    }

    private var whiteKeys: [Int] {
        range.filter { !PitchClass(midiNote: $0).isAccidental }
    }

    public var body: some View {
        GeometryReader { proxy in
            let whiteWidth = proxy.size.width / CGFloat(whiteKeys.count)
            let blackWidth = whiteWidth * 0.62
            let blackHeight = proxy.size.height * 0.62

            ZStack(alignment: .topLeading) {
                HStack(spacing: 0) {
                    ForEach(whiteKeys, id: \.self) { note in
                        whiteKey(note: note, width: whiteWidth, height: proxy.size.height)
                    }
                }

                ForEach(Array(whiteKeys.enumerated()), id: \.offset) { index, note in
                    let blackNote = note + 1
                    if range.contains(blackNote), PitchClass(midiNote: blackNote).isAccidental {
                        blackKey(note: blackNote, width: blackWidth, height: blackHeight)
                            .offset(x: CGFloat(index + 1) * whiteWidth - blackWidth / 2)
                    }
                }
            }
        }
        .frame(height: 168)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
        )
        .animation(.easeOut(duration: 0.18), value: highlightedSet)
    }

    // MARK: - 건반

    private func whiteKey(note: Int, width: CGFloat, height: CGFloat) -> some View {
        let isOn = highlightedSet.contains(note)
        return ZStack(alignment: .bottom) {
            Rectangle()
                .fill(isOn ? color(for: note) : Color(.systemBackground))
            if isOn {
                Text(PitchClass(midiNote: note).name(preferringFlats: prefersFlats))
                    .font(.system(size: min(11, width * 0.42), weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.bottom, 8)
            }
        }
        .frame(width: width, height: height)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(Color.primary.opacity(0.14))
                .frame(width: 1)
        }
        .contentShape(Rectangle())
        .onTapGesture { onKeyTap?(note) }
    }

    private func blackKey(note: Int, width: CGFloat, height: CGFloat) -> some View {
        let isOn = highlightedSet.contains(note)
        return ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(isOn ? color(for: note) : Color(red: 0.13, green: 0.13, blue: 0.15))
            if isOn {
                Text(PitchClass(midiNote: note).name(preferringFlats: prefersFlats))
                    .font(.system(size: min(9, width * 0.4), weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.bottom, 6)
            }
        }
        .frame(width: width, height: height)
        .contentShape(Rectangle())
        .onTapGesture { onKeyTap?(note) }
    }

    private func color(for note: Int) -> Color {
        PitchClass(midiNote: note) == rootPitch ? Theme.root : Theme.tone
    }
}

#Preview {
    PianoKeyboardView(
        highlighted: Chord(root: .c, quality: .majorSeventh).midiNotes(),
        rootPitch: .c
    )
    .padding()
}
