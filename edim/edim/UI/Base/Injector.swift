// SPDX-License-Identifier: EUPL-1.2

//
//  Injector.swift
//  edim
//
//  Created by Matīss Mamedovs on 10/01/2025.
//


public protocol FlowInjector: AnyObject {
    nonisolated func openContent(params: String, masterView: MasterViewProtocol?) async
}

open class BaseInjector {
    
    @MainActor public static let shared = BaseInjector()
    
    public var flowInjector: FlowInjector!
    
}
