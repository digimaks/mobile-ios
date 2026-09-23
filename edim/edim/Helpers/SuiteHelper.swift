// SPDX-License-Identifier: EUPL-1.2

//
//  SuiteHelper.swift
//  edim
//
//  Created by Matīss Mamedovs on 03/04/2025.
//

import Foundation

final public class SuiteHelper: Sendable {
    public static let shared = SuiteHelper()

    private static let sharedAppGroup = "group.lv.zzdats.edim.share1"

    public func getSuiteName() -> String {
        let bundleID = Bundle.main.bundleIdentifier

        switch bundleID {
        case "lv.zzdats.edim",      // edim      (production)
             "lv.zzdats.edim.dev1": // edim-dev  (development)
            return Self.sharedAppGroup
        default:
            AppLog.error("No App Group mapped for bundle identifier: \(bundleID ?? "nil")")
            return ""
        }
    }
}
