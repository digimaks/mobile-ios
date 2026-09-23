// SPDX-License-Identifier: EUPL-1.2

//
//  Transaction.swift
//  edim
//
//  Created by Matīss Mamedovs on 20/02/2025.
//

import RealmSwift

public class Transaction: Object, Codable {
    @Persisted var id: String
    @Persisted var documentId: String
    @Persisted var docType: String
    @Persisted var nameSpace: String
    @Persisted var timestamp: Int
    @Persisted var status: String
    @Persisted var authority: String
    @Persisted var eventType: String
    
    public override static func primaryKey() -> String? {
        return "id"
    }
    
    convenience init(id: String, documentId: String, docType: String, nameSpace: String, timestamp: Int, status: String, authority: String, eventType: String) {
        self.init()
        self.id = id
        self.documentId = documentId
        self.docType = docType
        self.nameSpace = nameSpace
        self.timestamp = timestamp
        self.status = status
        self.authority = authority
        self.eventType = eventType
    }
    
    enum CodingKeys: String, CodingKey {
        case id, documentId, docType, nameSpace, timestamp, status, authority, eventType
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(documentId, forKey: .documentId)
        try container.encode(docType, forKey: .docType)
        try container.encode(nameSpace, forKey: .nameSpace)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(status, forKey: .status)
        try container.encode(authority, forKey: .authority)
        try container.encode(eventType, forKey: .eventType)
    }
}

public enum TransactionStatus: String, Codable {
    case DOCUMENT_ISSUED, DOCUMENT_DELETED, DOCUMENT_PRESENTED, DOCUMENT_SIGNED, DOCUMENT_PAYMENT, DOCUMENT_CANCELLED
}
