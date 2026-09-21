@testable import ChordCore
import Foundation
import Testing

@Suite("번역")
struct LocalizationTests {
    /// 특정 언어 번들에서 직접 찾아본다. 시뮬레이터 언어 설정과 무관하게 검사하기 위해서다.
    private func string(_ key: String, in language: String) -> String? {
        guard
            let path = Bundle.chordCore.path(forResource: language, ofType: "lproj"),
            let bundle = Bundle(path: path)
        else { return nil }
        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }

    /// 지원하는 모든 언어.
    private static let languages = ["ko", "en", "ja", "zh-Hans", "zh-Hant"]

    @Test("지원하는 언어가 모두 번들에 들어 있다")
    func everyLanguageIsBundled() {
        for language in Self.languages {
            #expect(Bundle.chordCore.path(forResource: language, ofType: "lproj") != nil,
                    "\(language) 번역이 빠졌다")
        }
    }

    @Test("코드 성질 이름이 언어별로 번역된다")
    func chordQualityNames() {
        #expect(string("마이너 세븐스", in: "ko") == "마이너 세븐스")
        #expect(string("마이너 세븐스", in: "en") == "Minor 7th")
        #expect(string("마이너 세븐스", in: "ja") == "マイナー7th")
        #expect(string("마이너 세븐스", in: "zh-Hans") == "小七和弦")
        #expect(string("마이너 세븐스", in: "zh-Hant") == "小七和弦")
    }

    @Test("간체와 번체는 서로 다른 글자를 쓴다")
    func simplifiedAndTraditionalDiffer() {
        #expect(string("도미넌트 세븐스", in: "zh-Hans") == "属七和弦")
        #expect(string("도미넌트 세븐스", in: "zh-Hant") == "屬七和弦")
        #expect(string("12마디 블루스", in: "zh-Hans") == "十二小节布鲁斯")
        #expect(string("12마디 블루스", in: "zh-Hant") == "十二小節藍調")
    }

    @Test("계이름도 언어를 따라간다")
    func solfegeNames() {
        #expect(string("도", in: "en") == "Do")
        #expect(string("도", in: "ja") == "ド")
        #expect(string("시♭", in: "ja") == "シ♭")
        #expect(string("시♭", in: "zh-Hans") == "Si♭")
    }

    @Test("코드 진행 이름과 설명이 번역된다")
    func progressionStrings() {
        #expect(string("팝 진행", in: "en") == "Pop progression")
        #expect(string("팝 진행", in: "ja") == "ポップ進行")
        #expect(string("팝 진행", in: "zh-Hans") == "流行进行")
        #expect(string("팝 진행", in: "zh-Hant") == "流行進行")
        #expect(string("마이너 조성의 해결. m7♭5에서 시작한다.", in: "en") ==
            "The minor-key resolution, starting from m7♭5.")
    }

    @Test("화면에 쓰는 모든 문자열에 번역이 있다")
    func everyDisplayStringIsTranslated() {
        var keys = Set<String>()
        keys.formUnion(ChordQuality.all.map(\.nameKey))
        keys.formUnion(ChordQuality.Category.allCases.map { key(for: $0) })
        keys.formUnion(ChordProgression.all.flatMap { [$0.nameKey, $0.summaryKey] })

        for language in Self.languages.filter({ $0 != "ko" }) {
            for key in keys {
                let translated = string(key, in: language)
                #expect(translated != nil && translated != key,
                        "\(language)에 '\(key)' 번역이 없다")
            }
        }
    }

    /// 분류는 번역 키를 따로 들고 있지 않아 한국어 원문으로 되짚는다.
    private func key(for category: ChordQuality.Category) -> String {
        switch category {
        case .triad: "3화음"
        case .added: "애드"
        case .sixth: "6화음"
        case .seventh: "7화음"
        case .tension: "텐션"
        }
    }
}
