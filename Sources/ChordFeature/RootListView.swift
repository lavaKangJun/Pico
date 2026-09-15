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
            List {
                Section {
                    ForEach(PitchClass.allCases) { pitch in
                        NavigationLink(state: ChordFinderFeature.State(root: pitch)) {
                            row(for: pitch)
                        }
                    }
                } header: {
                    Text("루트를 고르면 그 음으로 쌓은 코드를 볼 수 있어요.", bundle: .chordFeature)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .textCase(nil)
                        .padding(.bottom, 4)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(Text("루트 코드", bundle: .chordFeature))
        } destination: { store in
            ChordFinderView(store: store)
        }
    }

    private func row(for pitch: PitchClass) -> some View {
        HStack(spacing: 14) {
            Text(pitch.name(preferringFlats: pitch.prefersFlatSpelling))
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(pitch.isAccidental ? Color.white : Theme.accent)
                .frame(width: 46, height: 46)
                .background(
                    pitch.isAccidental ? Theme.accent : Theme.accent.opacity(0.12),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(pitch.solfege)
                    .font(.body.weight(.medium))
                Text("메이저 3화음 · \(pitch.majorTriadPreview)", bundle: .chordFeature)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    RootListView(store: Store(initialState: RootListFeature.State()) {
        RootListFeature()
    })
}
