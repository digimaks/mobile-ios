// SPDX-License-Identifier: EUPL-1.2

//
//  Data+Base64URL.swift
//  edim
//
//  Created by Matīss Mamedovs on 22/09/2025.

import Foundation

extension Data {
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
