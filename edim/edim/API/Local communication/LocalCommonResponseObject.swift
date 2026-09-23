// SPDX-License-Identifier: EUPL-1.2

//
//  LocalCommonResponseObject.swift
//  edim
//
//  Created by Matīss Mamedovs on 09/12/2024.
//

public struct LocalCommonResponseObject<T : Codable>: Codable {
    
    
    public var id: String
    public var status: ResponseStatus
    public var message: String?
    public var data: T?
    public var error: String?

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case status = "status"
        case message = "message"
        case data = "data"
        case error = "error"
    }

}

public enum ResponseStatus: String, Codable {
    case SUCCESS
    case ERROR
}
