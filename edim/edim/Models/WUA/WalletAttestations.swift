// SPDX-License-Identifier: EUPL-1.2

//
//  WalletAttestations.swift
//  edim
//
//  Created by Matīss Mamedovs on 10/11/2025.
//


public struct WalletAttestations: Codable, Sendable {
    public var walletAttestations: [WalletAttestation]

    enum CodingKeys: String, CodingKey {
        case walletAttestations = "wallet_attestations"
    }
}

public struct WalletAttestation: Codable, Sendable {
    public var format: String
    public var walletAttestation: String

    enum CodingKeys: String, CodingKey {
        case format = "format"
        case walletAttestation = "wallet_attestation"
    }
}
