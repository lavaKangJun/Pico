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
                LazyVStack(alignment: .leading, spacing: 12) {
                    header
                        .padding(.bottom, 4)

                    ForEach(PitchClass.allCases) { pitch in
                        NavigationLink(state: ChordFinderFeature.State(root: pitch.defaultNoteName)) {
                            row(for: pitch)
                        }
                        .buttonStyle(CardButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(Theme.listBackground.ignoresSafeArea())
            // 큰 제목을 직접 그리므로 내비게이션 바는 접는다. 상세 화면은 자기 바를 따로 띄운다.
            .toolbar(.hidden, for: .navigationBar)
        } destination: { store in
            ChordFinderView(store: store)
        }
    }

    // MARK: - 머리말

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("코드 찾기", bundle: .chordFeature)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text("원하는 코드를 빠르게 찾아보세요", bundle: .chordFeature)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 44)
    }

    // MARK: - 목록 한 줄

    private func row(for pitch: PitchClass) -> some View {
        HStack(spacing: 14) {
            badge(for: pitch)

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
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassBackground()
    }

    /// 루트마다 색이 다른 배지. 검은 건반은 C♯/D♭처럼 두 표기를 함께 적는다.
    private func badge(for pitch: PitchClass) -> some View {
        Text(pitch.combinedName)
            .font(.system(size: 17, weight: .bold, design: .rounded))
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .padding(.horizontal, 4)
            .foregroundStyle(.white)
            .frame(width: 58, height: 40)
            .background(Theme.badge(for: pitch), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: Theme.badgeGlow(for: pitch), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    RootListView(store: Store(initialState: RootListFeature.State()) {
        RootListFeature()
    })
}
