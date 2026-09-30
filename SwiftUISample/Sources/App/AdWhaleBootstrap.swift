import Foundation
import SwiftUI
import AppTrackingTransparency

import AdWhaleSDK
// 사용할 광고 네트워크의 어댑터만 import 하고 register() 하면 된다.
// 여기서는 샘플이라 배포되는 4종을 모두 등록한다.
import AdWhaleAdMobAdapter
import AdWhaleCaulyAdapter
import AdWhaleAdFitAdapter
import AdWhaleAdmizeAdapter
import AdWhaleLevelPlayAdapter

/// SDK 초기화를 담당하는 옵저버블 컨트롤러.
///
/// ## 핵심 순서
/// ```
/// ATT 권한 요청  →  어댑터 register()  →  AdWhaleMediationAds.initialize()
/// ```
/// - ATT 를 먼저 띄우는 이유: SDK 는 `ATTrackingManager` 상태를 "확인만" 하고
///   팝업은 앱이 직접 띄운다. 초기화 이후에 허용을 받으면 그 세션의 첫 광고 요청은
///   IDFA 없이 나간다.
/// - `register()` 를 빠뜨리면 해당 네트워크가 워터폴에서 통째로 건너뛰어진다.
/// - `initialize()` 없이 광고를 로드하면 전부 초기화 실패(statusCode 200)로 떨어진다.
///
/// > Publisher UID 는 `Info.plist` 의 `net.adwhale.sdk.mediation.PUBLISHER_UID` 에서 읽는다.
/// > 코드로 넘기려면 `initialize(publisherUid:completion:)` 오버로드를 쓴다.
final class AdWhaleBootstrap: ObservableObject {
    static let shared = AdWhaleBootstrap()

    @Published private(set) var isInitialized = false
    @Published private(set) var lastMessage = "초기화 전"

    private var didRegisterAdapters = false
    private var didStart = false

    private init() {}

    /// 앱 시작 시 1회 호출.
    func start() {
        guard !didStart else { return }
        didStart = true

        // 연동 중에는 verbose 로 두면 워터폴 진행 상황이 전부 보인다.
        // 운영 빌드에서는 .error 또는 .none 을 권장한다.
        AdWhaleLog.setLogLevel(.verbose)

        requestTrackingAuthorizationIfNeeded { [weak self] in
            guard let self else { return }
            self.registerAdapters()
            AdWhaleMediationAds.initialize { [weak self] statusCode, message in
                self?.update(statusCode: statusCode, message: message)
            }
        }
    }

    /// 메인 화면에서 입력한 Publisher UID 로 다시 초기화한다.
    ///
    /// Android 샘플에서 `etMediaUid` 값을 `PUBLISHER_UID` 메타데이터에 밀어 넣던 동작에 대응한다.
    /// iOS 에서는 `Info.plist` 를 런타임에 바꿀 수 없으므로 파라미터 오버로드를 쓴다.
    /// (파라미터가 `Info.plist` 보다 우선하고, 공백이면 `Info.plist` 로 폴백한다)
    func reinitialize(publisherUid: String) {
        registerAdapters()
        AdWhaleMediationAds.initialize(publisherUid: publisherUid) { [weak self] statusCode, message in
            self?.update(statusCode: statusCode, message: message)
        }
    }

    // MARK: - 내부

    /// 어댑터 등록은 앱 생애 중 한 번이면 된다.
    private func registerAdapters() {
        guard !didRegisterAdapters else { return }
        didRegisterAdapters = true

        AdWhaleAdMobAdapterRegistrar.register()   // AdMob / Ad Manager
        AdWhaleCaulyAdapterRegistrar.register()   // Cauly
        AdWhaleAdFitAdapterRegistrar.register()   // AdFit (팝업 광고는 AdFit 전용)
        AdWhaleAdmizeAdapterRegistrar.register()  // Admize
        AdWhaleLevelPlayAdapterRegistrar.register() // LevelPlay
        adlog("어댑터 register() 완료 — AdMob / Cauly / AdFit / Admize / LevelPlay")
    }

    private func update(statusCode: Int, message: String) {
        let succeeded = (statusCode == AdWhaleResultCode.internalSuccess.rawValue)
        let text = "onInitComplete(\(statusCode), \(message))"
        adlog("SDK \(text)")
        DispatchQueue.main.async {
            self.isInitialized = succeeded
            self.lastMessage = text
        }
    }

    /// iOS 14+ ATT 권한 요청. 이미 결정된 상태면 바로 다음 단계로 넘어간다.
    private func requestTrackingAuthorizationIfNeeded(completion: @escaping () -> Void) {
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else {
            adlog("ATT 상태: \(Self.attStatusName)")
            completion()
            return
        }
        // 앱이 foreground 로 올라오기 전에 요청하면 팝업이 무시될 수 있어 약간 지연시킨다.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            ATTrackingManager.requestTrackingAuthorization { _ in
                adlog("ATT 응답: \(Self.attStatusName)")
                DispatchQueue.main.async { completion() }
            }
        }
    }

    private static var attStatusName: String {
        switch ATTrackingManager.trackingAuthorizationStatus {
        case .authorized:    return "authorized"
        case .denied:        return "denied"
        case .restricted:    return "restricted"
        case .notDetermined: return "notDetermined"
        @unknown default:    return "unknown"
        }
    }
}
