// SPDX-License-Identifier: EUPL-1.2

//
//  DocumentTypeIdentifier.swift
//  edim
//
//  Created by Matīss Mamedovs on 15/11/2024.
//

public enum DocumentTypeIdentifier: RawRepresentable, Equatable, Sendable, Codable {
    
    case PID
    case mDL
    case Diploma
    case paymentCard
    case GENERIC(docType: String)
    
    public var rawValue: String {
        return switch self {
        case .PID:
            Self.pidDocType
        case .mDL:
            Self.mdlDocType
        case .Diploma:
            Self.rtuDiplomaType
        case .paymentCard:
            Self.paymentCardType
        case .GENERIC(let docType):
            docType
        }
    }
    
    public var isSupported: Bool {
        return switch self {
        case .PID, .mDL, .Diploma, .paymentCard: true
        case .GENERIC: false
        }
    }
    
    public var offerType: String {
        switch self {
        case .PID:
            return "pid"
        case .mDL:
            return "mdl"
        case .Diploma:
            return "rtu"
        case .paymentCard:
            return "iban"
        case .GENERIC(let docType):
            return ""
        }
    }
    
    public init(rawValue: String) {
        switch rawValue {
        case Self.pidDocType:
            self = .PID
        case Self.mdlDocType:
            self = .mDL
        case Self.rtuDiplomaType:
            self = .Diploma
        case Self.paymentCardType:
            self = .paymentCard
        default:
            self = .GENERIC(docType: rawValue)
        }
    }
}

private extension DocumentTypeIdentifier {
    static let pidDocType = "eu.europa.ec.eudi.pid.1"
    static let mdlDocType = "org.iso.18013.5.1.mDL"
    static let rtuDiplomaType = "eu.europa.ec.eudi.rtu_diploma_mdoc"
    static let ageDocType = "eu.europa.ec.eudi.pseudonym.age_over_18.1"
    static let photoIdDocType = "org.iso.23220.2.photoid.1"
    static let paymentCardType = "eu.europa.ec.eudi.iban"
}

//
