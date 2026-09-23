// SPDX-License-Identifier: EUPL-1.2

//
//  SignatureHelper.swift
//  edim
//
//  Created by Matīss Mamedovs on 18/03/2025.
//

import RealmSwift
import Foundation

@MainActor
final public class SignatureHelper: Sendable {
    public static let ESIGN_NAME: String = "eSign"
    public static let ESEAL_NAME: String = "eSeal"
    public static let ESIGN_TYPE: String = "eu.digimaks.esign"
    public static let ESEAL_TYPE: String = "eu.digimaks.eseal"
    
    @MainActor public static let shared = SignatureHelper()
    
    func constructAsDocument(item: Signature) -> DocumentUIModel {
        let displayName: String = item.isSign ? SignatureHelper.ESIGN_NAME : SignatureHelper.ESEAL_NAME
        let model = DocumentUIModel(id: UUID().uuidString, value: .init(
            id: item.Sid,
            heading: displayName,
            title: displayName,
            createdAt: Locale.current.parseDate(
                date: item.issuedOn) ?? Date(),
            expiresAt: Locale.current.localizedDateTime(
                date: item.expiresOn,
                uiFormatter: "dd.MMM.yyyy"
            ),
            hasExpired: self.hasExpired(
                expiryDateValue: item.expiresOn, parser: { Locale.current.parseDate(date: $0) }
            ),
            state: .issued,
            image: nil
        ))
        
        return model
    }
    
    func hasExpired(expiryDateValue: String?, parser: (String) -> Date?) -> Bool {
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
    
    public func isFileContainer(url: URL) -> Bool {
        var isContainer: Bool = false
        if let fh = FileHandle(forReadingAtPath: url.relativePath) {
            let data = fh.readData(ofLength: 4)
            if data.starts(with: [0x50, 0x4b, 0x03, 0x04]) {
                isContainer = true
            }
            fh.closeFile()
        }
        
        return isContainer
    }
    
    public func isValidFileSize(data: Data) -> Bool {
        return data.count > 0 && data.count <= 25000000
    }
    
    public func constructDocumentDetails(id: String) -> [[String: String]] {
        if RealmManager.shared.signatureExists(Sid: id) {
            if let realmDocument = RealmManager.shared.getSignature(Sid: id) {
                let document = SignatureHelper.shared.constructAsDocument(item: realmDocument)
                var details: [[String: String]] = []
                
                let type: String = "text"
                
                var item1: [String: String] = [:]
                item1["type"] = type
                item1["identifier"] = Signature.codingKey(for: \.Sid)
                item1["label"] = Texts.SIGNATURE_TEXT_SID
                item1["value"] = realmDocument.Sid

                var item2: [String: String] = [:]
                item2["type"] = type
                item2["identifier"] = Signature.codingKey(for: \.cn)
                item2["label"] = realmDocument.isSign ? Texts.SIGNATURE_TEXT_CN : Texts.SIGNATURE_TEXT_CN_SEAL
                item2["value"] = realmDocument.cn
                
                var item3: [String: String] = [:]
                item3["type"] = type
                item3["identifier"] = Signature.codingKey(for: \.expiresOn)
                item3["label"] = Texts.SIGNATURE_TEXT_EXPIRES
                
                item3["value"] = Locale.current.localizedDateTime(
                    date: realmDocument.expiresOn,
                    uiFormatter: "dd.MM.yyyy."
                )
                
                var item4: [String: String] = [:]
                item4["type"] = type
                item4["identifier"] = Signature.codingKey(for: \.issuedOn)
                item4["label"] = Texts.SIGNATURE_TEXT_ISSUED
                item4["value"] = Locale.current.localizedDateTime(
                    date: realmDocument.issuedOn,
                    uiFormatter: "dd.MM.yyyy."
                )
                
                details.append(item1)
                details.append(item2)
                details.append(item3)
                details.append(item4)
                
                return details
            } else {
                return [[:]]
            }
        } else {
            return [[:]]
        }
    }
}
