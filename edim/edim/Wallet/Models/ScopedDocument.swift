// SPDX-License-Identifier: EUPL-1.2

//
//  ScopedDocument.swift
//  edim
//
//  Created by Matīss Mamedovs on 29/01/2025.
//

public struct ScopedDocument: Equatable, Sendable {
  public let name: String
  public let issuer: String
  public let configId: String
  public let isPid: Bool
}
