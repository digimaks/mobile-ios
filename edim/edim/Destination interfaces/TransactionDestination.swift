// SPDX-License-Identifier: EUPL-1.2

//
//  TransactionDestination.swift
//  edim
//
//  Created by Matīss Mamedovs on 20/02/2025.
//


final class TransactionDestination: Destination, Sendable {
    
    public static let shared = TransactionDestination()
    
    public override init() {
        super.init()
    }
    
    override func start() {
        Task {
            guard let localInit = await self.local else {
                return
            }
            
            switch localInit.funcName {
            case .getTransactions:
                await self.getTransactions(localInit: localInit)
            default:
                break
            }
        }
    }
}

extension TransactionDestination {
    fileprivate func getTransactions(localInit: LocalInitObject) async {
        let transactions = RealmManager.shared.getTransactions(for: localInit.params?["documentId"] as? String) ?? []
        var resultTransaction: [TransactionCommunicationObject] = []
        
        
        for transaction in transactions {
            let isSigningDoc: Bool = transaction.docType == SignatureHelper.ESEAL_TYPE || transaction.docType == SignatureHelper.ESIGN_TYPE
            
            let res = TransactionCommunicationObject(id: transaction.id,
                                                     documentId: transaction.documentId,
                                                     documentIdentifier: transaction.docType,
                                                     documentDisplay: TransactionDocumentDisplay(name: isSigningDoc ? "" : transaction.nameSpace),
                                                     timestamp: transaction.timestamp,
                                                     status: transaction.status,
                                                     eventType: transaction.eventType,
                                                     authority: transaction.authority)
            resultTransaction.append(res)
        }
        
        let docDict = ["transactions": resultTransaction]
        if let local = self.local {
            Task {
                await self.inject(id: local.id, status: .SUCCESS, message: nil, data: docDict)
            }
        }
    }
}

public struct TransactionCommunicationObject: Codable, Sendable {
    var id: String
    var documentId: String
    
    var documentIdentifier: String
    var documentDisplay: TransactionDocumentDisplay

    var timestamp: Int
    var status: String
    var eventType: String
    var authority: String
}

public struct TransactionDocumentDisplay: Codable, Sendable {
    var name: String
}
