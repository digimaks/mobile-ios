// SPDX-License-Identifier: EUPL-1.2

//
//  AppLog.swift
//  edim
//
//  Created by Matīss Mamedovs on 21/11/2024.

import Foundation
import os

enum AppLog {
    
    private static let subsystem = Bundle.main.bundleIdentifier ?? "lv.zzdats.edim"
    
    private static func logger(for file: String) -> Logger {
        let category = (file as NSString).lastPathComponent
            .replacingOccurrences(of: ".swift", with: "")
        return Logger(subsystem: subsystem, category: category)
    }
    
    private static func render(_ items: [Any]) -> String {
        items.map { String(describing: $0) }.joined(separator: " ")
    }
    
    /// Developer tracing. Stripped entirely from non-DEBUG builds.
    static func debug(_ items: Any..., file: String = #fileID) {
        #if DEBUG
        logger(for: file).debug("\(render(items), privacy: .private)")
        #endif
    }
    
    /// Recoverable failures. Retained in release builds but redacted by the system.
    static func error(_ items: Any..., file: String = #fileID) {
        logger(for: file).error("\(render(items), privacy: .private)")
    }
}

