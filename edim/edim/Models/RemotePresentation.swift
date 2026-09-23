// SPDX-License-Identifier: EUPL-1.2

//
//  RemotePresentation.swift
//  edim
//
//  Created by Matīss Mamedovs on 11/06/2025.
//

public struct RemotePresentationLocalResponse: Codable, Sendable {
    public var vendorKey: String
    public var quickFlowAvailable: Bool
    public var savedSelectionApplied: Bool
    public var verifierName: String
    public var verifierIsTrusted: Bool
    public var transactionData: PresentationTransactionData?
    public var documents: [RemotePresentationDocument]
}

public struct RemotePresentationDocument: Codable, Sendable {
    public var title: String
    public var meta: Meta
    public var fields: [RemotePresentationField]
}

public struct RemotePresentationField: Codable, Sendable {
    public var id: String
    public var readableName: String
    public var value: String
    public var checked: Bool
    public var enabled: Bool
    public var elementIdentifier: String
    public var isRequired: Bool
}

public struct PresentationTransactionData: Codable, Sendable {
    public var paymentId: String
    public var amount: String
    public var currency: String
    public var creditor: String
    public var purpose: String

}
