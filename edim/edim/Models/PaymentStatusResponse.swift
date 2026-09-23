// SPDX-License-Identifier: EUPL-1.2

//
//  PaymentStatusResponse.swift
//  edim
//
//  Created by Matīss Mamedovs on 04/06/2025.
//


public struct PaymentStatusResponse: Codable {
    var paymentStatus: String
    
    enum CodingKeys: String, CodingKey {
        case paymentStatus = "payment_status"
    }
}
