// SPDX-License-Identifier: EUPL-1.2

//
//  Destination.swift
//  edim
//
//  Created by Matīss Mamedovs on 10/12/2024.
//
import WebKit

@MainActor public protocol DestinationProtocol: NSObject, Sendable {
    func setLocal(parent: UIViewController, masterProtocol: MasterViewProtocol?, item: LocalInitObject?, for webView: WKWebView)
    func start()
    func decodingError()
    func inject<T: Codable>(id: String, status: ResponseStatus, message: String?, data: T?, error: String?) async
    func navigate(pathName: String, params: String, query: String)
    func emitPaymentStatus(status: String)
}

@MainActor
public class Destination: NSObject, DestinationProtocol, Sendable {
    nonisolated public func decodingError()  {}
    nonisolated public func start()  {}
    
    public weak var flowInjector: FlowInjector? = BaseInjector.shared.flowInjector

    var parent: UIViewController?
    var masterProtocol: MasterViewProtocol?
    @MainActor var local: LocalInitObject?
    var webView: WKWebView?
    
    @MainActor public func setLocal(parent: UIViewController, masterProtocol: MasterViewProtocol?, item: LocalInitObject?, for webView: WKWebView) {
        self.parent = parent
        self.masterProtocol = masterProtocol
        self.local = item
        self.webView = webView
    }
    
    @MainActor public func inject<T: Codable>(id: String, status: ResponseStatus, message: String?, data: T?, error: String? = nil) async  {
        let obj = LocalCommonResponseObject(id: id, status: status, message: message, data: data, error: error)
        do {
            let jsonData = try JSONEncoder().encode(obj)
            let jsonString = String(data: jsonData, encoding: .utf8)
            Task {
                guard let jsonString else { return }
                
                AppLog.debug("LX-RESPONSE: response is \(jsonString)")
                try await self.webView?.evaluateJavaScript("""
                    window.dispatchEvent(new CustomEvent('lx-embed-response', {
                        detail: \(jsonString)
                    }));
                    """)
            }
        } catch {
            AppLog.error("Encoding failed: \(error)")
        }
    }
    
    @MainActor public func navigate(pathName: String, params: String = "", query: String = "") {
        guard let webView = self.webView else { return }
        AppLog.debug("LX-NAVIGATION: NAVIGATE TO \(pathName)")
        CommunicationHelper.shared.navigate(webView: webView, pathName: pathName, params: params, query: query)
    }
    
    @MainActor public func emitPaymentStatus(status: String) {
        guard let webView = self.webView else { return }
        AppLog.debug("LX-EMIT-PAYMENT-STATUS: \(status)")
        CommunicationHelper.shared.emitPaymentStatus(webView: webView, status: status)
    }
}
