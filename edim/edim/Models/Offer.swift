// SPDX-License-Identifier: EUPL-1.2

//
//  Offer.swift
//  edim
//
//  Created by Matīss Mamedovs on 11/06/2025.
//


public struct ResolveOfferLocalResponseObject: Codable {
    public var documents: [[String: String]]
    public var issuerName: String
    public var txCodeLength: Int?
}

public struct OfferCodeLocalResponseObject: Codable {
    public var offerUri: String
    public var issuerName: String
    public var txCodeLength: Int
    
}

public enum OpenIDPresentationScheme: String, CaseIterable {
    case openid4VP = "openid4vp"
    case openidVP = "openid-vp"
    case mDocOpenID4VP = "mdoc-openid4vp"
    case eudiOpenID4VP = "eudi-openid4vp"
}

public enum CredentialOfferIssuanceScheme: String, CaseIterable {
    case eudiWallet = "eudi-wallet"
    case openIDCredentialOffer = "openid-credential-offer"
    case haipVCI = "haip-vci"
}
