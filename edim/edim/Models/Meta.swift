// SPDX-License-Identifier: EUPL-1.2

//
//  Meta.swift
//  edim
//
//  Created by Matīss Mamedovs on 03/02/2025.
//

public struct Meta: Codable, Sendable {
    public var id: String
    public var documentIdentifier: String
    public var issuerDisplay: IssuerDisplay
    public var documentDisplay: DocumentDisplay
    public var status: String
    public var hasExpired: Bool
    public var isFavorite: Bool
    public var expirationDate: String
    public var issuanceDate: String
    public var issuanceMethod: String
}

public struct IssuerDisplay: Codable, Sendable {
    public var name: String
    public var issuingAuthority: String
    public var issuingCountry: String
    public var logo: DisplayLogo
}

public struct DocumentDisplay: Codable, Sendable {
    public var name: String
    public var backgroundColor: String?
    public var backgroundImageUri: String?
    public var textColor: String?
    public var description1: String?
    public var description2: String?
    public var logo: DisplayLogo
}

public struct DisplayLogo: Codable, Sendable {
    public var altText: String
    public var uri: String
}
