// SPDX-License-Identifier: EUPL-1.2

//
//  VersionService.swift
//  edim
//
//  Created by Matīss Mamedovs on 13/05/2026.
//

import Moya
import Foundation

final public class VersionService: Sendable {
    public static let shared = VersionService()
    
    @MainActor public func getVersionConfig(completionCallback: @escaping(AppVersionConfigResponse?) -> ()) {
        AppApiProvider.shared.provider.request(.getVersionConfig, completion: {  [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                self.parsePersonData(response: response, completionCallback: completionCallback)
            case .failure:
                completionCallback(nil)
            }
        })
    }
    
    private func parsePersonData(response: Response, completionCallback: @escaping(AppVersionConfigResponse?) -> ()) {
        if let data = try? JSONDecoder().decode(AppVersionConfigResponse.self, from: response.data) {
            completionCallback(data)
        } else {
            completionCallback(nil)
        }
    }
}


public struct AppVersionConfigResponse: Codable {
    let platforms: Platforms?
}

public struct Platforms: Codable {
    let ios: IOSVersionConfig?
}

public struct IOSVersionConfig: Codable {
    let minRequiredVersion: String?
    let latestVersion: String?
    let storeUrl: String?

    enum CodingKeys: String, CodingKey {
        case minRequiredVersion = "min_required_version"
        case latestVersion = "latest_version"
        case storeUrl = "store_url"
    }
}
