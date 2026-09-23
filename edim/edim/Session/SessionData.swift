// SPDX-License-Identifier: EUPL-1.2

//
//  SessionData.swift
//  edim
//
//  Created by Matīss Mamedovs on 16/01/2025.
//

import Foundation
import AuthWrapperPackage
import UtilitiesPackage

@MainActor
final public class SessionData: Sendable {
    
    public static let shared = SessionData()
    public static let ShareExtensionKey = "ShareCommonExtension"
    public static let DEEPLINK_NOTIFICATION_NAME: String = "DEEPLINK_NOTIFICATION_NAME"
    
    @MainActor fileprivate var authToken: String?
    @MainActor fileprivate var deeplinkFilePath: String?
    
    @MainActor public func setAuthToken(_ authToken: String) {
        PasscodeManager.shared.storeSessionToken(token: authToken, completion: {_ in })
        self.authToken = authToken
    }
    
    @MainActor public func getAuthToken() -> String? {
        do {
            return try PasscodeManager.shared.getSessionToken()
        } catch {
            return nil
        }
    }
    
    public func deleteWallet(completion: @escaping (Bool) -> Void) async {
        await PasscodeManager.shared.clearAllData(completion: { success in
            Task {
                if await WalletInstance.shared.deleteAllDocuments() {
                    RealmManager.shared.deleteTransactions()
                    completion(success)
                } else {
                    completion(false)
                }
            }
            
        })
    }
    
    public func getDeeplinkFilePath() -> String? {
        return self.deeplinkFilePath
    }
    
    public func setDeeplinkFilePath() {
        self.deeplinkFilePath = UserDefaultsManager.shared.getValueFromSuite(suiteName: SuiteHelper.shared.getSuiteName(), key: SessionData.ShareExtensionKey)
    }
    
    public func removeDeeplinkFilePath() {
        self.deeplinkFilePath = nil
    }
    
    public func cleanDeeplinkUserDefaults() {
        UserDefaultsManager.shared.remove(key: DOWNLOAD_DESTINATION)
        UserDefaultsManager.shared.remove(suiteName: SuiteHelper.shared.getSuiteName(), key: SessionData.ShareExtensionKey)
    }
    
    public func hasDeeplinkFilePath() -> Bool {
        let val: String? = UserDefaultsManager.shared.getValueFromSuite(suiteName: SuiteHelper.shared.getSuiteName(), key: SessionData.ShareExtensionKey)
        return val != nil
    }
}
