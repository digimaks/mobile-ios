// SPDX-License-Identifier: EUPL-1.2

//
//  ElectronicSignature.swift
//  edim
//
//  Created by Matīss Mamedovs on 17/03/2025.
//


public struct ElectronicSignature: Codable, Sendable {
    public var eSeal: [ElectronicSignatureItem]
    public var eSign: [ElectronicSignatureItem]
}

public struct ElectronicSignatureItem: Codable, Sendable {
    public var Sid: String
    public var cn: String
    public var expiresOn: String
    public var issuedOn: String
    
    enum CodingKeys: String, CodingKey {
        case Sid = "Sid"
        case cn = "cn"
        case expiresOn = "ExpiresOn"
        case issuedOn = "IssuedOn"
    }
    
    public init(Sid: String, cn: String, expiresOn: String, issuedOn: String) {
        self.Sid = Sid
        self.cn = cn
        self.expiresOn = expiresOn
        self.issuedOn = issuedOn
    }
}
