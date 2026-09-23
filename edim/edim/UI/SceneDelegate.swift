// SPDX-License-Identifier: EUPL-1.2

//
//  SceneDelegate.swift
//  edim
//
//  Created by Matīss Mamedovs on 01/11/2024.
//

import UIKit
import NetworkWrapperPackage
import AuthWrapperPackage
import DeviceInformationPackage
import UtilitiesPackage

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
        
    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {

        AppApiProvider.shared.provider.delegate = self
        WalletInstance.shared.setUp()

        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        self.window = window

        if DeviceInfoManager.shared.canEnterApp() {
            VersionService.shared.getVersionConfig { config in
                DispatchQueue.main.async {
                    let hasMainPid: Bool = UserDefaultsManager.shared.get(key: OnboardingDestination.MAIN_PID_ISSUED) ?? false
                    let rootViewController: UIViewController
                    
                    let res = VersionHelper.shared.checkAppUpdate(result: config)
                    
                    switch res {
                    case .mandatory(let storeUrl):
                        rootViewController = DepricatedVersionViewController(storeURL: storeUrl)
                    default:
                        if hasMainPid {
                            rootViewController = FastLoginViewController(isRelogin: false)
                        } else {
                            rootViewController = ContentViewController(params: "")
                        }
                    }

                    

                    let navigationController = UINavigationController(rootViewController: rootViewController)

                    window.rootViewController = navigationController
                    window.makeKeyAndVisible()
                }
            }

        } else {
            let unsecure = DeviceInfoManager.shared.isUnsafeDevice()
            let rootViewController = RootedDeviceViewController(type: unsecure ? .rooted : .passcode)
            let navigationController = UINavigationController(rootViewController: rootViewController)

            window.rootViewController = navigationController
            window.makeKeyAndVisible()
        }

        if let url = connectionOptions.urlContexts.first?.url,
           url.scheme == "openid-vp" {
            AppLog.debug("Handling pending deeplink")
            
            DeepLinkCoordinator.shared.storePresentationDeeplink(url.absoluteString)
            if let source = connectionOptions.urlContexts.first?.options.sourceApplication {
                DeepLinkCoordinator.shared.storePresentingAppSource(source)
            }
        }
    }
    
    var backgroundEnteredAt: Date?
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        backgroundEnteredAt = Date()
        AppLog.debug("App entered background at \(backgroundEnteredAt!)")
        addOverlay()
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        if let backgroundTime = backgroundEnteredAt {
            let elapsed = Date().timeIntervalSince(backgroundTime)
            AppLog.debug("App was in background for \(elapsed) seconds")
            
            if elapsed > 60 {
                // Logout or force re-authentication
                let vc = FastLoginViewController(isRelogin: true)
                vc.modalPresentationStyle = .overCurrentContext
                self.window?.rootViewController?.present(vc, animated: true)
            }
        }
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        removeOverlay()
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let url = URLContexts.first?.url, url.scheme == "openid-credential-offer" {
            AppLog.debug(url.absoluteString)
            Task {
                let model = await WalletInstance.shared.qrcodeIssue(uri: url.absoluteString)
                AppLog.debug(url.scheme)
            }
        } else if let url = URLContexts.first?.url, url.scheme == "openid-vp" || url.scheme == "openid4vp" {
            if let url = URLContexts.first?.url {
                DeepLinkCoordinator.shared.storePresentationDeeplink(url.absoluteString)
                if let source = URLContexts.first?.options.sourceApplication {
                    DeepLinkCoordinator.shared.storePresentingAppSource(source)
                }
            }
        } else {
            if SessionData.shared.hasDeeplinkFilePath() {
                SessionData.shared.setDeeplinkFilePath()
                SessionData.shared.cleanDeeplinkUserDefaults()
                
                NotificationCenter.default.post(name: Notification.Name(SessionData.DEEPLINK_NOTIFICATION_NAME), object: nil)
            }
        }
        
    }

    let SPLASH_VIEW_TAG: Int = 999
    
    func addOverlay() {
        var view = self.window?.viewWithTag(SPLASH_VIEW_TAG) as? OverlayScreenView
        if view == nil {
            view = OverlayScreenView()
            view?.tag = 999
            
            if let view = view {
                self.window?.addSubview(view)
                
                view.snp.makeConstraints { make in
                    make.edges.equalToSuperview()
                }
            }
        }
    }
    
    func removeOverlay() {
        let view = self.window?.viewWithTag(SPLASH_VIEW_TAG) as? OverlayScreenView
        view?.removeFromSuperview()
    }
    
    
}

extension SceneDelegate: CommonServiceManagerProtocol {
    nonisolated func requestCompleted() {}
    nonisolated func requestFailed() {}
    nonisolated func unauthorizedError() {}
    nonisolated func criticalError() {}
    nonisolated func unrecognizedError(code: String) {}
    nonisolated func versionUpdateError(code: String) {}
}
