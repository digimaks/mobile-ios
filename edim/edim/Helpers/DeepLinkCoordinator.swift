// SPDX-License-Identifier: EUPL-1.2

//
//  DeepLinkCoordinator.swift
//  edim
//
//  Created by Matīss Mamedovs on 23/04/2026.
//

import UIKit

@MainActor
final class DeepLinkCoordinator: Sendable {

    @MainActor static let shared = DeepLinkCoordinator()

    private init() {}

    private var pendingPresentationDeeplink: String?
    private var pendingSourceApp: String?

    func storePresentationDeeplink(_ deeplink: String) {
        pendingPresentationDeeplink = deeplink
        AppLog.debug("Stored pending presentation deeplink")
    }
    
    func storePresentingAppSource(_ source: String) {
        pendingSourceApp = source
    }

    func consumePresentationDeeplink() -> String? {
        defer { pendingPresentationDeeplink = nil }
        return pendingPresentationDeeplink
    }
    
    func consumeAppSource() -> String? {
        defer { pendingSourceApp = nil }
        return pendingSourceApp
    }


    func hasPendingPresentationDeeplink() -> Bool {
        return pendingPresentationDeeplink != nil
    }
}
