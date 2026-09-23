// SPDX-License-Identifier: EUPL-1.2

//
//  CookiesHelper.swift
//  edim
//
//  Created by Matīss Mamedovs on 21/03/2025.
//

import WebKit

extension WKWebView {

    func cleanAllCookies() {
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        AppLog.debug("All cookies deleted")

        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            records.forEach { record in
                WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
                AppLog.debug("Cookie ::: \(record) deleted")
            }
        }
    }

    func refreshCookies() {
        self.configuration.processPool = WKProcessPool()
    }
}
