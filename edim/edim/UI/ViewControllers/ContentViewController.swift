// SPDX-License-Identifier: EUPL-1.2

//
//  ContentViewController.swift
//  edim
//
//  Created by Matīss Mamedovs on 01/11/2024.
//

import UIKit
import UIWrapperPackage
import SnapKit
import EudiWalletKit
import AuthWrapperPackage
import UtilitiesPackage
import WebKit
import SafariServices


class ContentViewController: BaseViewController, ContentView {
    
    fileprivate let walletInstance: WalletInstance = WalletInstance.shared
    var wrapperView: WrapperView?
    
    fileprivate var tempPasscode: String = ""
    fileprivate var params: String = ""
    
    
    private var edgePan: UIScreenEdgePanGestureRecognizer?
    private var isSwiping = false
    
    private var isViewVisible = false

    public init(params: String) {
        
        super.init(nibName: nil, bundle: nil)
        self.params = params
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
        isViewVisible = true
        tryProcessPendingDeeplink()
    }

    public override func setColors() {
        self.view.backgroundColor = Colors.BACKGROUND_COLOR
        wrapperView?.backgroundColor = Colors.BACKGROUND_COLOR
        wrapperView?.getWebView()?.backgroundColor = Colors.BACKGROUND_COLOR
    }
    
    public override func applyAccessibility() {
        if let webview = self.wrapperView?.getWebView() {
            CommunicationHelper.shared.emitEnvironmentChange(webView: webview, scaleFactor: AppDestination.shared.getScaleFactor(), reduceMotion: UIEnvironmentManager.shared.isReduceMotionEnabled, reduceTransparency: UIEnvironmentManager.shared.isReduceTransparencyEnabled)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
         
        self.setColors()
        self.addUI()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.handleDeeplink),
                                               name: NSNotification.Name(SessionData.DEEPLINK_NOTIFICATION_NAME),
                                               object: nil)
        
        
        NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleAppDidBecomeActive),
                name: UIApplication.didBecomeActiveNotification,
                object: nil
            )

        
        addSwipeBack()
    }
    
    
    @objc private func handleAppDidBecomeActive() {
        tryProcessPendingDeeplink()
    }

    
    fileprivate func addSwipeBack() {
        edgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleEdgePan(_:)))
        edgePan?.edges = .left
        edgePan?.delegate = self
        if let edgePan = edgePan {
            view.addGestureRecognizer(edgePan)
        }
    }
    
    
    @objc private func handleEdgePan(_ gesture: UIScreenEdgePanGestureRecognizer) {
            guard let host = gesture.view else { return }
            let width = max(host.bounds.width, 1)
            let translationX = gesture.translation(in: host).x
            
            let signedTranslation = translationX
            
            let progress = max(0, min(1, signedTranslation / width))
            
            switch gesture.state {
            case .began:
                isSwiping = true
                sendProgressToJS(progress)
                
            case .changed:
                sendProgressToJS(progress)
                
            case .ended, .cancelled, .failed:
                let velocityX = gesture.velocity(in: host).x
                let signedVelocity = velocityX
                let shouldFinish = (progress > 0.5) || (signedVelocity > 500)
                
                if shouldFinish {
                    sendProgressToJS(1.0)
                } else {
                    sendProgressToJS(0.0)
                }
                isSwiping = false
                
            default:
                break
            }
        }
    
    func sendProgressToJS(_ progress: Double) {
        AppLog.debug("PROGRESS IS: \(progress)")
        if progress > 0.5 {
            if let webView = wrapperView?.getWebView() {
                CommunicationHelper.shared.setGoBackProgress(webView: webView, value: progress)
            }
        }
    }
    
    
    public func navigateToBiometry(passcode: String) {
        self.tempPasscode = passcode
        if let webView = wrapperView?.getWebView() {
            CommunicationHelper.shared.navigate(webView: webView, pathName: "activation", params: "step: '2'")
        }
    }

    private func tryProcessPendingDeeplink() {
        guard
            isViewVisible,
            let deeplink = DeepLinkCoordinator.shared.consumePresentationDeeplink()
        else {
            return
        }

        startPresentation(result: deeplink)
    }

    
    fileprivate func startPresentation(result: String) {
        Task {
            do {
                let res = try await IssuanceDestination.shared.startDeeplinkPresentation(result: result)
                
                if let webView = wrapperView?.getWebView() {
                    if res {
                        CommunicationHelper.shared.navigate(webView: webView, pathName: "dashboard")
                        CommunicationHelper.shared.navigate(webView: webView, pathName: "documentPresentation")
                    } else {
                        CommunicationHelper.shared.navigate(webView: webView, pathName: "documentOfferManual", params: "status: 'presentationError'")
                    }
                }
            } catch {
                AppLog.error(error)
            }
        }
    }
    
    @objc public func handleDeeplink() {
        if let filePath = SessionData.shared.getDeeplinkFilePath(), let webView = self.wrapperView?.getWebView() {
            CommunicationHelper.shared.navigate(webView: webView, pathName: "dashboard")
            let params: String = "filePath: '\(filePath.escapedForJavaScriptSingleQuotedLiteral())' , type: 'null'"
            CommunicationHelper.shared.navigate(webView: webView, pathName: "sign", params: params)
        }
    }
}

extension ContentViewController {
    fileprivate func addUI() {
        let route: String
        let hasMainPid: Bool = UserDefaultsManager.shared.get(key: OnboardingDestination.MAIN_PID_ISSUED) ?? false
        if let val = SessionData.shared.getDeeplinkFilePath() {
            route = "sign/\(val)/null"
        } else {
            route = hasMainPid ? "dashboard" : "activation"
            
        }

        wrapperView = WrapperView(resourcePath: "index", interfaces: DestinationInterface.allCases.map({ $0.rawValue }), route: route, params: self.params, color: Colors.BACKGROUND_COLOR, baseURL: AppApiProvider.shared.getBaseURL())
        wrapperView?.backgroundColor = Colors.BACKGROUND_COLOR
        wrapperView?.delegate = self
        if let wrapperView = wrapperView {
            self.view.addSubview(wrapperView)
            
            wrapperView.snp.makeConstraints { make in
                make.top.left.right.bottom.equalToSuperview()
            }
        }
        
        tryProcessPendingDeeplink()
    }
}

@MainActor
extension ContentViewController: WrapperMessageProtocol {
    nonisolated public func openExternalUrl(url: URL) {
        let safariVC = SFSafariViewController(url: url)
        safariVC.modalPresentationStyle = .pageSheet // or .formSheet for iPad
        safariVC.dismissButtonStyle = .close // Optional: shows a close button
        present(safariVC, animated: true, completion: nil)
    }
    
    nonisolated public func messageReceived(interface: String, body: NSDictionary, from webView: WKWebView) {
        guard let id = body["id"] as? String else { return }
        
        guard let funcName = body["function"] as? String else { return }
        AppLog.debug("ID is \(id) for function \(funcName) and interface: \(interface)")
        let data = body["data"] as? [String: any Sendable]
        guard let funcObject = WebViewFunctionObject(rawValue: funcName) else { return }
        
        Task {
            if let interface = DestinationInterface(lx: interface) {
                let localInit = LocalInitObject(id: id, funcName: funcObject, params: data)
                await interface.getDestination().setLocal(parent: self, masterProtocol: self, item: localInit, for: webView)
                await (interface.getDestination() as? SettingsDestionation)?.savePasscode(passcode: self.tempPasscode)
                await interface.getDestination().start()
            }
        }
    }
}

extension ContentViewController: UIGestureRecognizerDelegate {
    
}

@MainActor
public protocol ContentView: MasterViewProtocol {}
