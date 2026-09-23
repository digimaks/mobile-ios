// SPDX-License-Identifier: EUPL-1.2

//
//  AppFlowConfigurator.swift
//  edim
//
//  Created by Matīss Mamedovs on 10/01/2025.
//

@MainActor
final public class AppFlowConfigurator: FlowInjector, Sendable {
        
    @MainActor public static let shared = AppFlowConfigurator()

    nonisolated public func openContent(params: String = "",masterView: MasterViewProtocol?) async {
        let vc = await ContentViewController(params: params)
        await masterView?.push(vc: vc)
    }
}
