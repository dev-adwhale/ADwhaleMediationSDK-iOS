import UIKit

/// 전면 / 리워드 / 앱오프닝 / 팝업 광고의 `show(from:)` 에 넘길 ViewController 를 찾는다.
///
/// SwiftUI 에는 `UIViewController` 개념이 노출되지 않으므로 UIKit 계층에서 직접 꺼내야 한다.
///
/// ## 요구사항
/// SDK 는 `viewController.view.window != nil` 인 VC 만 받는다.
/// 이미 dismiss 된 VC 를 넘기면 `didFailToShowWithError`(statusCode 200,
/// "ViewController is not in window hierarchy.") 가 돌아온다.
enum TopViewController {

    /// 현재 화면 최상단 ViewController.
    static func find() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
            ?? UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first

        guard let root = scene?.keyWindow?.rootViewController else {
            return nil
        }
        return topMost(of: root)
    }

    private static func topMost(of viewController: UIViewController) -> UIViewController {
        if let presented = viewController.presentedViewController {
            return topMost(of: presented)
        }
        if let nav = viewController as? UINavigationController, let visible = nav.visibleViewController {
            return topMost(of: visible)
        }
        if let tab = viewController as? UITabBarController, let selected = tab.selectedViewController {
            return topMost(of: selected)
        }
        return viewController
    }
}
