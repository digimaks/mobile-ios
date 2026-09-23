// SPDX-License-Identifier: EUPL-1.2

//
//  DrivingPrivilege.swift
//  edim
//
//  Created by Matīss Mamedovs on 11/06/2025.
//

public struct DrivingPrivilege: Codable {
    var vehicleCategoryCode: String
    var issueDate: String
    var expiryDate: String
    
    enum CodingKeys: String, CodingKey {
        case vehicleCategoryCode = "vehicle_category_code"
        case issueDate = "issue_date"
        case expiryDate = "expiry_date"
    }
}
