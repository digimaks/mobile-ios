// SPDX-License-Identifier: EUPL-1.2

//
//  Signature.swift
//  edim
//
//  Created by Matīss Mamedovs on 18/03/2025.
//

import RealmSwift

public class Signature: Object, Codable {
    @Persisted var Sid: String
    @Persisted var cn: String
    @Persisted var expiresOn: String
    @Persisted var issuedOn: String
    @Persisted var isSign: Bool
    
    convenience init(Sid: String, cn: String, expiresOn: String, issuedOn: String, isSign: Bool) {
        self.init()
        self.Sid = Sid
        self.cn = cn
        self.expiresOn = expiresOn
        self.issuedOn = issuedOn
        self.isSign = isSign
    }
    
    enum CodingKeys: String, CodingKey {
        case Sid = "sid"
        case cn = "cn"
        case expiresOn = "expiresOn"
        case issuedOn = "issuedOn"
        case isSign = "isSign"
    }
    
    static func codingKey<Value>(for keyPath: KeyPath<Signature, Value>) -> String? {
            let codingKey: CodingKeys
            switch keyPath {
            case \Signature.Sid:
                codingKey = .Sid
            case \Signature.cn:
                codingKey = .cn
            case \Signature.expiresOn:
                codingKey = .expiresOn
            case \Signature.issuedOn:
                codingKey = .issuedOn
            case \Signature.isSign:
                codingKey = .isSign
            default: // handle properties that aren't encoded
                return nil
            }
            return codingKey.rawValue
        }
}
