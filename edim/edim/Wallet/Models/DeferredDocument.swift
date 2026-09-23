// SPDX-License-Identifier: EUPL-1.2

//
//  DeferredDocument.swift
//  edim
//
//  Created by Matīss Mamedovs on 25/11/2024.
//

import Foundation
import MdocSecurity18013
import MdocDataTransfer18013
import MdocDataModel18013
import EudiWalletKit


public struct DeferrredDocument: DocClaimsDecodable {
    public var statusList: MdocDataModel18013.StatusList?
    public var docType: String
    public var credentialsUsageCounts: MdocDataModel18013.CredentialsUsageCounts?
    public var credentialPolicy: MdocDataModel18013.CredentialPolicy
    public var validFrom: Date?
    public var validUntil: Date?
    public var id: String
    public var createdAt: Date
    public var modifiedAt: Date?
    public var displayName: String?
    public var docClaims: [MdocDataModel18013.DocClaim]
    public var docDataFormat: MdocDataModel18013.DocDataFormat
    public var ageOverXX: [Int: Bool]
    public var display: [MdocDataModel18013.DisplayMetadata]?
    public var issuerDisplay: [MdocDataModel18013.DisplayMetadata]?
    public var credentialIssuerIdentifier: String?
    public var configurationIdentifier: String?
    public var secureAreaName: String?
}
