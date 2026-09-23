// SPDX-License-Identifier: EUPL-1.2

//
//  FavoriteDocument.swift
//  edim
//
//  Created by Matīss Mamedovs on 25/02/2025.
//

import RealmSwift

public class FavoriteDocument: Object, Codable {
    @Persisted var id: String
    @Persisted var documentID: String
    
    public override static func primaryKey() -> String? {
        return "id"
    }
    
    convenience init(id: String, documentId: String) {
        self.init()
        self.id = id
        self.documentID = documentId
    }
    
    enum CodingKeys: String, CodingKey {
        case id, documentID
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(documentID, forKey: .documentID)
    }
    
}
