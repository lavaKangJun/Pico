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

// MARK: - 빌드 스크립트

/// 아카이브할 때 dSYM을 Crashlytics로 올린다.
///
/// 이게 없으면 크래시 로그가 심볼 없는 주소값으로만 올라와 어디서 죽었는지 읽을 수 없다.
/// `runForInstallBuildsOnly`라서 평소 디버그 빌드는 건드리지 않는다.
private let crashlyticsSymbolUpload = TargetScript.post(
    script: """
    # SPM으로 붙인 Firebase는 체크아웃 경로가 빌드 디렉터리 안에 있다.
    RUN_SCRIPT="${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run"
    if [ -f "$RUN_SCRIPT" ]; then
      "$RUN_SCRIPT"
    else
      echo "warning: Crashlytics run 스크립트를 찾지 못했다. dSYM이 올라가지 않는다."
    fi
    """,
    name: "Upload Crashlytics dSYM",
    inputPaths: [
        "${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/${TARGET_NAME}",
        "$(SRCROOT)/$(BUILT_PRODUCTS_DIR)/$(INFOPLIST_PATH)",
    ],
    basedOnDependencyAnalysis: false,
    runForInstallBuildsOnly: true
)

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
        .remote(
            url: "https://github.com/firebase/firebase-ios-sdk",
            requirement: .upToNextMajor(from: "11.0.0")
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
            scripts: [crashlyticsSymbolUpload],
            dependencies: [
                .target(name: "ChordFeature"),
                // 크래시 리포터 의존성(CrashReporterClient)의 실제 구현이 앱 타깃에 있다.
                .target(name: "ChordCore"),
                // 정적 프레임워크는 동적 라이브러리를 품을 수 없으므로,
                // 앱 타깃에서도 직접 링크해 번들에 들어가게 한다.
                .package(product: "GoogleMobileAds"),
                // Crashlytics는 UI도 도메인도 아닌 앱 수명주기 인프라라 앱 타깃에만 붙인다.
                .package(product: "FirebaseCrashlytics"),
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
