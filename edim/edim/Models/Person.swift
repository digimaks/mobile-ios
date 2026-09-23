// SPDX-License-Identifier: EUPL-1.2

//
//  Person.swift
//  edim
//
//  Created by Matīss Mamedovs on 16/01/2025.
//

public struct Person: Codable, Sendable {
    public var id: String
    public var code: String
    public var givenName: String
    public var familyName: String
    public var contacts: [Contact]
    
    public struct Contact: Codable, Sendable {
        public var type: String
        public var value: String
    }
}
