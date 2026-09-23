// SPDX-License-Identifier: EUPL-1.2

//
//  Documents.swift
//  edim
//
//  Created by Matīss Mamedovs on 11/06/2025.
//

public struct DocumentDetailLocalResponseObject: Codable, Sendable {
    public var meta: Meta
    public var documentDetails: [[String: String]]?
    public var documentImage: String?
    
    enum CodingKeys: String, CodingKey {
        case meta = "meta"
        case documentDetails = "documentDetails"
        case documentImage = "documentImage"
    }
}

public struct GetDocumentsLocalResponse: Codable {
    public var meta: Meta
    public var documentDetails: [[String: String]]
}
