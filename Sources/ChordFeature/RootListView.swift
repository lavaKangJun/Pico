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
                    Text("루트를 고르면 그 음으로 쌓은 코드를 볼 수 있어요.", bundle: .chordFeature)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)

                    ForEach(PitchClass.allCases) { pitch in
                        NavigationLink(state: ChordFinderFeature.State(root: pitch)) {
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
            Text(pitch.name(preferringFlats: pitch.prefersFlatSpelling))
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(pitch.isAccidental ? Color.white : Theme.accent)
                .frame(width: 40, height: 40)
                .background(
                    pitch.isAccidental ? Theme.accent : Theme.accent.opacity(0.12),
                    in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(pitch.solfege)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                Text("메이저 3화음 · \(pitch.majorTriadPreview)", bundle: .chordFeature)
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
