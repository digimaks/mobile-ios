// SPDX-License-Identifier: EUPL-1.2

//
//  LVRTCAuthViewController.swift
//  edim
//
//  Created by Matīss Mamedovs on 17/03/2025.
//


import Foundation
import UIKit
import SnapKit
import WebKit

@MainActor
final public class LVRTCAuthViewController: UIViewController, Sendable {
    
    private static let sharedProcessPool = WKProcessPool()
    
    var webView: WKWebView?
    
    fileprivate var redirectUrl: String = ""
    fileprivate var url: URL!
    
    weak var delegate: IdentitiesResultDelegate?
        
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    public init(redirectUrl: String) {
        self.redirectUrl = redirectUrl
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = Colors.BACKGROUND_COLOR
        setUp()
        presentationController?.delegate = self
        
        
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(appDidBecomeActive),
                name: UIApplication.didBecomeActiveNotification,
                object: nil
            )

    }
    
    @objc private func appDidBecomeActive() {
        AppLog.debug("App became active → restoring cookies")
        
        guard let webView else { return }
        
        restoreCorrelationCookieIfNeeded()
    }

    fileprivate func setUp() {
        webView = WKWebView(frame: .zero, configuration: getWKWebViewConfiguration())
        webView?.navigationDelegate = self
        
        guard let webView else { return }
        
        self.view.addSubview(webView)
        webView.snp.makeConstraints { make in
            make.left.right.top.bottom.equalToSuperview()
        }
        
        startWebView()
    }
        
    @objc func startWebView() {
        guard let url = URL(string: self.redirectUrl),
              let webView else { return }
        
        self.url = url
                
        syncCookies(to: webView) { [weak self] in
            guard let self else { return }
            
            let request = URLRequest(url: url)
            webView.load(request)
            webView.allowsBackForwardNavigationGestures = true
            
            self.printCookies()
        }
    }
        
    private func getWKWebViewConfiguration() -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.processPool = LVRTCAuthViewController.sharedProcessPool
        
        let source = """
        var meta = document.createElement('meta');
        meta.name = 'viewport';
        meta.content = 'width=device-width, initial-scale=1.0, user-scalable=no, viewport-fit=cover';
        var head = document.getElementsByTagName('head')[0];
        head.appendChild(meta);
        """
        
        let script = WKUserScript(
            source: source,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        
        let userController = WKUserContentController()
        userController.addUserScript(script)
        
        configuration.userContentController = userController
        
        return configuration
    }
        
    private func syncCookies(to webView: WKWebView, completion: @escaping () -> Void) {
        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        let cookies = HTTPCookieStorage.shared.cookies ?? []
        
        guard !cookies.isEmpty else {
            completion()
            return
        }
        
        let group = DispatchGroup()
        
        for cookie in cookies {
            group.enter()
            cookieStore.setCookie(cookie) {
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion()
        }
    }
    
    
    func persistCorrelationCookie() {
        webView?.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            if let cookie = cookies.first(where: { $0.name.contains("Correlation") }) {
                AppLog.debug("Saving correlation cookie:", cookie)
                
                let data = try? NSKeyedArchiver.archivedData(withRootObject: cookie, requiringSecureCoding: false)
                UserDefaults.standard.set(data, forKey: "correlation_cookie")
            }
        }
    }

    
    func restoreCorrelationCookieIfNeeded() {
        guard let data = UserDefaults.standard.data(forKey: "correlation_cookie"),
              let cookie = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? HTTPCookie else {
            return
        }
        
        AppLog.debug("Restoring correlation cookie:", cookie)
        
        let store = webView?.configuration.websiteDataStore.httpCookieStore
        AppLog.debug("Set cookie:", cookie)
        store?.setCookie(cookie)
    }

    public func checkForDeeplink(url: URL) -> Bool {
        let absolute = url.absoluteString
        
        if absolute.starts(with: "eparakstsid") {
            persistCorrelationCookie()
            let items = getQueryItems(url)
            let base = url.absoluteStringByTrimmingQuery() ?? ""
            
            var params: [URLQueryItem] = []
            
            for item in items {
                var value: String = item.value
                
                if item.key == "successurl" || item.key == "failureurl" {
                    value = "digimaks:///resume_authn?url=\(item.value)"
                }
                
                params.append(URLQueryItem(name: item.key, value: value))
            }
            
            var result = URLComponents(string: base)
            result?.queryItems = params
            
            guard let resultURL = result?.url else { return true }
            
            UIApplication.shared.open(resultURL)
            return false
            
        } else if absolute.contains("identitiesResult") {
            if let redirect = getQueryItems(url)["redirect_uri"] {
                let last = redirect.components(separatedBy: "/").last ?? ""
                
                cleanup()
                delegate?.identitiesResult(result: last)
                dismiss(animated: true)
                return false
            }
            
        } else if absolute.starts(with: "digimaks") {
            cleanup()
            
            if absolute.contains("eseal-success") {
                delegate?.signResult(success: true)
            } else {
                delegate?.signResult(success: false)
            }
            
            dismiss(animated: true)
            return false
        }
        
        return true
    }
        
    private func cleanup() {
        webView?.stopLoading()
        webView?.navigationDelegate = nil
        webView?.removeFromSuperview()
        webView = nil
    }
    
    func getQueryItems(_ url: URL) -> [String: String] {
        var queryItems: [String: String] = [:]
        
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems?.forEach {
            queryItems[$0.name] = $0.value?.removingPercentEncoding
        }
        
        return queryItems
    }
    
    func printCookies() {
        webView?.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            AppLog.debug("==== WEBVIEW COOKIES ====")
            cookies.forEach { AppLog.debug($0) }
        }
    }
}

extension LVRTCAuthViewController: UIAdaptivePresentationControllerDelegate {
    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        delegate?.signResult(success: false)
    }
}

extension LVRTCAuthViewController: WKNavigationDelegate {
    
    public func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping @MainActor (WKNavigationActionPolicy) -> Void
    ) {
        if let url = navigationAction.request.url {
            AppLog.debug("NAV:", url.absoluteString)
            
            let shouldAllow = checkForDeeplink(url: url)
            decisionHandler(shouldAllow ? .allow : .cancel)
        } else {
            decisionHandler(.cancel)
        }
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            AppLog.debug("==== AFTER LOAD COOKIES ====")
            for cookie in cookies {
                if cookie.name.contains("Correlation") {
                    AppLog.debug("FOUND CORRELATION COOKIE:", cookie)
                }
            }
        }
    }

}

public protocol IdentitiesResultDelegate: AnyObject {
    func identitiesResult(result: String)
    func signResult(success: Bool)
}
