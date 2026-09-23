// SPDX-License-Identifier: EUPL-1.2

//
//  MasterViewProtocol.swift
//  edim
//
//  Created by Matīss Mamedovs on 10/01/2025.
//

import Foundation
import UIKit

@MainActor
public protocol MasterViewProtocol: AnyObject, Sendable {
    func push(vc: UIViewController) async
}

public extension MasterViewProtocol where Self: UIViewController {
    @MainActor func push(vc: UIViewController) {
        navigationController?.pushViewController(vc, animated: true)
    }
}
