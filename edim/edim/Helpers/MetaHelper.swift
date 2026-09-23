// SPDX-License-Identifier: EUPL-1.2

//
//  MetaHelper.swift
//  edim
//
//  Created by Matīss Mamedovs on 05/02/2025.
//

import Foundation
import EudiWalletKit
import MdocSecurity18013
import MdocDataTransfer18013
import MdocDataModel18013
import OpenID4VCI
import WalletStorage
import UIKit

@MainActor
final public class MetaHelper: Sendable {
    @MainActor public static let shared = MetaHelper()
    
    func constructMeta(item: any DocClaimsDecodable) -> Meta {
        let uiDoc = item.transformToDocumentUi()
        let detailDoc = item.transformToDocumentDetailsUi()
        
        let issuerDisplay = item.issuerDisplay?.first
        let documentDisplay = item.display?.first
        
        let meta = Meta(id: uiDoc.value.id,
                        documentIdentifier: detailDoc.type.rawValue,
                        issuerDisplay: IssuerDisplay(name: issuerDisplay?.name ?? "",
                                                     issuingAuthority: item.getIssuanceAuthority(type: detailDoc.type),
                                                     issuingCountry: item.getIssuingCountry(type: detailDoc.type),
                                                     logo: DisplayLogo(altText: issuerDisplay?.logo?.alternativeText ?? "", uri: issuerDisplay?.logo?.urlString ?? "")),
                        documentDisplay: DocumentDisplay(name: detailDoc.documentName,
                                                         backgroundColor: documentDisplay?.backgroundColor,
                                                         backgroundImageUri: nil,
                                                         textColor: documentDisplay?.textColor,
                                                         description1: detailDoc.holdersName,
                                                         description2: item.getPersonalCode(),
                                                         logo: DisplayLogo(altText: documentDisplay?.logo?.alternativeText ?? "", uri: documentDisplay?.logo?.urlString ?? "")),
                        status: uiDoc.value.state.rawValue.uppercased(),
                        hasExpired: uiDoc.value.hasExpired,
                        isFavorite: RealmManager.shared.isFavoriteDocument(documentID: uiDoc.value.id),
                        expirationDate: item.getExpiryDate(type: detailDoc.type),
                        issuanceDate: item.getIssuanceDate(type: detailDoc.type),
                        issuanceMethod: RealmManager.shared.getIssuanceMethod(id: uiDoc.value.id) ?? ""
        )
        
        return meta
    }
    
    func constructMeta(signature: DocumentUIModel) -> Meta {
        let isESign: Bool = signature.value.title == SignatureHelper.ESIGN_NAME ? true : false
        
        let realmSignature = RealmManager.shared.getSignature(Sid: signature.value.id)
        
        let meta = Meta(id: signature.value.id,
                        documentIdentifier: isESign ? SignatureHelper.ESIGN_TYPE : SignatureHelper.ESEAL_TYPE,
                        issuerDisplay: IssuerDisplay(name: "",
                                                     issuingAuthority: "",
                                                     issuingCountry: "",
                                                     logo: DisplayLogo(altText: "", uri: "")),
                        documentDisplay: DocumentDisplay(name: "", backgroundColor: isESign ? "#009AC9" : "#DC4F0B", description1: realmSignature?.cn, logo: DisplayLogo(altText: "", uri: "")),
                        status: signature.value.state.rawValue.uppercased(),
                        hasExpired: signature.value.hasExpired,
                        isFavorite: RealmManager.shared.isFavoriteDocument(documentID: signature.value.id),
                        expirationDate: Locale.current.localizedDateTime(
                            date: realmSignature?.expiresOn ?? "",
                            uiFormatter: "dd.MM.yyyy."
                        ),
                        issuanceDate: Locale.current.localizedDateTime(
                            date: realmSignature?.issuedOn ?? "",
                            uiFormatter: "dd.MM.yyyy."
                        ),
                        issuanceMethod: RealmManager.shared.getIssuanceMethod(id: signature.value.id) ?? ""
        )
        
        return meta
    }
}
