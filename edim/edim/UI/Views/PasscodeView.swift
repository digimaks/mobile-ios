// SPDX-License-Identifier: EUPL-1.2

//
//  PasscodeView.swift
//  edim
//
//  Created by Matīss Mamedovs on 14/12/2024.
//

import Foundation
import UIKit

@MainActor
public protocol PasscodeView: MasterViewProtocol {
    func incorrectPin()
    func setPinEmpty()
    func confirmationEnded(didChange: Bool)
    func showFailedPin(title: String)
}
