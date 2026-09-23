// SPDX-License-Identifier: EUPL-1.2

//
//  SettingsDestionation.swift
//  edim
//
//  Created by Matīss Mamedovs on 31/01/2025.
//

import AuthWrapperPackage
import Foundation
import UtilitiesPackage

final class SettingsDestionation: Destination, Sendable {
    
    fileprivate var passcode: String = ""
    
    public static let shared = SettingsDestionation()
    
    public override init() {
        super.init()
    }
    
    override func start() {
        Task {
            guard let localInit = await self.local else {
                return
            }
            
            switch localInit.funcName {
            case .setLanguage:
                await self.setLanguage(localInit: localInit)
            case .deleteWallet:
                await self.deleteWallet(localInit: localInit)
            default:
                break
            }
        }
        
    }
    
    public func savePasscode(passcode: String) {
        self.passcode = passcode
    }
}

extension SettingsDestionation {
    fileprivate func setLanguage(localInit: LocalInitObject) async {
        if let params = localInit.params?["language"] as? String {
            let lang = Language(rawValue: params) ?? .lv
            Texts.lang = lang
            WalletInstance.shared.setUiCulture(lang.rawValue)
            await WalletInstance.shared.loadDocuments()
            UserDefaultsManager.shared.set(value: params, key: AppDestination.LANGUAGE_CODE)
            if let local = self.local {
                Task {
                    await self.inject(id: local.id, status: .SUCCESS, message: nil, data: nil as String?)
                }
            }
        }
        
    }
    
    fileprivate func deleteWallet(localInit: LocalInitObject) async {
        do {
            let success = try await BiometricsManager.shared.evaluatePolicyWithPasscode()
            Task {
                if success {
                    if await WalletInstance.shared.deleteAllDocuments() {
                        RealmManager.shared.deleteSignatures()
                        RealmManager.shared.deleteTransactions()
                        AppSecurityLayer.shared.deleteKeyID(completion: {_ in})
                        UserDefaultsManager.shared.remove(key: OnboardingDestination.MAIN_PID_ISSUED)
                        if let local = self.local {
                            Task {
                                await self.inject(id: local.id, status: success ? .SUCCESS : .ERROR, message: nil, data: nil as String?)
                            }
                        }
                    } else {
                        if let local = self.local {
                            Task {
                                await self.inject(id: local.id, status: .ERROR, message: nil, data: nil as String?)
                            }
                        }
                    }
                }
            }
        } catch {
            AppLog.error(error)
        }
    }
}

extension SettingsDestionation: BiometryEnded {
    nonisolated func biometryEnded(didChange: Bool) {
        Task {
            if let local = await self.local {
                await self.inject(id: local.id, status: didChange ? .SUCCESS : .ERROR, message: nil, data: nil as String?)
            }
        }
    }
}

public struct BiometryAvailability: Codable, Sendable {
    public var data: [String: String?]
    
    enum CodingKeys: String, CodingKey {
        case data = "data"
    }
}

public protocol BiometryEnded: NSObject, Sendable {
    func biometryEnded(didChange: Bool)
}
