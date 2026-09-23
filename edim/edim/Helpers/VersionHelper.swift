// SPDX-License-Identifier: EUPL-1.2

//
//  VersionHelper.swift
//  edim
//
//  Created by Matīss Mamedovs on 13/05/2026.
//

import Foundation

final class VersionHelper {

    @MainActor static let shared = VersionHelper()

    private init() {}

    enum AppUpdateStatus {
        case upToDate
        case recommended(storeUrl: String, latestVersion: String)
        case mandatory(storeUrl: String)
        case error
    }

    func checkAppUpdate(result: AppVersionConfigResponse?) -> AppUpdateStatus {

        guard let config = result?.platforms?.ios else {
            return .error
        }

        let appVersion =
            Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            ?? "1.0"

        let storeUrl = config.storeUrl ?? ""
        let minRequired = config.minRequiredVersion
        let latest = config.latestVersion

        // Mandatory update
        if let minRequired = minRequired,
           !minRequired.isEmpty,
           isVersionOlder(current: appVersion, target: minRequired) {
            return .mandatory(storeUrl: storeUrl)
        }

        // Recommended update
        if let latest = latest,
           !latest.isEmpty,
           isVersionOlder(current: appVersion, target: latest) {
            return .recommended(
                storeUrl: storeUrl,
                latestVersion: latest
            )
        }

        // 3. Up-to-date (FIXED)
        return .upToDate
    }

    private func normalizeToThree(_ version: String) -> [Int] {
        let parts = version
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: ".")
            .compactMap { Int($0) }

        return (parts + [0, 0, 0]).prefix(3).map { $0 }
    }

    private func isVersionOlder(current: String, target: String) -> Bool {
        let c = normalizeToThree(current)
        let t = normalizeToThree(target)

        return c.lexicographicallyPrecedes(t)
    }


}
