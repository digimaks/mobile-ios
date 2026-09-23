// SPDX-License-Identifier: EUPL-1.2

//
//  SignResponse.swift
//  edim
//
//  Created by Matīss Mamedovs on 20/03/2025.
//

public struct SignResponse: Codable, Sendable {
    public var redirectUrl: String
}

public struct SignSession: Codable, Sendable {
    public var sessionId: String
    public var requestId: String
}
