// SPDX-License-Identifier: EUPL-1.2

//
//  IssueDocumentPartialState.swift
//  edim
//
//  Created by Matīss Mamedovs on 25/11/2024.
//

import Foundation

public enum IssueDocumentPartialState: Sendable {
    case success(String)
    case deferredSuccess
    case dynamicIssuance
    case failure(Error)
}

public enum DocumentDetailsDeletionPartialState: Sendable {
  case success(shouldReboot: Bool)
  case failure(Error)
}
