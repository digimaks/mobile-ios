// SPDX-License-Identifier: EUPL-1.2

//
//  WalletPropertyReader.swift
//  edim
//
//  Created by Matīss Mamedovs on 11/11/2024.
//

import Foundation

final class WalletPropertyReader: Sendable {
    static let shared = WalletPropertyReader()
    
    @MainActor func getIssuerUrl() -> String {
        return AppApiProvider.shared.getBaseURL() + (getPlist()?["IssuerURL"] as? String ?? "")
    }
    
    func getClientID() -> String {
        return getPlist()?["ClientID"] as? String ?? ""
    }
    
    func getRedirectURI() -> String {
        return getPlist()?["RedirectURI"] as? String ?? ""
    }
    
    func getAuthRequired() -> Bool {
        return getPlist()?["AuthRequired"] as? Bool ?? false
    }
}

extension WalletPropertyReader {
    func getPlist() -> [String: Any]? {
        AppConfiguration.walletInfo
    }
}
