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
/// 어댑터 register()  →  AdWhaleMediationAds.initialize()  →  GDPR 동의 요청(UMP)  →  광고 로드
/// ```
/// - `register()` 를 빠뜨리면 해당 네트워크가 워터폴에서 통째로 건너뛰어진다.
/// - `initialize()` 없이 광고를 로드하면 전부 초기화 실패(statusCode 200)로 떨어진다.
/// - GDPR 동의는 초기화 뒤에, 앱이 활성 상태일 때 요청한다. (EEA 밖 사용자에게는 폼이 뜨지 않는다)
/// - ATT 는 앱이 직접 띄우지 않고 AdMob UMP 에 맡긴다. AdMob 콘솔에서 IDFA 메시지를 켜 두면
///   UMP 가 동의 흐름 안에서 ATT 를 띄운다. 앱이 먼저 ATT 를 요청하면 UMP 의 동의 흐름이 멈출 수 있다.
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

        registerAdapters()
        AdWhaleMediationAds.initialize { [weak self] statusCode, message in
            self?.update(statusCode: statusCode, message: message)
        }

        // 초기화가 앱 활성화보다 먼저 끝나는 경우를 위해, 활성화될 때도 한 번 더 시도한다.
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main
        ) { [weak self] _ in
            self?.requestGdprConsentIfReady()
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
            self.requestGdprConsentIfReady()
        }
    }

    // MARK: - GDPR 동의 (UMP)

    private var didRequestGdprConsent = false

    /// 초기화가 끝났고 앱이 활성 상태일 때 한 번만 GDPR 동의를 요청한다.
    /// 동의 폼과 ATT 알림(AdMob 콘솔에서 IDFA 메시지를 켠 경우)은 UMP 가 띄운다.
    private func requestGdprConsentIfReady() {
        guard isInitialized, !didRequestGdprConsent,
              UIApplication.shared.applicationState == .active,
              let viewController = TopViewController.find() else { return }
        didRequestGdprConsent = true

        AdWhaleMediationAds.requestGdprConsent(from: viewController) { isSuccess, message in
            adlog("GDPR 동의 처리 \(isSuccess ? "완료" : "실패") (\(message)) — "
                  + "상태 \(AdWhaleMediationAds.gdprConsentStatus.rawValue), ATT \(Self.attStatusName)")
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
