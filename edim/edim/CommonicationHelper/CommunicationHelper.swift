// SPDX-License-Identifier: EUPL-1.2

//
//  CommunicationHelper.swift
//  edim
//
//  Created by Matīss Mamedovs on 31/01/2025.
//

import UIKit
import Foundation
import WebKit

final public class CommunicationHelper {
    
    @MainActor static let shared = CommunicationHelper()
    
    @MainActor public func navigate(webView: WKWebView, pathName: String, params: String = "", query: String = "") {
        let safePathName = pathName.escapedForJavaScriptSingleQuotedLiteral()
        let str: String
        if params.isEmpty {
            str = """
                window.dispatchEvent(
                    new CustomEvent('lx-navigation', {
                      detail: {
                        path: '\(safePathName)',
                      },
                    })
                  );
                """
        } else if query.isEmpty {
            str = """
                window.dispatchEvent(
                    new CustomEvent('lx-navigation', {
                      detail: {
                        path: '\(safePathName)',
                        params: { \(params) },
                      },
                    })
                  );
                """
        } else {
            str = """
                window.dispatchEvent(
                    new CustomEvent('lx-navigation', {
                      detail: {
                        path: '\(safePathName)',
                        params: { \(params) },
                        query: { \(query) },
                      },
                    })
                  );
                """
        }
        webView.evaluateJavaScript(str)
    }
    
    @MainActor public func emitPaymentStatus(webView: WKWebView, status: String) {
        let safeStatus = status.escapedForJavaScriptSingleQuotedLiteral()
        let str: String = """
                window.dispatchEvent(
                    new CustomEvent('lx-payment-status', {
                      detail: {
                        status: '\(safeStatus)',
                      },
                    })
                  );
                """
        webView.evaluateJavaScript(str)
    }
    
    @MainActor public func setGoBackProgress(webView: WKWebView, value: Double) {
        let str: String = """
                window.dispatchEvent(
                    new CustomEvent('lx-native-back')
                  );
                """
        webView.evaluateJavaScript(str)
    }
    
    
    @MainActor public func emitEnvironmentChange(
        webView: WKWebView,
        scaleFactor: Double,
        reduceMotion: Bool,
        reduceTransparency: Bool) {
        let js = """
        window.dispatchEvent(
            new CustomEvent('lx-native-state-change', {
                detail: {
                    scaleFactor: \(scaleFactor),
                    reduceMotion: \(reduceMotion),
                    reduceTransparency: \(reduceTransparency)
                }
            })
        );
        """

        webView.evaluateJavaScript(js)
    }

}
