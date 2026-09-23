// SPDX-License-Identifier: EUPL-1.2

//
//  FileValidation.swift
//  edim
//
//  Created by Matīss Mamedovs on 19/03/2025.
//

public struct FileValidationResponses: Codable {
    public var validationResponses: [FileValidationResponse]
    
    enum CodingKeys: String, CodingKey {
        case validationResponses = "validationResponses"
    }
}

public struct FileValidationResponse: Codable {
    public var sessionId: String
    public var data: FileValidationResponseData
    
    enum CodingKeys: String, CodingKey {
        case sessionId = "sessionId"
        case data = "data"
    }
}

public struct FileValidationResponseData: Codable {
    public var includedFiles: [FileName]
    public var signatureForm: String?
    public var signatureCount: Int
    public var signatureExt: [SignatureExtension]
    public var validSignaturesCount: Int
    public var validatedDocument: FileName
    public var validationLevel: String
    
    enum CodingKeys: String, CodingKey {
        case includedFiles = "includedFiles"
        case signatureForm = "signatureForm"
        case signatureCount = "signaturesCount"
        case signatureExt = "signaturesExt"
        case validSignaturesCount = "validSignaturesCount"
        case validatedDocument = "validatedDocument"
        case validationLevel = "validationLevel"
    }
}

public struct FileName: Codable {
    public var filename: String
    
    enum CodingKeys: String, CodingKey {
        case filename = "filename"
    }
}

public struct SignatureExtension: Codable {
    var errors: [WarningContent]
    var id: String
    var indication: String
    var signatureFormat: String
    var signatureLevel: String
    var signedBy: String
    var signerSerialNumber: String?
    var registrationNumber: String?
    var subIndication: String
    var warnings: [WarningContent]
    var info: SignatureInfo
    
    enum CodingKeys: String, CodingKey {
        case errors = "errors"
        case id = "id"
        case indication = "indication"
        case signatureFormat = "signatureFormat"
        case signatureLevel = "signatureLevel"
        case signedBy = "signedBy"
        case signerSerialNumber = "signerSerialNumber"
        case registrationNumber = "registrationNumber"
        case subIndication = "subIndication"
        case warnings = "warnings"
        case info = "info"
    }
}

public struct WarningContent: Codable {
    var content: String
    
    enum CodingKeys: String, CodingKey {
        case content = "content"
    }
}

public struct SignatureInfo: Codable {
    var bestSignatureTime: String
    
    enum CodingKeys: String, CodingKey {
        case bestSignatureTime = "bestSignatureTime"
    }
}
