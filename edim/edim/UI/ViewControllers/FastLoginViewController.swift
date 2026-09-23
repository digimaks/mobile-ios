// SPDX-License-Identifier: EUPL-1.2

//
//  FastLoginViewController.swift
//  edim
//
//  Created by Matīss Mamedovs on 10/04/2025.
//

import Foundation
import UIKit
import SnapKit
import AuthWrapperPackage
import FirebaseCrashlytics

@MainActor
final public class FastLoginViewController: BaseViewController {
    
    fileprivate let presenter: FastLoginPresenter
    
    fileprivate let logoImageView: UIImageView = UIImageView()
    fileprivate let titleLabel: UILabel = UILabel()
    fileprivate let loginButton: UIButton = UIButton()
    
    init(isRelogin: Bool) {
        presenter = FastLoginPresenter(isRelogin: isRelogin)
        
        super.init(nibName: nil, bundle: nil)
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
                
        self.presenter.attachView(view: self)
        setUp()
        Task {
            await WalletInstance.shared.loadDocuments()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                self.presenter.login()
            })
        }
    }
    
    
    override func setColors() {
        self.view.backgroundColor = Colors.BACKGROUND_COLOR
        self.titleLabel.textColor = Colors.FAST_LOGIN_CONTENT_COLOR
        self.loginButton.backgroundColor = Colors.ACCENT_COLOR
        self.loginButton.setTitleColor(Colors.BACKGROUND_COLOR, for: UIControl.State())
    }
    
    fileprivate func setUp() {
        // TO-DO
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.image = UIImage(named: "logo")
        self.view.addSubview(logoImageView)
        
        let width = self.view.frame.width - 30
        
        logoImageView.snp.makeConstraints { make in
            make.width.height.equalTo(250)
            make.centerY.equalToSuperview()
            make.centerX.equalToSuperview()
        }
        
        self.loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        self.loginButton.setTitle(Texts.LOGIN_TITLE, for: UIControl.State())
        self.loginButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        self.loginButton.clipsToBounds = true
        self.loginButton.layer.cornerRadius = 26.0
        self.loginButton.isHidden = true
        self.view.addSubview(loginButton)
        
        loginButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-50)
            make.width.equalTo(width)
            make.height.equalTo(48)
        }
    }
    
    @objc func loginTapped() {
        UIView.animate(withDuration: 0.3, animations: {
            self.loginButton.alpha = 0
        }, completion: { (value: Bool) in
            self.loginButton.isHidden = true
        })
        self.presenter.login()
    }
    
}

extension FastLoginViewController: FastLoginView {
    public func showLoginButton() {
        UIView.animate(withDuration: 0.3, animations: {
            self.loginButton.alpha = 1
        }, completion: { (value: Bool) in
            self.loginButton.isHidden = false
        })
    }
    
    public func dismiss() {
        self.dismiss(animated: true)
    }
}
