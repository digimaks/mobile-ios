// SPDX-License-Identifier: EUPL-1.2

//
//  Nonce.swift
//  edim
//
//  Created by Matīss Mamedovs on 27/10/2025.
//

public struct Nonce: Codable, Sendable {
    public var nonce: String

    enum CodingKeys: String, CodingKey {
        case nonce = "c_nonce"
    }
}
