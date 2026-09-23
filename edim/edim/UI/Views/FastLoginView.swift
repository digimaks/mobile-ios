// SPDX-License-Identifier: EUPL-1.2

//
//  FastLoginView.swift
//  edim
//
//  Created by Matīss Mamedovs on 10/04/2025.
//

import Foundation
import UIKit

@MainActor
public protocol FastLoginView: MasterViewProtocol {
    func showLoginButton()
    func dismiss()
}
