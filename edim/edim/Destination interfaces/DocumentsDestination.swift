// SPDX-License-Identifier: EUPL-1.2

//
//  DocumentsDestination.swift
//  edim
//
//  Created by Matīss Mamedovs on 10/12/2024.
//

import WebKit
import EudiWalletKit
import MdocSecurity18013
import MdocDataTransfer18013
import MdocDataModel18013
import OpenID4VCI
import WalletStorage

final class DocumentsDestination: Destination, Sendable {
        
    public static let shared = DocumentsDestination()
    
    public override init() {
        super.init()
    }
        
    override func start() {
        Task {
            guard let localInit = await self.local else {
                return
            }
            
            switch localInit.funcName {
            case .getDocuments:
                await self.getDocuments()
            case .getDocumentDetails:
                await self.getDocument(localInit: localInit)
            case .deleteDocument:
                await self.delete(localInit: localInit)
            case .setDocumentFavorite:
                await self.setDocumentFavorite(localInit: localInit)
            default:
                break
            }
        }
    }
}

extension DocumentsDestination {
    fileprivate func delete(localInit: LocalInitObject) async {
        if let id = localInit.params?["documentId"] as? String {
            if let document = WalletInstance.shared.fetchDocument(id: id) {
                RealmManager.shared.insertTransaction(id: id, type: .DOCUMENT_DELETED)
                RealmManager.shared.deleteFavoriteDocument(documentID: id)
                let state: DocumentDetailsDeletionPartialState = await WalletInstance.shared.deleteDocument(identifier: id, type: document.transformToDocumentDetailsUi().type)
                switch state {
                case .success(shouldReboot: let shouldReboot):
                    let dict = ["status": shouldReboot ? "all_deleted" : "deleted" ]
                    if let local = self.local {
                        Task {
                            await self.inject(id: local.id, status: .SUCCESS, message: nil, data: dict)
                        }
                    }
                case .failure(_):
                    break
                }
            } else if RealmManager.shared.signatureExists(Sid: id) {
                RealmManager.shared.insertTransaction(id: id, type: .DOCUMENT_DELETED)
                RealmManager.shared.deleteFavoriteDocument(documentID: id)
                RealmManager.shared.deleteSignature(Sid: id)

                let dict = ["status": "deleted" ]
                if let local = self.local {
                    Task {
                        await self.inject(id: local.id, status: .SUCCESS, message: nil, data: dict)
                    }
                }
            }
        }
    }
    
    fileprivate func getDocuments() async {
        let docs = await WalletInstance.shared.fetchDocuments() ?? []
        
        var responseArray: [GetDocumentsLocalResponse] = []
        
        for doc in docs.enumerated() {
            if doc.element.value.heading == SignatureHelper.ESIGN_NAME || doc.element.value.heading == SignatureHelper.ESEAL_NAME {
                let meta = MetaHelper.shared.constructMeta(signature: doc.element)
                
                let resp = GetDocumentsLocalResponse(meta: meta, documentDetails: constructESignDocumentDetails(id: doc.element.value.id))
                
                responseArray.append(resp)
            } else {
                if let doc1 = await WalletInstance.shared.fetchDocument(id: doc.element.value.id) {
                    let meta = MetaHelper.shared.constructMeta(item: doc1)
                    let resp = GetDocumentsLocalResponse(meta: meta, documentDetails: constructDocumentDetails(document: doc1))
                    
                    responseArray.append(resp)
                }
            }
        }
        
        let docDict = ["documents": responseArray]
        if let local = self.local {
            Task {
                await self.inject(id: local.id, status: .SUCCESS, message: nil, data: docDict)
            }
        }
    }
    
    fileprivate func constructDocumentDetails(document: any DocClaimsDecodable) -> [[String: String]] {
        var details: [[String: String]] = []
        for documentField in document.docClaims {
            if let identifier = document.configurationIdentifier, identifier ==  "eu.europa.ec.eudi.iban_sd_jwt_vc", documentField.name == "status" {
                // Dont show status claim as it's hidden by Android SDK
                continue
            }
            var item: [String: String] = [:]
            item["type"] = documentField.name == "signature_usual_mark" ? "signature" : "text"
            item["identifier"] = documentField.name
            item["label"] = documentField.displayName == nil ? documentField.name : documentField.displayName
            
            if documentField.name == "driving_privileges" {
                var privileges: String = ""
                for children in documentField.children ?? [] {
                    for child in children.children ?? [] {
                        if child.name == "vehicle_category_code" {
                            privileges += child.stringValue + ", "
                        }
                    }
                }
                privileges = String(privileges.dropLast())
                privileges = String(privileges.dropLast())
                item["value"] = privileges
            } else {
                if documentField.name == "signature_usual_mark" {
                    item["image"] = documentField.dataValue.base64
                    item["value"] = ""
                } else {
                    var val = documentField.stringValue
                    if hasElevenDigits(text: val) {
                        val = val.replacingOccurrences(of: "PNOLV-", with: "")
                    }
                    
                    if documentField.name.contains("date") {
                        val = Locale.current.convertFromYearsAtStart(val) ?? ""
                    }
                    
                    item["value"] = val
                    if documentField.name == "portrait" {
                        item["value"] = "Shown above"
                        item["image"] = documentField.dataValue.base64 ?? ""
                    } else {
                        item["image"] = ""
                    }
                }
                
            }
            
            details.append(item)
        }
        
        return details
    }
    
    
    fileprivate func hasElevenDigits(text: String) -> Bool {
        let digitsOnly = text.filter { $0.isNumber }
        return digitsOnly.count == 11
    }

    
    fileprivate func constructESignDocumentDetails(id: String) -> [[String: String]] {
        return SignatureHelper.shared.constructDocumentDetails(id: id)
    }
    
    fileprivate func getDocument(localInit: LocalInitObject) {
        if let local = self.local {
            Task {
                await self.inject(id: local.id, status: .SUCCESS, message: nil, data: nil as String?)
            }
        }
    }
    
    fileprivate func setDocumentFavorite(localInit: LocalInitObject) {
        if let id = localInit.params?["documentId"] as? String, let isFavorite = localInit.params?["isFavorite"] as? Bool {
            if isFavorite {
                RealmManager.shared.insertFavoriteDocument(documentID: id)
            } else {
                RealmManager.shared.deleteFavoriteDocument(documentID: id)
            }
            
            if let local = self.local {
                Task {
                    await self.inject(id: local.id, status: .SUCCESS, message: nil, data: nil as String?)
                }
            }
        }
    }
}
