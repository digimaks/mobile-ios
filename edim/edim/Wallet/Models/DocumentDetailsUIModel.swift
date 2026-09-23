// SPDX-License-Identifier: EUPL-1.2

//
//  DocumentDetailsUIModel.swift
//  edim
//
//  Created by Matīss Mamedovs on 27/01/2025.
//

import Foundation
import UIKit
import EudiWalletKit
import MdocSecurity18013
import MdocDataTransfer18013
import MdocDataModel18013

public struct DocumentDetailsUIModel: Sendable {
    
    public let id: String
    public let type: DocumentTypeIdentifier
    public let documentName: String
    public let issuer: IssuerField?
    public let holdersName: String
    public let createdAt: Date
    public let hasExpired: Bool
    public let documentFields: [DocumentField]
    
    public func getIssuanceAuthority() -> String {
        if type == .mDL {
            return self.documentFields.first(where: { $0.title == "Issuing authority" })?.getValue() as? String ?? ""
        } else if type == .Diploma {
            return self.documentFields.first(where: { $0.title == "Issuing authority" })?.getValue() as? String ?? ""
        } else {
            return self.documentFields.first(where: { $0.title == "Issuance Authority" })?.getValue() as? String ?? ""
            
        }
    }
    
    public func getIssuingCountry() -> String {
        if type == .mDL {
            return self.documentFields.first(where: { $0.title == "Issuing country" })?.getValue() as? String ?? ""
        } else if type == .Diploma {
            
            return self.documentFields.first(where: { $0.title == "Awarding body country code" })?.getValue() as? String ?? ""
        }  else {
            return self.documentFields.first(where: { $0.title == "Issuing Country" })?.getValue() as? String ?? ""
        }
    }
    
    public func getExpiryDate() -> String {
        if type == .mDL {
            return self.documentFields.first(where: { $0.title == "Date when mDL expires" })?.getValue() as? String ?? ""
        } else if type == .Diploma {
            return ""
        }  else {
            return self.documentFields.first(where: { $0.title == "Expiry Date" })?.getValue() as? String ?? ""
        }
    }
    
    public func getIssuanceDate() -> String {
        if type == .mDL {
            return self.documentFields.first(where: { $0.title == "Date of issue" })?.getValue() as? String ?? ""
        } else if type == .Diploma {
            return self.documentFields.first(where: { $0.title == "Issuance date" })?.getValue() as? String ?? ""
        } else {
            return self.documentFields.first(where: { $0.title == "Issuance Date" })?.getValue() as? String ?? ""
        }
    }
}

public extension DocumentDetailsUIModel {
    
    struct IssuerField: Identifiable, Sendable, Equatable {
        public let id: String
        public let name: String
        public let logoUrl: URL?
        public let isVerified: Bool
        
        public init(
            id: String = UUID().uuidString,
            issuersName: String,
            logoUrl: URL?,
            isVerified: Bool
        ) {
            self.id = id
            self.name = issuersName
            self.logoUrl = logoUrl
            self.isVerified = isVerified
        }
    }
    
    struct DocumentField: Identifiable, Sendable {
        
        public indirect enum Value: Sendable {
            case string(String)
            case image(Data)
        }
        
        public let id: String
        public let title: String
        public let value: Value
        
        func getValue() -> Any {
            switch value {
            case .image(let num):
                return num
            case .string(let num):
                return num
            }
        }
    }
}

extension DocClaimsDecodable {
    func transformToDocumentDetailsUi() -> DocumentDetailsUIModel {
        
        var issuer: DocumentDetailsUIModel.IssuerField? {
            guard let name = self.issuerDisplay?.first?.name else {
                return nil
            }
            let logo = self.issuerDisplay?.first?.logo?.uri
            return .init(
                issuersName: name,
                logoUrl: logo,
                isVerified: true
            )
        }
        
        let documentFields: [DocumentDetailsUIModel.DocumentField] =
        flattenValues(
            input: docClaims
                .compactMap({$0})
                .parseDates(
                    parser: {
                        Locale.current.localizedDateTime(
                            date: $0,
                            uiFormatter: "dd MMM yyyy"
                        )
                    }
                )
                .parseUserPseudonym()
        )
        .sorted(by: { $0.title.lowercased() < $1.title.lowercased() })
        
        var bearerName: String {
            guard let fullName = getBearersName() else {
                return ""
            }
            return "\(fullName.first) \(fullName.last)"
        }
        
        let identifier = DocumentTypeIdentifier(rawValue: docType)
        
        return .init(
            id: id,
            type: identifier,
            documentName: displayName.orEmpty,
            issuer: issuer,
            holdersName: bearerName,
            createdAt: createdAt,
            hasExpired: hasExpired(
                parser: {
                    Locale.current.parseDate(
                        date: $0
                    )
                }
            ),
            documentFields: documentFields
        )
    }
    
    private func flattenValues(input: [DocClaim]) -> [DocumentDetailsUIModel.DocumentField] {
        input.reduce(into: []) { partialResult, docClaim in
            
            let uuid = UUID().uuidString
            let title = docClaim.displayName.ifNilOrEmpty { docClaim.name }
            
            if let uiImage = docClaim.dataValue.image, let data = uiImage.pngData() {
                
                partialResult.append(
                    .init(
                        id: uuid,
                        title: title,
                        value: .image(data)
                    )
                )
                
            } else if let nested = docClaim.children {
                partialResult.append(
                    .init(
                        id: uuid,
                        title: title,
                        value: .string(docClaim.flattenNested(nested: nested).stringValue)
                    )
                )
            } else {
                partialResult.append(
                    .init(
                        id: uuid,
                        title: title,
                        value: .string(docClaim.stringValue)
                    )
                )
            }
        }
    }
}
