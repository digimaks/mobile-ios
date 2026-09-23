// SPDX-License-Identifier: EUPL-1.2

//
//  ContainerInfo.swift
//  edim
//
//  Created by Matīss Mamedovs on 11/06/2025.
//

public struct ContainerInfoLocalObject: Codable, Sendable {
    var signers: [Signer]
    var files: [SignedFile]
}
