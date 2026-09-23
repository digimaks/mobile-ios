// SPDX-License-Identifier: EUPL-1.2

//
//  BaseViewController.swift
//  edim
//
//  Created by Matīss Mamedovs on 12/03/2025.
//

import Foundation
import UIKit

public class BaseViewController: UIViewController, Sendable {

    
    deinit {
        NotificationCenter.default.removeObserver(self)
        
        AppLog.debug("🔥 deinit \(self)")
    }

    
    public override func viewDidLoad() {
        super.viewDidLoad()

        // Start manager
        _ = UIEnvironmentManager.shared

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(environmentDidChange),
            name: UIEnvironmentManager.didChangeNotification,
            object: nil
        )

        if #available(iOS 17.0, *) {
            registerForTraitChanges(
                [UITraitUserInterfaceStyle.self, UITraitPreferredContentSizeCategory.self]
            ) { (self: Self, previous: UITraitCollection) in
                self.applyEnvironment()
            }
        }
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyEnvironment()
    }

    @objc private func environmentDidChange() {
        applyEnvironment()
    }

    func applyEnvironment() {
        applyAccessibility()
        setColors()
    }

    func setColors() {}
    func applyAccessibility() {}
}
