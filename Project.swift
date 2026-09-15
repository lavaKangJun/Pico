import ProjectDescription

// MARK: - 공통 상수

private let bundleIDPrefix = "com.lavakangjun.pico"
private let deploymentTargets: DeploymentTargets = .iOS("17.0")
private let destinations: Destinations = [.iPhone, .iPad]

/// 한국어로 쓰고 영어·일본어·중국어(간체/번체)로 번역한다.
private let developmentRegion = "ko"
private let knownRegions = ["ko", "en", "ja", "zh-Hans", "zh-Hant"]

private let baseSettings: SettingsDictionary = [
    "SWIFT_VERSION": "6.0",
    "SWIFT_STRICT_CONCURRENCY": "complete",
    "DEVELOPMENT_TEAM": "",
    "CODE_SIGN_STYLE": "Automatic",
]

// MARK: - 타깃 헬퍼

private func module(
    name: String,
    dependencies: [TargetDependency]
) -> Target {
    .target(
        name: name,
        destinations: destinations,
        product: .staticFramework,
        bundleId: "\(bundleIDPrefix).\(name.lowercased())",
        deploymentTargets: deploymentTargets,
        infoPlist: .default,
        sources: ["Sources/\(name)/**"],
        // 모듈마다 자기 String Catalog을 들고 다닌다. (Bundle.module로 읽는다)
        resources: ["Sources/\(name)/Resources/**"],
        dependencies: dependencies
    )
}

private func testTarget(
    name: String,
    dependencies: [TargetDependency]
) -> Target {
    .target(
        name: name,
        destinations: destinations,
        product: .unitTests,
        bundleId: "\(bundleIDPrefix).\(name.lowercased())",
        deploymentTargets: deploymentTargets,
        infoPlist: .default,
        sources: ["Tests/\(name)/**"],
        dependencies: dependencies
    )
}

// MARK: - 프로젝트

let project = Project(
    name: "Pico",
    organizationName: "lavaKangJun",
    options: .options(
        defaultKnownRegions: knownRegions,
        developmentRegion: developmentRegion
    ),
    packages: [
        .remote(
            url: "https://github.com/pointfreeco/swift-composable-architecture",
            requirement: .exact("1.26.2")
        ),
        .remote(
            url: "https://github.com/googleads/swift-package-manager-google-mobile-ads",
            requirement: .upToNextMajor(from: "13.9.0")
        ),
    ],
    settings: .settings(base: baseSettings),
    targets: [
        .target(
            name: "Pico",
            destinations: destinations,
            product: .app,
            bundleId: bundleIDPrefix,
            deploymentTargets: deploymentTargets,
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "Pico",
                "UILaunchScreen": ["UIColorName": ""],
                "UIUserInterfaceStyle": "Automatic",
                "UISupportedInterfaceOrientations": [
                    "UIInterfaceOrientationPortrait",
                ],
                "ITSAppUsesNonExemptEncryption": false,
                // 번역 리소스는 모듈 번들에 있으므로, 앱이 지원하는 언어를 여기서 알린다.
                "CFBundleLocalizations": .array(knownRegions.map { .string($0) }),
                // TODO: 배포 전에 AdMob 콘솔에서 발급받은 앱 ID로 바꾼다.
                // 지금 값은 구글이 공개한 테스트 앱 ID라 실제 광고가 나가지 않는다.
                "GADApplicationIdentifier": "ca-app-pub-3940256099942544~1458002511",
                // 배포 전에 구글 문서의 전체 목록으로 채운다.
                // https://developers.google.com/admob/ios/quick-start#skadnetwork
                "SKAdNetworkItems": .array([
                    .dictionary(["SKAdNetworkIdentifier": "cstr6suwn9.skadnetwork"]),
                ]),
            ]),
            sources: ["Sources/App/**"],
            resources: ["Resources/**"],
            dependencies: [
                .target(name: "ChordFeature"),
                // 정적 프레임워크는 동적 라이브러리를 품을 수 없으므로,
                // 앱 타깃에서도 직접 링크해 번들에 들어가게 한다.
                .package(product: "GoogleMobileAds"),
            ]
        ),
        module(
            name: "ChordFeature",
            dependencies: [
                .target(name: "ChordCore"),
                .package(product: "ComposableArchitecture"),
                .package(product: "GoogleMobileAds"),
            ]
        ),
        module(
            name: "ChordCore",
            dependencies: [
                .package(product: "ComposableArchitecture"),
            ]
        ),
        testTarget(
            name: "ChordCoreTests",
            dependencies: [.target(name: "ChordCore")]
        ),
        testTarget(
            name: "ChordFeatureTests",
            dependencies: [.target(name: "ChordFeature")]
        ),
    ]
)
