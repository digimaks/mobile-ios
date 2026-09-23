// SPDX-License-Identifier: EUPL-1.2

//
//  OverlayScreenView.swift
//  edim
//
//  Created by Matīss Mamedovs on 17/10/2025.
//



import Foundation
import UIKit
import SnapKit

class OverlayScreenView: UIView {
    
    fileprivate let logoImageView: UIImageView = UIImageView()
    
    @objc init() {
        super.init(frame: .zero)
        
        setUpView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func setUpView() {
        self.backgroundColor = Colors.BACKGROUND_COLOR
        
        logoImageView.image = UIImage(named: "logo")
        logoImageView.contentMode = .scaleAspectFit
        self.addSubview(logoImageView)
        
        logoImageView.snp.makeConstraints { make in
            make.centerX.centerY.equalToSuperview()
            make.height.width.equalTo(256)
        }
    }
}
