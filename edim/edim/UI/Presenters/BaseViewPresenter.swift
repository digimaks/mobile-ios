// SPDX-License-Identifier: EUPL-1.2

//
//  BaseViewPresenter.swift
//  edim
//
//  Created by Matīss Mamedovs on 11/06/2025.
//

import UIKit
import Foundation

@MainActor
open class BaseViewPresenter: NSObject {
    
    public weak var flowInjector: FlowInjector? = BaseInjector.shared.flowInjector

    public override init() {
        super.init()
    }
}
