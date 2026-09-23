// SPDX-License-Identifier: EUPL-1.2

//
//  DestinationInterface.swift
//  edim
//
//  Created by Matīss Mamedovs on 10/12/2024.
//


public enum DestinationInterface: String, CaseIterable, Sendable {
    case DocumentProcessorInterface, OnboardingInterface, IssuanceInterface, SettingsInterface, AppInterface, TransactionInterface, SignInterface, none
    
    @MainActor func getDestination() -> Destination {
        switch self {
        case .DocumentProcessorInterface:
            return DocumentsDestination.shared
        case .OnboardingInterface:
            return OnboardingDestination.shared
        case .IssuanceInterface:
            return IssuanceDestination.shared
        case .SettingsInterface:
            return SettingsDestionation.shared
        case .AppInterface:
            return AppDestination.shared
        case .TransactionInterface:
            return TransactionDestination.shared
        case .SignInterface:
            return SignDestination.shared
        case .none:
            return DocumentsDestination.shared
        }
    }
    
    init?(lx: String) {
        switch lx {
        case "dashboard":
            self = .DocumentProcessorInterface
        case "onboarding":
            self = .OnboardingInterface
        case "issuance":
            self = .IssuanceInterface
        case "settings":
            self = .SettingsInterface
        case "presentation":
            self = .IssuanceInterface
        case "app":
            self = .AppInterface
        case "transactions":
            self = .TransactionInterface
        case "sign":
            self = .SignInterface
        default:
            self = .none
        }
    }
}
