// SPDX-License-Identifier: EUPL-1.2

//
//  IssuanceMethod.swift
//  edim
//
//  Created by Matīss Mamedovs on 08/06/2026.
//

import RealmSwift

public class IssuanceMethod: Object {
    @Persisted var documentID: String
    @Persisted var method: IssuanceMethodType
    
    public override static func primaryKey() -> String? {
        return "documentID"
    }
    
    convenience init(documentID: String, method: IssuanceMethodType) {
        self.init()
        self.documentID = documentID
        self.method = method
    }
}


public enum IssuanceMethodType: String, PersistableEnum {
    case eparaksts
    case smart_id
    case qr
}
