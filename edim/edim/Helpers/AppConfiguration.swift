// SPDX-License-Identifier: EUPL-1.2

//
//  AppConfiguration.swift
//  edim
//
//  Created by Matīss Mamedovs on 21/11/2024.

import Foundation

enum AppConfiguration {
    
    /// Backend endpoints shared by every build flavour.
    static var backend: NSDictionary? {
        plist(named: "Backend-Edim")
    }
    
    /// Flavour-specific configuration: `Base-Prod.plist` or `Base-Dev.plist`.
    static var base: NSDictionary? {
        plist(named: AppEnvironment.baseConfigurationPlistName)
    }
    
    /// OpenID4VCI wallet configuration. The same file serves both flavours.
    static var walletInfo: [String: Any]? {
        guard let url = Bundle.main.url(forResource: "WalletInfo-Edim", withExtension: "plist") else {
            assertionFailure("""
                Missing configuration file 'WalletInfo-Edim.plist'.
                Run ./scripts/setup-config.sh from the repository root, then fill in \
                your wallet client ID and issuer settings.
                """)
            AppLog.error("Missing configuration file: WalletInfo-Edim.plist")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            return try PropertyListSerialization.propertyList(from: data,
                                                             options: [],
                                                             format: nil) as? [String: Any]
        } catch {
            AppLog.error(error)
            return nil
        }
    }
    
    static var apiClientID: String {
        base?["apiClientID"] as? String ?? ""
    }
    
    private static func plist(named name: String) -> NSDictionary? {
        guard !name.isEmpty,
              let path = Bundle.main.path(forResource: name, ofType: "plist") else {
            assertionFailure("""
                Missing configuration file '\(name).plist'.
                Run ./scripts/setup-config.sh from the repository root, then fill in \
                your backend host and client IDs.
                """)
            AppLog.error("Missing configuration file: \(name).plist")
            return nil
        }
        
        return NSDictionary(contentsOfFile: path)
    }
}
