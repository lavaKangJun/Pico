import ComposableArchitecture
import Foundation

/// 크래시 리포터에 남기는 기록을 감싼 의존성.
///
/// `ChordCore`는 Firebase를 모른다. 실제 구현은 앱 타깃의 `CrashReporterClient.firebase`에 있고,
/// 앱을 켤 때 `prepareDependencies`로 갈아 끼운다. 그래서 `liveValue`가 아무것도 하지 않는
/// 구현이다 — 주입하지 않으면 기록이 조용히 버려질 뿐 앱은 그대로 돈다.
public struct CrashReporterClient: Sendable {
    /// 앱이 죽지는 않았지만 남겨 둘 만한 실패.
    public var recordError: @Sendable (_ error: any Error, _ context: [String: String]) -> Void
    /// 크래시 로그에 함께 실리는 빵부스러기. 죽기 직전에 무슨 일이 있었는지 되짚는 용도다.
    public var log: @Sendable (_ message: String) -> Void
    /// 크래시에 붙는 키/값. 같은 키를 다시 쓰면 덮어쓴다.
    public var setKey: @Sendable (_ key: String, _ value: String) -> Void

    public init(
        recordError: @escaping @Sendable (any Error, [String: String]) -> Void,
        log: @escaping @Sendable (String) -> Void,
        setKey: @escaping @Sendable (String, String) -> Void
    ) {
        self.recordError = recordError
        self.log = log
        self.setKey = setKey
    }

    /// 호출하는 쪽에서 쓰는 형태. 저장 프로퍼티와 이름이 같으면 순환 참조가 되므로 따로 둔다.
    public func record(_ error: any Error, context: [String: String] = [:]) {
        recordError(error, context)
    }
}

public extension CrashReporterClient {
    /// 아무것도 하지 않는 구현.
    static let noop = CrashReporterClient(
        recordError: { _, _ in },
        log: { _ in },
        setKey: { _, _ in }
    )
}

extension CrashReporterClient: DependencyKey {
    // 앱 타깃이 Firebase 구현을 주입하기 전까지의 기본값이다. 주입하지 않으면 계속 no-op이다.
    // (타입을 적지 않으면 Value 추론이 세 값을 돌며 순환 참조가 된다)
    public static let liveValue: CrashReporterClient = .noop
    public static let testValue: CrashReporterClient = .noop
    public static let previewValue: CrashReporterClient = .noop
}

public extension DependencyValues {
    var crashReporter: CrashReporterClient {
        get { self[CrashReporterClient.self] }
        set { self[CrashReporterClient.self] = newValue }
    }
}
