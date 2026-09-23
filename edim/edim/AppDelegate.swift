// SPDX-License-Identifier: EUPL-1.2

//
//  AppDelegate.swift
//  edim
//
//  Created by Matīss Mamedovs on 01/11/2024.
//

import UIKit
import UtilitiesPackage
import OpenID4VCI
import EudiWalletKit
import FirebaseCore
import FirebaseCrashlytics
#if canImport(FirebaseAnalytics)
// Only the production `edim` target links FirebaseAnalytics; `edim-dev` does not,
// so this import is conditional to keep both flavours compiling from one source.
import FirebaseAnalytics
#endif

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var FIRST_LOAD: String = "FIRST_LOAD"
    static var INSTANCE_ID: String = "INSTANCE_ID"
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
        Self.configureAnalyticsCollection()
        
        AppDelegateHelper.shared.setUpNavigationBar()
        if SessionData.shared.hasDeeplinkFilePath() {
            SessionData.shared.setDeeplinkFilePath()
            SessionData.shared.cleanDeeplinkUserDefaults()
        }
                
        let set: String? = UserDefaultsManager.shared.get(key: FIRST_LOAD) ?? nil
        if set == nil {
            Task {
                // delete wscd key id when new install
                AppSecurityLayer.shared.deleteKeyID(completion: {_ in})
                await WalletInstance.shared.deleteAllDocuments()
            }
            UserDefaultsManager.shared.set(value: Language.en.rawValue, key: AppDestination.LANGUAGE_CODE)
            UserDefaultsManager.shared.set(value: "set", key: FIRST_LOAD)
        }
        
        let instanceID: String? = UserDefaultsManager.shared.get(key: AppDelegate.INSTANCE_ID) ?? nil
        if instanceID == nil {
            UserDefaultsManager.shared.set(value: UUID().uuidString, key: AppDelegate.INSTANCE_ID)
        }

        
        BaseInjector.shared.flowInjector = AppFlowConfigurator.shared
        return true
    }
    
    private static func configureAnalyticsCollection() {
        #if canImport(FirebaseAnalytics)
        let enabled = AppEnvironment.isProduction
        Analytics.setAnalyticsCollectionEnabled(enabled)
        AppLog.debug("Analytics collection enabled: \(enabled) (\(AppEnvironment.current.rawValue))")
        #endif
    }
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}
