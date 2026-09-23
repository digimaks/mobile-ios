// SPDX-License-Identifier: EUPL-1.2

//
//  AppDelegateHelper.swift
//  edim
//
//  Created by Matīss Mamedovs on 17/12/2024.
//

import Foundation
import UIKit

final public class AppDelegateHelper: Sendable {
    public static let shared = AppDelegateHelper()
    
    @MainActor public func setUpNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.shadowImage = UIImage()
        appearance.shadowColor = .clear
        appearance.backgroundColor = .white
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
}
