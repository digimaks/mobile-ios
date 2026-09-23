// SPDX-License-Identifier: EUPL-1.2

//
//  WebViewFunctionObject.swift
//  edim
//
//  Created by Matīss Mamedovs on 28/11/2024.
//

import Foundation

public enum WebViewFunctionObject: String, Codable, Sendable {
    // SCAN
    case scan
    // DOCUMENTS
    case getDocumentDetails
    case getDocuments
    case deleteDocument
    case setDocumentFavorite
    // ONBOARDING
    case initiateEParaksts
    case initiateSmartID
    case submitEmail
    case verifyEmailOTP
    case submitSms
    case verifySmsOTP
    case initialiseWallet
    case startWallet
    case activateWallet
    // ISSUANCE
    case getDocumentOptions
    case issueDocument
    case getPidDetails
    case getUserSignatureOptions
    case selectUserSignatures
    // SETTINGS
    case enableBiometrics
    case setLanguage
    case getBiometricAvailability
    case deleteWallet
    // PRESENTATION
    case scanQrCode
    case resolveDocumentOffer
    case getOfferCodeData
    case issueDocumentOffer
    case getRequestDocuments
    case confirmRequest
    case setVendorPresentationPreference
    case presentationCanceled
    //APP
    case getState
    //TRANSACTIONS
    case getTransactions
    //SIGN
    case pickFiles
    case openFile
    case getSigningMethods
    case signDocument
    case downloadSignedDocument
    case shareSignedDocument
    case getSharedFile
    
    enum CodingKeys: String, CodingKey {
        case scan = "scan"
        case addAttribute = "addAttribute"
        case getDocuments = "getDocuments"
        case getDocumentDetails = "getDocumentDetails"
        case getDocument = "getDocument"
        case initiateEParaksts = "initiateEParaksts"
    }
}
