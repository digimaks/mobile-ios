// SPDX-License-Identifier: EUPL-1.2

//
//  DocumentUIModel.swift
//  edim
//
//  Created by Matīss Mamedovs on 25/11/2024.
//

import Foundation
import EudiWalletKit
import MdocSecurity18013
import MdocDataTransfer18013
import MdocDataModel18013
import UIKit

public struct DocumentUIModel: Identifiable, Equatable, Sendable {
    
    public var id: String
    
    public let value: Value
    
    public init(id: String, value: Value) {
        self.id = id
        self.value = value
    }
}

public extension DocumentUIModel {
    
    struct Value: Equatable, Sendable {
        
        public struct RemoteImage: Equatable, Sendable {
            public static func == (lhs: RemoteImage, rhs: RemoteImage) -> Bool {
                return lhs.url == rhs.url
            }
            public let url: URL?
            public let placeholder: UIImage?
        }
        
        public var id: String
        
        public let heading: String
        public let title: String
        public var createdAt: Date
        public let expiresAt: String?
        public let hasExpired: Bool
        public let state: State
        public let image: RemoteImage?
    }
}

extension DocClaimsDecodable {
    func transformToDocumentUi(with failedDocuments: [String] = []) -> DocumentUIModel {
        return .init(
            id: UUID().uuidString,
            value: .init(
                id: self.id,
                heading: issuerDisplay?.first?.name.orEmpty ?? "",
                title: self.displayName.orEmpty,
                createdAt: self.createdAt,
                expiresAt: self.getExpiryDate(
                    parser: {
                        Locale.current.localizedDateTime(
                            date: $0,
                            uiFormatter: "dd MMM yyyy"
                        )
                    }
                ),
                hasExpired: self.hasExpired(
                    parser: { Locale.current.parseDate(date: $0) }
                ),
                state: failedDocuments.contains(
                    where: { $0 == self.id }
                ) ? .failed : (self is DeferrredDocument) ? .pending : .issued,
                image: .init(
                    url: self.issuerDisplay?.first?.logo?.uri,
                    placeholder: UIImage()
                )
            )
        )
    }
}


public extension DocumentUIModel.Value {
    enum State: String, Equatable, Sendable, Codable {
        case issued
        case pending
        case failed
    }
}
