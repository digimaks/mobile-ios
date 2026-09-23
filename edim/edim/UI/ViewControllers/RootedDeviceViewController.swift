// SPDX-License-Identifier: EUPL-1.2

//
//  RootedDeviceViewController.swift
//  edim
//
//  Created by Matīss Mamedovs on 11/03/2025.
//

import Foundation
import UIKit
import SnapKit


@MainActor
final public class RootedDeviceViewController: BaseViewController {
    public enum DEVICE_SECURITY_ERROR {
        case rooted, passcode
    }
    
    fileprivate let warningImageView: UIImageView = UIImageView()
    fileprivate let titleLabel: UILabel = UILabel()
    fileprivate let subtitleLabel: UILabel = UILabel()
    fileprivate let helpLabel: UILabel = UILabel()
    
    fileprivate var errorType: DEVICE_SECURITY_ERROR?
    
    init(type: DEVICE_SECURITY_ERROR) {
        self.errorType = type
        
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
        
        self.setColors()
        setUp()
        setTexts()
    }
    
    override func setColors() {
        self.view.backgroundColor = Colors.BACKGROUND_COLOR
        warningImageView.image = UIImage(named: "ic_warning")?.withTintColor(Colors.LABEL_COLOR)
        self.titleLabel.textColor = Colors.LABEL_COLOR
        self.subtitleLabel.textColor = Colors.LABEL_COLOR
        self.helpLabel.textColor = Colors.LABEL_COLOR
    }
    
    fileprivate func setUp() {
        warningImageView.contentMode = .scaleAspectFit
        self.view.addSubview(warningImageView)
        
        warningImageView.snp.makeConstraints { make in
            make.width.height.equalTo(96)
            make.centerY.equalToSuperview().offset(-60)
            make.centerX.equalToSuperview()
        }
        
        
        self.titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        self.titleLabel.textAlignment = .left
        self.titleLabel.numberOfLines = 0
        self.view.addSubview(titleLabel)
        
        titleLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(30)
            make.top.equalTo(self.warningImageView.snp.bottom).offset(60)
        }
        
        self.subtitleLabel.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        self.subtitleLabel.textAlignment = .left
        self.subtitleLabel.numberOfLines = 0
        self.view.addSubview(subtitleLabel)
        
        subtitleLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(30)
            make.top.equalTo(self.titleLabel.snp.bottom).offset(15)
        }
        
        self.helpLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        self.helpLabel.textAlignment = .center
        self.helpLabel.numberOfLines = 0
        self.view.addSubview(helpLabel)
        
        helpLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.left.equalToSuperview().offset(30)
            make.right.equalToSuperview().offset(-30)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-15)
        }
    }
    
    fileprivate func setTexts() {
        if let type = self.errorType {
            let title: String = Texts.ROOTED_DEVICE_TITLE
            let help: String = Texts.ROOTED_DEVICE_HELP
            let subtitle: String

            switch type {
            case .rooted:
                subtitle = Texts.ROOTED_DEVICE_SUBTITLE
            case .passcode:
                subtitle = Texts.NO_PASSCODE_DEVICE_SUBTITLE
            }
            
            self.titleLabel.text = title
            self.subtitleLabel.text = subtitle
            self.helpLabel.text = help
        }
    }
}
