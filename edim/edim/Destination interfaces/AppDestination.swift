// SPDX-License-Identifier: EUPL-1.2

//
//  AppDestination.swift
//  edim
//
//  Created by Matīss Mamedovs on 04/02/2025.
//

import DeviceInformationPackage
import UtilitiesPackage
import UIKit

final class AppDestination: Destination, Sendable {
    public static let LANGUAGE_CODE: String = "LANGUAGE_CODE"
        
    public static let shared = AppDestination()
    
    public override init() {
        super.init()
    }
    
    override func start() {
        Task {
            guard let localInit = await self.local else {
                return
            }
            
            switch localInit.funcName {
            case .getState:
                await self.getState(localInit: localInit)
            default:
                break
            }
        }
        
    }
}

extension AppDestination {
    fileprivate func getState(localInit: LocalInitObject) async {
        let doc = WalletInstance.shared.fetchMainPidDocument()
        let nameBearer = doc?.getBearersName()
        let name = (nameBearer?.first ?? "") + " " + (nameBearer?.last ?? "")
        let theme: String = DeviceInfoManager.shared.getStringTheme
        
        
        let response = StateResponse(
            language: UserDefaultsManager.shared.get(key: AppDestination.LANGUAGE_CODE) ?? "lv",
            fullName: name,
            theme: theme,
            system: "ios",
            env: "prod",
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            scaleFactor: getScaleFactor(),
            reduceMotion: UIAccessibility.isReduceMotionEnabled,
            ios: IOSSettings(
                reduceTransparency: UIAccessibility.isReduceTransparencyEnabled
            )
        )

        if let local = self.local {
            Task {
                await self.inject(id: local.id, status: .SUCCESS, message: nil, data: response)
            }
        }
    }
}

extension AppDestination {
    func getScaleFactor() -> Double {
        let category = UIApplication.shared.preferredContentSizeCategory

        switch category {
            case .extraSmall: return 1
            case .small: return 1.1
            case .medium: return 1.15
            case .large: return 1.2
            case .extraLarge: return 1.3
            case .extraExtraLarge: return 1.4
            case .extraExtraExtraLarge: return 1.5
            case .accessibilityMedium: return 1.6
            case .accessibilityLarge: return 1.7
            case .accessibilityExtraLarge: return 1.8
            case .accessibilityExtraExtraLarge: return 1.9
            case .accessibilityExtraExtraExtraLarge: return 2.0
            default: return 1.2
        }
    }
}


struct IOSSettings: Codable {
    let reduceTransparency: Bool
}

struct StateResponse: Codable {
    let language: String
    let fullName: String
    let theme: String
    let system: String
    let env: String
    let appVersion: String
    let scaleFactor: Double
    let reduceMotion: Bool
    let ios: IOSSettings
}
