// SPDX-License-Identifier: EUPL-1.2

//
//  Token.swift
//  edim
//
//  Created by Matīss Mamedovs on 10/07/2025.
//

public struct Token: Codable, Sendable {
    public var accessToken: String
    public var tokenType: String
    public var expiresIn: Int
    public var scope: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case scope = "scope"
    }
}
