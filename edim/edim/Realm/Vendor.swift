// SPDX-License-Identifier: EUPL-1.2

//
//  Vendor.swift
//  edim
//
//  Created by Matīss Mamedovs on 06/05/2026.
//


import RealmSwift

public class Vendor: Object {
    @Persisted var vendorID: String
    @Persisted var attributeFields: List<String>
    
    public override static func primaryKey() -> String? {
        return "vendorID"
    }
    
    convenience init(vendorID: String, attributeFields: List<String>) {
        self.init()
        self.vendorID = vendorID
        self.attributeFields = attributeFields
    }
}
