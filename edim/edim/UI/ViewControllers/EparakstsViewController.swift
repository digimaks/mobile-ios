// SPDX-License-Identifier: EUPL-1.2

//
//  EparakstsViewController.swift
//  edim
//
//  Created by Matīss Mamedovs on 10/01/2025.
//

import Foundation
import UIKit
import SnapKit
import WebKit

@MainActor
final public class EparakstsViewController: UIViewController, Sendable {
    
    var webView: WKWebView?
    
    var skip: Bool = true
    var once: Bool = true
    
    var authCode: String = ""
    fileprivate var codeChallange: String = ""
    fileprivate var codeVerifier: String = ""
    fileprivate var state: String = ""
    
    public weak var delegate: EparakstsAuthFinishedDelegate?
    
    fileprivate var isEparaksts: Bool = true
    
    
    private var isAuthInProgress = false
    
    
    init(isEparaksts: Bool) {
        self.isEparaksts = isEparaksts
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if authCode.isEmpty {
            self.delegate?.eparakstsAuthFinished(isSuccess: false)
        }
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = Colors.BACKGROUND_COLOR
        setUp()
    }
    
    fileprivate func setUp() {
        webView = WKWebView(frame: .zero, configuration: self.getWKWebViewConfiguration())
        
        webView?.navigationDelegate = self
        guard let webView else { return }
        self.view.addSubview(webView)
        webView.snp.makeConstraints { make in
            make.left.right.bottom.top.equalToSuperview()
        }
        startWebView()
    }
    
    @objc func startWebView() {
        // BULLETPROOF THAT CANNOT START WEBVIEW 2X IN A ROW
        guard !isAuthInProgress else { return }
        isAuthInProgress = true
        
        
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            WKWebsiteDataStore.default().removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
                                                    for: records,
                                                    completionHandler: {})
        }

        
        var absolute = AppApiProvider.shared.getEparakstsAuth()
        self.codeVerifier = PkceUtils.shared.generateCodeVerifier()
        self.codeChallange = PkceUtils.shared.generateCodeChallenge(codeVerifier: self.codeVerifier) ?? ""
        self.state = PkceUtils.shared.generateRandomState()
        absolute = absolute.replacingOccurrences(of: "{0}", with: self.codeChallange)
        absolute = absolute.replacingOccurrences(of: "{2}", with: self.state)
        absolute = absolute.replacingOccurrences(of: "{4}", with: AppApiProvider.shared.getApiClientID())
        
        if isEparaksts {
            if EparakstsHelper.shared.canOpenLocallyEparaksts() {
                absolute = absolute.replacingOccurrences(of: "{1}", with: "eparaksts:mobileid")
            } else {
                absolute = absolute.replacingOccurrences(of: "{1}", with: "eparaksts:mobileid:cross_device")
            }
        } else {
            absolute = absolute.replacingOccurrences(of: "{1}", with: "smartid")
        }
        
        
        if let url = URL(string: absolute) {
            webView?.load(URLRequest(url: url))
            webView?.allowsBackForwardNavigationGestures = true
        }
    }
    
    private func getWKWebViewConfiguration() -> WKWebViewConfiguration {
        webView?.scrollView.pinchGestureRecognizer?.isEnabled = false
        let source1 = "var meta = document.createElement('meta');" +
        "meta.name = 'viewport';" +
        "meta.content = 'width=device-width, initial-scale=1.0, user-scalable=no, viewport-fit=cover';" +
        "var head = document.getElementsByTagName('head')[0];" +
        "head.appendChild(meta);"
        
        let script1 = WKUserScript(source: source1, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        
        let userController = WKUserContentController()
        userController.addUserScript(script1)
        
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userController
        
        return configuration
    }
   
    public func checkForDeeplink(url: URL) -> Bool {
        if url.absoluteString.starts(with: "eparakstsid") {
            let tempURL = url
            let items = getQueryItems(tempURL)
            let base = tempURL.absoluteStringByTrimmingQuery() ?? ""
            var params: [URLQueryItem] = []
            for item in items {
                var value: String = item.value
                if item.key == "successurl" {
                    value = "digimaks:///resume_authn?url=\(item.value)"
                } else if item.key == "failureurl" {
                    value = "digimaks:///resume_authn?url=\(item.value)"
                }
                
                let param = URLQueryItem(name: item.key, value: value)
                params.append(param)
            }
            var result = URLComponents(string: base)
            result?.queryItems = params
            
            guard let resultURL = result?.url else { return true }
            UIApplication.shared.open(resultURL, options: [:], completionHandler: nil)
            return false
        } else if url.absoluteString.starts(with: "digimaks") {
            let items = getQueryItems(url)
            
            if let item = items["code"] {
                self.authCode = items["code"] ?? ""
                
                let returnedState = items["state"] ?? ""
                guard self.state == returnedState else {
                    AppLog.error("STATE MISMATCH - expected: \(self.state), got: \(returnedState)")
                    
                    SessionData.shared.setAuthToken("")
                    self.delegate?.eparakstsAuthFinished(isSuccess: false)
                    self.dismiss(animated: true)
                    
                    return false
                }
                
                TokenService.shared.getToken(grantType: "authorization_code", code: self.authCode, redirectUri: "digimaks://auth-done", codeVerifier: self.codeVerifier, completionCallback: { token in
                    SessionData.shared.setAuthToken(token.accessToken)
                    AppLog.debug("auth code is: " + self.authCode)
                    self.webView?.removeFromSuperview()
                    self.webView = nil
                    self.delegate?.eparakstsAuthFinished(isSuccess: true)
                    self.dismiss(animated: true)
                }, errorCallback: {
                    SessionData.shared.setAuthToken("")
                    self.webView?.removeFromSuperview()
                    self.webView = nil
                    self.delegate?.eparakstsAuthFinished(isSuccess: false)
                    self.dismiss(animated: true)
                })
            } else {
                SessionData.shared.setAuthToken("")
                self.webView?.removeFromSuperview()
                self.webView = nil
                self.delegate?.eparakstsAuthFinished(isSuccess: false)
                self.dismiss(animated: true)
                return false
            }
            
            return false
        }
        
        return true
    }
    
    func getQueryItems(_ urlString: URL) -> [String : String] {
        var queryItems: [String : String] = [:]
        let components: NSURLComponents? = getURLComonents(urlString.absoluteString)
        for item in components?.queryItems ?? [] {
            queryItems[item.name] = item.value?.removingPercentEncoding
        }
        return queryItems
    }
    
    func getURLComonents(_ urlString: String?) -> NSURLComponents? {
        var components: NSURLComponents? = nil
        let linkUrl = URL(string: urlString?.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? "")
        if let linkUrl = linkUrl {
            components = NSURLComponents(url: linkUrl, resolvingAgainstBaseURL: true)
        }
        return components
    }
}

extension EparakstsViewController: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping @MainActor (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url {
            AppLog.debug(url.absoluteString)
            let val = self.checkForDeeplink(url: url)
            AppLog.debug("AAAAAAAA:\(val ? "YES" : "NO" )")
            decisionHandler(val ? .allow : .cancel)
        } else {
            AppLog.debug("AAAAAAAA:\("NO")")
            decisionHandler(.cancel)
        }
    }
}

public extension URL {
    func absoluteStringByTrimmingQuery() -> String? {
        if let urlcomponents = NSURLComponents(url: self, resolvingAgainstBaseURL: false) {
            urlcomponents.query = nil
            return urlcomponents.string
        }
        return nil
    }
}

public protocol EparakstsAuthFinishedDelegate: AnyObject {
    func eparakstsAuthFinished(isSuccess: Bool)
}
