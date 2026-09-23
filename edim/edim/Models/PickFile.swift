// SPDX-License-Identifier: EUPL-1.2

//
//  File.swift
//  edim
//
//  Created by Matīss Mamedovs on 11/06/2025.
//

public struct PickFilesLocalResponseObject: Codable, Sendable {
    var files: [PickFileLocalObject]
}

public struct PickFileLocalObject: Codable, Sendable {
    var path: String
    var name: String
    var size: Int
    var type: String
    var isContainer: Bool
    var isValid: Bool
    var allowedOutputFormats: [String]
    var containerInfo: ContainerInfoLocalObject?
}

public enum OutputFormats: Codable, Sendable {
    case edoc, pdf
    
    var name: String {
        switch self {
        case .edoc:
            return ".edoc"
        case .pdf:
            return ".pdf"
        }
    }
}
