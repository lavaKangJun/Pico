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
            // 흰 건반 기준으로 한 번만 정해 두 건반이 같은 크기로 보이게 한다.
            let labelSize = min(11, whiteWidth * 0.42)

            ZStack(alignment: .topLeading) {
                HStack(spacing: 0) {
                    ForEach(whiteKeys, id: \.self) { note in
                        whiteKey(note: note, width: whiteWidth, height: proxy.size.height, labelSize: labelSize)
                    }
                }

                ForEach(Array(whiteKeys.enumerated()), id: \.offset) { index, note in
                    let blackNote = note + 1
                    if range.contains(blackNote), PitchClass(midiNote: blackNote).isAccidental {
                        blackKey(note: blackNote, width: blackWidth, height: blackHeight, labelSize: labelSize)
                            .offset(x: CGFloat(index + 1) * whiteWidth - blackWidth / 2)
                    }
                }
            }
        }
        .frame(height: 168)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(KeyColor.border, lineWidth: 1)
        )
        .animation(.easeOut(duration: 0.18), value: highlightedSet)
    }

    // MARK: - 건반

    private func whiteKey(note: Int, width: CGFloat, height: CGFloat, labelSize: CGFloat) -> some View {
        let isOn = highlightedSet.contains(note)
        return ZStack(alignment: .bottom) {
            Rectangle()
                .fill(isOn ? color(for: note) : KeyColor.white)
            if isOn {
                Text(PitchClass(midiNote: note).name(preferringFlats: prefersFlats))
                    .font(.system(size: min(12, width * 0.42), weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.bottom, 8)
            }
        }
        .frame(width: width, height: height)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(KeyColor.separator)
                .frame(width: 1)
        }
        .contentShape(Rectangle())
        .onTapGesture { onKeyTap?(note) }
    }

    private func blackKey(note: Int, width: CGFloat, height: CGFloat, labelSize: CGFloat) -> some View {
        let isOn = highlightedSet.contains(note)
        return ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(isOn ? color(for: note) : KeyColor.black)
            if isOn {
                Text(PitchClass(midiNote: note).name(preferringFlats: prefersFlats))
                    // 흰 건반과 같은 크기. 좁은 건반에서 두 글자가 넘칠 때만 줄어든다.
                    .font(.system(size: labelSize, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 1)
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

/// 건반 색은 밝기 모드를 따라가지 않는다.
///
/// 흰 건반에 `systemBackground`를 쓰면 다크 모드에서 검정이 되어, 검은 건반과 구분되지 않는다.
/// 실제 피아노가 그렇듯 두 모드에서 같은 색으로 둔다.
private enum KeyColor {
    static let white = Color(red: 0.96, green: 0.96, blue: 0.97)
    static let black = Color(red: 0.13, green: 0.13, blue: 0.15)
    /// 흰 건반끼리 나누는 선.
    static let separator = Color.black.opacity(0.16)
    /// 건반 전체를 두르는 선.
    static let border = Color.black.opacity(0.18)
}

#Preview {
    PianoKeyboardView(
        highlighted: Chord(root: .c, quality: .majorSeventh).midiNotes(),
        rootPitch: .c
    )
    .padding()
}
