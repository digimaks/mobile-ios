// SPDX-License-Identifier: EUPL-1.2

//
//  SafariViewController.swift
//  edim
//
//  Created by Matīss Mamedovs on 21/03/2025.
//

import SafariServices
import Foundation
import UIKit
import SnapKit
@MainActor
final public class SafariViewController: UIViewController, Sendable {
 
    fileprivate var redirectUrl: String = ""
    var safariVC: SFSafariViewController!
    
    public init(redirectUrl: String) {
        self.redirectUrl = redirectUrl
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        safariVC = SFSafariViewController(url: URL(string: redirectUrl)!)
        safariVC.delegate = self
        self.present(safariVC, animated: true)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
}

extension SafariViewController: SFSafariViewControllerDelegate {
    nonisolated public func safariViewController(_ controller: SFSafariViewController, initialLoadDidRedirectTo URL: URL) {
        AppLog.debug(URL.absoluteString)
    }
}
