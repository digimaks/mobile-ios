// SPDX-License-Identifier: EUPL-1.2

//
//  LocalInitObject.swift
//  edim
//
//  Created by Matīss Mamedovs on 09/12/2024.
//

import Foundation

public struct LocalInitObject: Codable, Sendable {
    public var id: String
    public var funcName: WebViewFunctionObject
    public var params: [String: any Sendable]?
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case funcName = "func"
        case params = "params"
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        funcName = try values.decode(WebViewFunctionObject.self, forKey: .funcName)
        let data = try values.decode(Data.self, forKey: .params)
        params = try JSONSerialization.jsonObject(with: data, options: []) as? [String: any Sendable]
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(funcName, forKey: .funcName)
        let data = try JSONSerialization.data(withJSONObject: params, options: [])
        try container.encode(data, forKey: .params)
    }
    
    public init(id: String, funcName: WebViewFunctionObject, params: [String: any Sendable]? = nil) {
        self.id = id
        self.funcName = funcName
        self.params = params
    }
}
