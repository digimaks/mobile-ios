// SPDX-License-Identifier: EUPL-1.2

//
//  AppApiProvider.swift
//  edim
//
//  Created by Matīss Mamedovs on 21/11/2024.
//
import Foundation
import NetworkWrapperPackage
import Moya

public class AppApiProvider: ApiProvider {
    
    @MainActor public static let shared = AppApiProvider()
    
    public override init() { super.init() }
    
    fileprivate static var loggingPlugins: [PluginType] {
        #if DEBUG
        return [NetworkLoggerPlugin(configuration: NetworkLoggerPlugin.Configuration(logOptions: .verbose))]
        #else
        return []
        #endif
    }
    
    public let provider = RefreshbleMoyaProvider<ApiService>(plugins: AppApiProvider.loggingPlugins)

    @MainActor fileprivate func endpoint(_ key: String) -> String {
        guard let path = AppConfiguration.backend?[key] as? String else {
            return ""
        }
        
        return getBaseURL() + path
    }
    
    @MainActor public func getApiClientID() -> String {
        AppConfiguration.apiClientID
    }
    
    @MainActor public func getBaseURL() -> String {
        AppConfiguration.base?["BaseURL"] as? String ?? ""
    }
    
    @MainActor public func getPersonBackendBase() -> String {
        endpoint("PersonBaseURL")
    }
    
    @MainActor public func getWalletBackendBase() -> String {
        endpoint("WalletBaseURL")
    }
    
    @MainActor public func getSessionBackendBase() -> String {
        endpoint("SessionBaseURL")
    }
    
    @MainActor public func getEparakstsAuth() -> String {
        endpoint("EparakstsAuth")
    }
    
    @MainActor public func getEparakstsWalletBackendBase() -> String {
        endpoint("EparakstsWalletBaseUrl")
    }
    
    @MainActor public func getIDAuthBackendBase() -> String {
        endpoint("IDAuthBaseURL")
    }
}

