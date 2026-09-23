// SPDX-License-Identifier: EUPL-1.2

//
//  EparakstsHelper.swift
//  edim
//
//  Created by Matīss Mamedovs on 08/07/2026.
//
import Foundation
import UIKit

@MainActor
public struct EparakstsHelper {
    public static let shared = EparakstsHelper()
    
    public func canOpenLocallyEparaksts() -> Bool {
        if let url1 = URL(string: "eparakstsid://"), let url2 = URL(string: "eparakstsid-demo://") {
            if UIApplication.shared.canOpenURL(url1) || UIApplication.shared.canOpenURL(url2) {
                return true
            } else {
                return false
            }
        }
        
        return false
    }
}
