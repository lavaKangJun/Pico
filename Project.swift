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

/// SKAdNetwork 허용 목록. 여기 적힌 네트워크만 애플에서 설치 성과(postback)를 받는다.
///
/// 빠진 네트워크는 성과를 못 보니 입찰을 낮추거나 아예 빠진다. 앱이 고장나는 게 아니라
/// 수익이 깎이는 문제다. 구글이 공개한 목록을 그대로 옮겼다. (2026-01-30 기준 50개)
/// https://developers.google.com/admob/ios/3p-skadnetworks
///
/// 중개하는 네트워크가 늘면 목록도 바뀐다. 앱을 올릴 때마다 위 문서와 맞춰 본다.
private let skAdNetworkIdentifiers = [
    "cstr6suwn9.skadnetwork", // Google
    "4fzdc2evr5.skadnetwork", // Aarki
    "2fnua5tdw4.skadnetwork", // Adform
    "ydx93a7ass.skadnetwork", // Adikteev
    "p78axxw29g.skadnetwork", // Amazon
    "v72qych5uu.skadnetwork", // Appier
    "ludvb6z3bs.skadnetwork", // Applovin
    "cp8zw746q7.skadnetwork", // Arpeely
    "3sh42y64q3.skadnetwork", // Basis
    "c6k4g5qg8m.skadnetwork", // Beeswax.io
    "s39g8k73mm.skadnetwork", // Bidease
    "wg4vff78zm.skadnetwork", // BidMachine
    "3qy4746246.skadnetwork", // Bigabid Media
    "f38h382jlk.skadnetwork", // Chartboost
    "hs6bdukanm.skadnetwork", // Criteo
    "mlmmfzh3r3.skadnetwork", // Digital Turbine DSP
    "v4nxqhlyqp.skadnetwork", // i-mobile
    "wzmmz9fp6w.skadnetwork", // InMobi
    "su67r6k2v3.skadnetwork", // ironsource Ads
    "yclnxrl5pm.skadnetwork", // Jampp
    "t38b2kh725.skadnetwork", // LifeStreet Media
    "7ug5zh24hu.skadnetwork", // Liftoff
    "gta9lk7p23.skadnetwork", // Liftoff Monetize
    "vutu7akeur.skadnetwork", // LINE Ads Network
    "y5ghdn5j9k.skadnetwork", // Mediaforce
    "v9wttpbfk9.skadnetwork", // Meta (1 of 2)
    "n38lu8286q.skadnetwork", // Meta (2 of 2)
    "47vhws6wlr.skadnetwork", // MicroAd
    "kbd757ywx3.skadnetwork", // Mintegral / Mobvista
    "9t245vhmpl.skadnetwork", // Moloco
    "a2p9lx4jpn.skadnetwork", // Opera
    "22mmun2rn5.skadnetwork", // Pangle
    "44jx6755aq.skadnetwork", // Persona.ly Ltd.
    "k674qkevps.skadnetwork", // Pubmatic
    "4468km3ulz.skadnetwork", // Realtime Technologies GmbH
    "2u9pt9hc89.skadnetwork", // Remerge
    "8s468mfl3y.skadnetwork", // RTB House
    "klf5c3l5u5.skadnetwork", // Sift Media
    "ppxm28t8ap.skadnetwork", // Smadex
    "kbmxgpxpgc.skadnetwork", // StackAdapt
    "uw77j35x4d.skadnetwork", // The Trade Desk
    "578prtvx9j.skadnetwork", // Unicorn
    "4dzt52r2t5.skadnetwork", // Unity Ads
    "tl55sbb4fm.skadnetwork", // Verve
    "c3frkrj4fj.skadnetwork", // Viant
    "e5fvkxwrpn.skadnetwork", // Yahoo!
    "8c4e2ghe7u.skadnetwork", // Yahoo! Japan Ads
    "3rd42ekr43.skadnetwork", // YouAppi
    "97r2b46745.skadnetwork", // Zemanta
    "3qcr597p9d.skadnetwork", // Zucks
]

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
                "CFBundleDisplayName": "PICO",
                "UILaunchScreen": ["UIColorName": ""],
                "UIUserInterfaceStyle": "Automatic",
                "UISupportedInterfaceOrientations": [
                    "UIInterfaceOrientationPortrait",
                ],
                "ITSAppUsesNonExemptEncryption": false,
                // 번역 리소스는 모듈 번들에 있으므로, 앱이 지원하는 언어를 여기서 알린다.
                "CFBundleLocalizations": .array(knownRegions.map { .string($0) }),
                // AdMob 콘솔에서 발급받은 실제 앱 ID. 앱 ID는 ~, 광고 단위는 /로 구분된다.
                "GADApplicationIdentifier": "ca-app-pub-4602481899762111~4950998751",
                "SKAdNetworkItems": .array(
                    skAdNetworkIdentifiers.map { .dictionary(["SKAdNetworkIdentifier": .string($0)]) }
                ),
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
