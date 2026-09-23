// SPDX-License-Identifier: EUPL-1.2

//
//  SignFile.swift
//  edim
//
//  Created by Matīss Mamedovs on 11/06/2025.
//

public struct Signer: Codable, Sendable {
    var name: String
    var signedAt: String
    var type: String
}

public struct SignedFile: Codable, Sendable {
    var name: String
}
