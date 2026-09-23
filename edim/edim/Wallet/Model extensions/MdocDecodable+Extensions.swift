// SPDX-License-Identifier: EUPL-1.2

//
//  MdocDecodable+Extensions.swift
//  edim
//
//  Created by Matīss Mamedovs on 25/11/2024.
//

import Foundation
import MdocSecurity18013
import MdocDataTransfer18013
import MdocDataModel18013
import UIKit


public extension DocClaimsDecodable {
    
    func getExpiryDate(parser: (String) -> String) -> String? {
        if let expiryDate = expiryDateValue {
            return parser(expiryDate)
        } else {
            return nil
        }
    }
    
    func hasExpired(parser: (String) -> Date?) -> Bool {
        guard let value = expiryDateValue, let expiryDate = parser(value) else {
            return false
        }
        let order = Calendar.current.compare(expiryDate, to: Date.now, toGranularity: .day)
        switch order {
        case .orderedAscending:
            return true
        default:
            return false
        }
    }
    
    func getBearersName() -> (first: String, last: String)? {
        var name: (first: String, last: String)?
        
        let firstName = self.docClaims.first(where: { $0.name == DocumentJsonKeys.FIRST_NAME })?.stringValue
        let lastName = self.docClaims.first(where: { $0.name == DocumentJsonKeys.LAST_NAME })?.stringValue
        
        if let firstName, let lastName {
            name = (firstName, lastName)
        }
        
        return name
    }
    
    func getFirstName() -> String {
        let firstName = self.docClaims.first(where: { $0.name == DocumentJsonKeys.FIRST_NAME })?.stringValue
        
        return firstName ?? ""
    }
    
    func getPortrait() -> UIImage? {
        var image: UIImage?
        
        let uiImage = self.docClaims.first(where: { $0.name == DocumentJsonKeys.PORTRAIT })?.dataValue.image
        
        
        return uiImage
    }
    
    private var expiryDateValue: String? {
        return self.docClaims.first(where: { $0.name == DocumentJsonKeys.EXPIRY_DATE })?.stringValue
    }
    
    func getDisplayNumber(type: DocumentTypeIdentifier) -> String {
        if type == .mDL {
            return self.docClaims.first(where: { $0.name == "document_number" })?.stringValue ?? ""
        } else if type == .Diploma {
            return self.docClaims.first(where: { $0.name == "nationalID" })?.stringValue ?? ""
        } else if type == .paymentCard {
            return self.docClaims.first(where: { $0.name == "sub" })?.stringValue ?? ""
        } else {
            return self.docClaims.first(where: { $0.name == "personal_administrative_number" })?.stringValue ?? ""
        }
    }
    
    func getDescription(type: DocumentTypeIdentifier) -> String {
        if type == .mDL {
            return self.docClaims.first(where: { $0.name == "issuing_country" })?.stringValue ?? ""
        } else if type == .Diploma {
            return self.docClaims.first(where: { $0.name == "thematicArea" })?.stringValue ?? ""
        } else {
            return self.docClaims.first(where: { $0.name == "issuing_country" })?.stringValue ?? ""
        }
    }
    
    func getAdditionalInfo(type: DocumentTypeIdentifier) -> String {
        if type == .mDL {
            let claim = self.docClaims.first(where: { $0.name == "driving_privileges" })
            var privileges: String = ""
            for children in claim?.children ?? [] {
                for child in children.children ?? [] {
                    if child.name == "vehicle_category_code" {
                        privileges += child.stringValue + ", "
                    }
                }
            }
            privileges = String(privileges.dropLast())
            privileges = String(privileges.dropLast())
            return privileges
        } else if type == .Diploma {
            return self.docClaims.first(where: { $0.name == "title" })?.stringValue ?? ""
        } else {
            return ""
        }
    }
    
    func getExpiryDate(type: DocumentTypeIdentifier) -> String {
        if type == .paymentCard {
            return self.docClaims.first(where: { $0.name == "exp" })?.stringValue ?? ""

        } else {
            return Locale.current.convertFromYearsAtStart(self.docClaims.first(where: { $0.name == "expiry_date" })?.stringValue ?? "") ?? ""
        }
    }
    
    func getIssuanceAuthority(type: DocumentTypeIdentifier) -> String {
        return self.docClaims.first(where: { $0.name == "issuing_authority" })?.stringValue ?? ""
    }
    
    func getPersonalCode() -> String {
        var val = (self.docClaims.first(where: { $0.name == "personal_administrative_number" })?.stringValue ?? "").replacingOccurrences(of: "PNOLV-", with: "")
        if isElevenDigits(text: val) {
            let index = val.index(val.startIndex, offsetBy: 6)
            val.insert("-", at: index)
            return val
        } else {
            return val
        }
        
    }
    
    func getIssuingCountry(type: DocumentTypeIdentifier) -> String {
        if type == .mDL {
            return self.docClaims.first(where: { $0.name == "issuing_country" })?.stringValue ?? ""
        } else if type == .Diploma {
            return self.docClaims.first(where: { $0.name == "awardingBody_countryCode" })?.stringValue ?? ""
        } else {
            return self.docClaims.first(where: { $0.name == "issuing_country" })?.stringValue ?? ""
        }
    }
    
    func getIssuanceDate(type: DocumentTypeIdentifier) -> String {
        if type == .mDL {
            return self.docClaims.first(where: { $0.name == "issue_date" })?.stringValue ?? ""
        } else if type == .Diploma {
            return self.docClaims.first(where: { $0.name == "issued" })?.stringValue ?? ""
        } else if type == .paymentCard {
            return self.docClaims.first(where: { $0.name == "iat" })?.stringValue ?? ""
        } else {
            return Locale.current.convertFromYearsAtStart(self.docClaims.first(where: { $0.name == "issuance_date" })?.stringValue ?? "") ?? ""
        }
    }
    
    
    
    fileprivate func isElevenDigits(text: String) -> Bool {
        return text.range(of: #"^\d{11}$"#, options: .regularExpression) != nil
    }
}

public struct DocumentJsonKeys {
    public static let PORTRAIT = "portrait"
    public static let SIGNATURE = "signature_usual_mark"
    public static let FIRST_NAME = "given_name"
    public static let LAST_NAME = "family_name"
    public static let USER_PSEUDONYM = "user_pseudonym"
    public static let EXPIRY_DATE = "expiry_date"
}
