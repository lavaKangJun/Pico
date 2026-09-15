import ChordCore
import ComposableArchitecture
import SwiftUI

public struct ProgressionView: View {
    @Bindable var store: StoreOf<ProgressionFeature>

    public init(store: StoreOf<ProgressionFeature>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                progressionPicker
                chordStrip
                selectedChordCard
                keyPicker
            }
            .padding(16)
        }
        .background(Theme.groupedBackground)
        .navigationTitle(Text("코드 진행", bundle: .chordFeature))
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - 진행 고르기

    private var progressionPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ChordProgression.all) { progression in
                        let isSelected = progression == store.progression
                        Button {
                            store.send(.progressionTapped(progression))
                        } label: {
                            Text(progression.name)
                                .font(.subheadline.weight(.medium))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    isSelected ? Theme.accent : Color(.tertiarySystemGroupedBackground),
                                    in: Capsule()
                                )
                                .foregroundStyle(isSelected ? Color.white : Color.primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(store.progression.numeralDescription)
                    .font(.system(.headline, design: .rounded))
                Text(store.progression.summary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .cardStyle()
    }

    // MARK: - 코드 카드와 재생

    private var chordStrip: some View {
        VStack(spacing: 14) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(store.chords.enumerated()), id: \.offset) { index, chord in
                        let isActive = store.selectedIndex == index
                        Button {
                            store.send(.chordTapped(index))
                        } label: {
                            VStack(spacing: 6) {
                                Text(store.progression.steps[index].numeral)
                                    .font(.caption.weight(.semibold))
                                    .opacity(0.7)
                                Text(chord.symbol)
                                    .font(.system(.title3, design: .rounded).weight(.bold))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.6)
                            }
                            .frame(width: 86, height: 76)
                            .background(
                                isActive ? Theme.accent : Color(.tertiarySystemGroupedBackground),
                                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                            )
                            .foregroundStyle(isActive ? Color.white : Color.primary)
                            .scaleEffect(isActive ? 1.04 : 1)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 2)
            }

            HStack(spacing: 12) {
                Button {
                    store.send(store.isPlaying ? .stopButtonTapped : .playAllButtonTapped)
                } label: {
                    Label {
                        Text(store.isPlaying ? "정지" : "진행 듣기", bundle: .chordFeature)
                    } icon: {
                        Image(systemName: store.isPlaying ? "stop.fill" : "play.fill")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(store.isPlaying ? Color.red : Theme.accent)
            }

            HStack(spacing: 12) {
                Image(systemName: "metronome")
                    .foregroundStyle(.secondary)
                Slider(value: $store.tempo, in: 50 ... 160, step: 1)
                    .tint(Theme.accent)
                Text(verbatim: "\(Int(store.tempo)) BPM")
                    .font(.system(.footnote, design: .rounded).weight(.medium))
                    .monospacedDigit()
                    .frame(width: 66, alignment: .trailing)
            }
        }
        .cardStyle()
    }

    // MARK: - 고른 코드

    @ViewBuilder
    private var selectedChordCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let chord = store.selectedChord {
                HStack(alignment: .firstTextBaseline) {
                    Text(chord.symbol)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                    Spacer()
                    Text(chord.pitchNames.joined(separator: " · "))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                PianoKeyboardView(
                    highlighted: chord.midiNotes(),
                    rootPitch: chord.root.pitch,
                    prefersFlats: chord.prefersFlatSpelling
                )
            } else {
                Text("코드를 눌러 구성음을 확인해 보세요.", bundle: .chordFeature)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 28)
            }
        }
        .cardStyle()
    }

    // MARK: - 조성 고르기

    private var keyPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("조성", bundle: .chordFeature)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(store.keyName) · \(store.progression.tonality.displayName)")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                ForEach(NoteName.allCases) { note in
                    let isSelected = note == store.key
                    Button {
                        store.send(.keyTapped(note))
                    } label: {
                        Text(note.name)
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                isSelected ? Theme.accent : Color(.tertiarySystemGroupedBackground),
                                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                            )
                            .foregroundStyle(isSelected ? Color.white : Color.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .cardStyle()
    }
}

#Preview {
    NavigationStack {
        ProgressionView(store: Store(initialState: ProgressionFeature.State()) {
            ProgressionFeature()
        })
    }
}
