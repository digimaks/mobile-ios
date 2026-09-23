// SPDX-License-Identifier: EUPL-1.2

//
//  AppEnvironment.swift
//  edim
//
//  Created by Matīss Mamedovs on 21/11/2024.

import Foundation

enum AppEnvironment: String, Sendable {
    case production
    case development
    
    /// Executable name of the running target, e.g. "edim" or "edim-dev".
    static var targetName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleExecutable") as? String ?? ""
    }
    
    /// Resolved from the running target.
    ///
    /// Note the deliberately conservative default: anything we do not explicitly
    /// recognise is treated as `production`, so an unknown/renamed target can never
    /// silently gain development trust anchors or development backends.
    static var current: AppEnvironment {
        switch targetName {
        case "edim":
            return .production
        case "edim-dev":
            return .development
        default:
            return .production
        }
    }
    
    static var isProduction: Bool {
        current == .production
    }
    
    /// Name of the `Base-*.plist` describing the backend for this flavour.
    static var baseConfigurationPlistName: String {
        switch current {
        case .production:
            return "Base-Prod"
        case .development:
            return "Base-Dev"
        }
    }
}
