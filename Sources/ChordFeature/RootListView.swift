import ChordCore
import ComposableArchitecture
import SwiftUI

/// 앱을 열면 가장 먼저 보이는 루트 코드 목록.
public struct RootListView: View {
    @Bindable var store: StoreOf<RootListFeature>

    public init(store: StoreOf<RootListFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(PitchClass.allCases) { pitch in
                        NavigationLink(state: ChordFinderFeature.State(root: pitch.defaultNoteName)) {
                            row(for: pitch)
                        }
                        .buttonStyle(CardButtonStyle())
                    }
                }
                .padding(16)
            }
            .background(Theme.groupedBackground)
            .navigationTitle(Text("코드 찾기", bundle: .chordFeature))
        } destination: { store in
            ChordFinderView(store: store)
        }
    }

    private func row(for pitch: PitchClass) -> some View {
        HStack(spacing: 14) {
            // 검은 건반은 C♯/D♭처럼 두 표기를 함께 적는다.
            Text(pitch.combinedName)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, 4)
                .foregroundStyle(pitch.isAccidental ? Color.white : Theme.accent)
                .frame(width: 58, height: 40)
                .background(
                    pitch.isAccidental ? Theme.accent : Theme.accent.opacity(0.12),
                    in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(pitch.combinedSolfege)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                Text("메이저 3화음 · \(pitch.defaultNoteName.majorTriadPreview)", bundle: .chordFeature)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        // cardStyle()의 16pt 대신 위아래만 좁혀 셀 높이를 낮춘다.
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
    }
}

#Preview {
    RootListView(store: Store(initialState: RootListFeature.State()) {
        RootListFeature()
    })
}
