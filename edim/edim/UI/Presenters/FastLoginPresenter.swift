// SPDX-License-Identifier: EUPL-1.2

//
//  FastLoginPresenter.swift
//  edim
//
//  Created by Matīss Mamedovs on 10/04/2025.
//

import AuthWrapperPackage
import Foundation

@MainActor
public class FastLoginPresenter: BaseViewPresenter {
    
    fileprivate var loginView: FastLoginView?
    
    fileprivate let isRelogin: Bool
    
    init(isRelogin: Bool) {
        self.isRelogin = isRelogin
        
        super.init()
    }
    
    public func attachView(view: FastLoginView) {
        self.loginView = view
    }
    
    public func login() {
        Task {  [weak self] in
            
            guard let self = self else { return }

            do {
                if let success = try? await BiometricsManager.shared.evaluatePolicyWithPasscode() {
                    if isRelogin {
                        self.loginView?.dismiss()
                    } else {
                        await self.flowInjector?.openContent(params: "", masterView: self.loginView)
                    }
                } else {
                    self.loginView?.showLoginButton()
                }
            }
        }
    }
}
