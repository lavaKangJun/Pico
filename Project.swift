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
            ]),
            sources: ["Sources/App/**"],
            resources: ["Resources/**"],
            dependencies: [
                .target(name: "ChordFeature"),
            ]
        ),
        module(
            name: "ChordFeature",
            dependencies: [
                .target(name: "ChordCore"),
                .package(product: "ComposableArchitecture"),
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
