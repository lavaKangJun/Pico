import ChordCore
import ComposableArchitecture
import SwiftUI

public struct ChordFinderView: View {
    @Bindable var store: StoreOf<ChordFinderFeature>

    public init(store: StoreOf<ChordFinderFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            rootStrip
            ScrollView {
                VStack(spacing: 16) {
                    summaryCard
                    AdBannerView(horizontalInset: 16)
                    keyboardCard
                    qualityPicker
                }
                .padding(16)
            }
        }
        .background(Theme.groupedBackground)
        .navigationTitle(store.symbol)
        .navigationBarTitleDisplayMode(.inline)
        .task { store.send(.viewAppeared) }
    }

    // MARK: - 최상단 루트 스트립

    /// 화면 맨 위에 고정되는 루트 선택 줄. 가로로 넘겨 다른 루트로 바로 옮겨 간다.
    private var rootStrip: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(PitchClass.allCases) { pitch in
                        let isSelected = pitch == store.root.pitch
                        Button {
                            store.send(.rootTapped(pitch.defaultNoteName))
                        } label: {
                            VStack(spacing: 1) {
                                Text(pitch.combinedName)
                                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.6)
                                Text(pitch.combinedSolfege)
                                    .font(.caption2)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.6)
                                    .opacity(0.7)
                            }
                            .frame(width: 62)
                            .padding(.vertical, 8)
                            .background(
                                isSelected ? Theme.accent : Color(.tertiarySystemGroupedBackground),
                                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                            )
                            .foregroundStyle(isSelected ? Color.white : Color.primary)
                        }
                        .buttonStyle(.plain)
                        .id(pitch)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .onAppear { proxy.scrollTo(store.root.pitch, anchor: .center) }
            .onChange(of: store.root.pitch) { _, newPitch in
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo(newPitch, anchor: .center)
                }
            }
        }
        .background(Theme.card)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    // MARK: - 코드 요약

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(store.symbol)
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)

                    // 검은 건반은 같은 소리를 두 가지로 적을 수 있어 코드 이름 바로 옆에서 고른다.
                    if store.root.enharmonic != nil {
                        spellingPicker
                    }

                    Spacer(minLength: 0)
                }

                Text(store.quality.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            FlowLayout(spacing: 8) {
                ForEach(store.chord.tones) { tone in
                    VStack(spacing: 2) {
                        Text(tone.name)
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        Text(tone.degree)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(minWidth: 46)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .background(
                        (tone.semitone == 0 ? Theme.root : Theme.tone).opacity(0.14),
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                    )
                }
            }

            Text(store.chord.solfegeNames.joined(separator: " · "))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .cardStyle()
        .animation(.easeOut(duration: 0.2), value: store.symbol)
    }

    /// C♯과 D♭처럼 같은 소리를 어떻게 적을지 고르는 토글.
    private var spellingPicker: some View {
        Picker(selection: .init(
            get: { store.root },
            set: { store.send(.rootTapped($0)) }
        )) {
            ForEach(store.root.pitch.noteNames) { spelling in
                Text(spelling.name).tag(spelling)
            }
        } label: {
            Text("표기", bundle: .chordFeature)
        }
        .pickerStyle(.segmented)
        .frame(width: 104)
        // 세그먼트를 코드 이름의 밑선에 맞춰 나란히 놓는다.
        .alignmentGuide(.firstTextBaseline) { $0[.bottom] - 4 }
    }

    // MARK: - 건반과 재생

    private var keyboardCard: some View {
        VStack(spacing: 14) {
            PianoKeyboardView(
                highlighted: store.midiNotes,
                rootPitch: store.root.pitch,
                prefersFlats: store.chord.prefersFlatSpelling,
                onKeyTap: { note in store.send(.keyTapped(note)) }
            )

            HStack(spacing: 12) {
                Button {
                    store.send(.playButtonTapped)
                } label: {
                    Label {
                        // 어느 언어에서나 그대로 "Play"로 둔다.
                        Text(verbatim: "Play")
                    } icon: {
                        Image(systemName: "play.fill")
                    }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accent)

                Picker(selection: $store.style) {
                    ForEach(PlaybackStyle.allCases) { style in
                        Image(systemName: style.systemImage).tag(style)
                    }
                } label: {
                    Text("재생 방식", bundle: .chordFeature)
                }
                .pickerStyle(.segmented)
                .frame(width: 110)
            }

            HStack {
                Text("전위", bundle: .chordFeature)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Picker(selection: .init(
                    get: { store.inversion },
                    set: { store.send(.inversionTapped($0)) }
                )) {
                    ForEach(store.inversionOptions, id: \.self) { inversion in
                        Text(inversionLabel(inversion)).tag(inversion)
                    }
                } label: {
                    Text("전위", bundle: .chordFeature)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 220)
            }

            HStack {
                Text("옥타브", bundle: .chordFeature)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Button {
                    store.send(.octaveStepped(-1))
                } label: {
                    Image(systemName: "minus")
                }
                .buttonStyle(.bordered)
                .disabled(!store.canLowerOctave)

                Text("\(store.octave)")
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .frame(minWidth: 28)

                Button {
                    store.send(.octaveStepped(1))
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.bordered)
                .disabled(!store.canRaiseOctave)
            }
        }
        .cardStyle()
    }

    private func inversionLabel(_ inversion: Int) -> String {
        switch inversion {
        case 0: localized("기본")
        case 1: localized("1전위")
        case 2: localized("2전위")
        default: localized("3전위")
        }
    }

    // MARK: - 코드 성질 고르기

    private var qualityPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker(selection: .init(
                get: { store.category },
                set: { store.send(.categoryTapped($0)) }
            )) {
                ForEach(ChordQuality.Category.allCases) { category in
                    Text(category.displayName).tag(category)
                }
            } label: {
                Text("분류", bundle: .chordFeature)
            }
            .pickerStyle(.segmented)
            .disabled(store.isWaitingForAd)

            // 세그먼트 컨트롤은 라벨에 아이콘을 못 넣으므로 아래에 따로 알린다.
            if !store.lockedCategories.isEmpty {
                Label {
                    Text(
                        "광고를 보면 \(store.lockedCategories.map(\.displayName).joined(separator: ", ")) 분류를 열 수 있어요.",
                        bundle: .chordFeature
                    )
                } icon: {
                    Image(systemName: "lock.fill")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(store.qualities) { quality in
                    let isSelected = quality == store.quality
                    Button {
                        store.send(.qualityTapped(quality))
                    } label: {
                        VStack(spacing: 2) {
                            Text(store.root.name + quality.symbol)
                                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            Text(quality.displayName)
                                .font(.caption2)
                                .opacity(0.7)
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                        }
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
        ChordFinderView(store: Store(initialState: ChordFinderFeature.State()) {
            ChordFinderFeature()
        })
    }
}
