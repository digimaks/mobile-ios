// SPDX-License-Identifier: EUPL-1.2

//
//  CheckTokenResponse.swift
//  edim
//
//  Created by Matīss Mamedovs on 20/03/2025.
//


public struct CheckTokenResponse: Codable {
    var active: Bool
    
    enum CodingKeys: String, CodingKey {
        case active = "active"
    }
}
