// SPDX-License-Identifier: EUPL-1.2

//
//  WalletCoreError.swift
//  edim
//
//  Created by Matīss Mamedovs on 25/11/2024.
//

import Foundation

public enum WalletCoreError: LocalizedError {
    case unableFetchDocuments
    case unableFetchDocument
    case missingPid
    case unableToIssueAndStore
    case transactionCodeFormat([String])
    case unableToPresentAndShare
}
