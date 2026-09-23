// SPDX-License-Identifier: EUPL-1.2

//
//  UIEnvironmentManager.swift
//  edim
//
//  Created by Matīss Mamedovs on 16/06/2026.
//
import Foundation
import UIKit


final class UIEnvironmentManager {

    @MainActor static let shared = UIEnvironmentManager()

    private init() {
        startObserving()
    }

    // MARK: - Public state

    @MainActor var isReduceMotionEnabled: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    @MainActor var isReduceTransparencyEnabled: Bool {
        UIAccessibility.isReduceTransparencyEnabled
    }

    // MARK: - Notification

    static let didChangeNotification = Notification.Name("UIEnvironmentManager.didChange")

    private func notify() {
        NotificationCenter.default.post(name: Self.didChangeNotification, object: nil)
    }

    // MARK: - Observing

    private func startObserving() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(accessibilityChanged),
            name: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(accessibilityChanged),
            name: UIAccessibility.reduceTransparencyStatusDidChangeNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(contentSizeChanged),
            name: UIContentSizeCategory.didChangeNotification,
            object: nil
        )
    }

    @objc private func accessibilityChanged() {
        notify()
    }

    @objc private func contentSizeChanged() {
        notify()
    }
}
