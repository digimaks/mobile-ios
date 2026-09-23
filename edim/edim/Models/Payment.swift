// SPDX-License-Identifier: EUPL-1.2

//
//  Payment.swift
//  edim
//
//  Created by Matīss Mamedovs on 11/06/2025.
//

import Foundation
import UIKit

public struct Payment: Codable {
    public var type: String
    public var credentialIds: [String]
    public var transactionDataHashesAlg: [String]
    public var paymentId: String
    public var creditorAccount: CreditorAccount
    public var instructedAmount: Float
    public var currency: String
    public var creditor: String
    public var purpose: String

    
    enum CodingKeys: String, CodingKey {
        case type = "type"
        case credentialIds = "credential_ids"
        case transactionDataHashesAlg = "transaction_data_hashes_alg"
        case paymentId = "payment_id"
        case creditorAccount = "creditor_account"
        case instructedAmount = "instructed_amount"
        case currency = "currency"
        case creditor = "creditor"
        case purpose = "purpose"
    }
}

public struct CreditorAccount: Codable {
    public var iban: String
}
