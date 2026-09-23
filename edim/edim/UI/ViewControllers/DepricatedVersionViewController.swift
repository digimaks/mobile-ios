// SPDX-License-Identifier: EUPL-1.2

//
//  DepricatedVersionViewController.swift
//  edim
//
//  Created by Matīss Mamedovs on 13/05/2026.
//

import Foundation
import UIKit
import SnapKit
import AuthWrapperPackage
import FirebaseCrashlytics

@MainActor
final public class DepricatedVersionViewController: BaseViewController {
    
    fileprivate let warningImageView: UIImageView = UIImageView()
    fileprivate let titleLabel: UILabel = UILabel()
    fileprivate let subtitleLabel: UILabel = UILabel()
    fileprivate let updateButton: UIButton = UIButton()
    
    fileprivate var storeURL: String?
    
    init(storeURL: String) {
        self.storeURL = storeURL
        
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
        
        self.setUpView()
    }
    
    
    override func setColors() {
        self.view.backgroundColor = Colors.BACKGROUND_COLOR
        self.titleLabel.textColor = Colors.LABEL_COLOR
        self.subtitleLabel.textColor = Colors.LABEL_COLOR
        self.updateButton.backgroundColor = Colors.ACCENT_COLOR
        self.updateButton.setTitleColor(Colors.BACKGROUND_COLOR, for: UIControl.State())
    }
    
    fileprivate func setUpView() {
        warningImageView.contentMode = .scaleAspectFit
        warningImageView.image = UIImage(named: "warning")?.withTintColor(Colors.WARNING_IMAGE_COLOR)
        self.view.addSubview(warningImageView)
                
        warningImageView.snp.makeConstraints { make in
            make.width.height.equalTo(80)
            make.centerY.equalToSuperview().offset(-70)
            make.centerX.equalToSuperview()
        }
        
        self.titleLabel.text = Texts.DEPRICATED_VERSION_TITLE
        self.titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .semibold)
        self.titleLabel.textAlignment = .center
        self.titleLabel.numberOfLines = 0
        self.view.addSubview(titleLabel)
        
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(warningImageView.snp.bottom).offset(40)
            make.left.equalToSuperview().offset(15)
            make.right.equalToSuperview().offset(-15)
        }
        
        self.subtitleLabel.text = Texts.DEPRICATED_VERSION_SUBTITLE
        self.subtitleLabel.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        self.subtitleLabel.textAlignment = .center
        self.subtitleLabel.numberOfLines = 0
        self.view.addSubview(subtitleLabel)
        
        subtitleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(15)
            make.left.equalToSuperview().offset(15)
            make.right.equalToSuperview().offset(-15)
        }
        
        self.updateButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        self.updateButton.setTitle(Texts.DEPRICATED_VERSION_BUTTON_TITLE, for: UIControl.State())
        self.updateButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        self.updateButton.clipsToBounds = true
        self.updateButton.layer.cornerRadius = 26.0
        self.view.addSubview(updateButton)
        
        updateButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-50)
            make.width.equalTo(self.view.frame.width - 30)
            make.height.equalTo(48)
        }
    }
    
    @objc func buttonTapped() {
        if let storeURL = storeURL, let url = URL(string: storeURL) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:])
            }
        }
    }
}
