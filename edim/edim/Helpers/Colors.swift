// SPDX-License-Identifier: EUPL-1.2

//
//  Colors.swift
//  edim
//
//  Created by Matīss Mamedovs on 31/01/2025.
//

import Foundation
import UIKit
import DeviceInformationPackage

@MainActor
public struct Colors: Sendable {
    
    fileprivate static func themed(light: String, dark: String) -> UIColor {
        switch DeviceInfoManager.shared.theme {
        case .light:
            return UIColor(hexString: light)
        case .dark:
            return UIColor(hexString: dark)
        }
    }
    
    static var BACKGROUND_COLOR: UIColor {
        themed(light: "#F5EFFF", dark: "#18151d")
    }
    
    static var ACCENT_COLOR: UIColor {
        themed(light: "#8232F7", dark: "#BA74FF")
    }
    
    static var LABEL_COLOR: UIColor {
        themed(light: "#3C402B", dark: "#e3dfd6")
    }
    
    static var PASSCODE_PIN_BORDER_COLOR: UIColor {
        themed(light: "#C1BFB5", dark: "#e3dfd6")
    }
    
    static var PIN_FILL_BLACK_COLOR: UIColor {
        themed(light: "#3C402B", dark: "#e3dfd6")
    }
    
    static var PIN_KEY_BUTTON_COLOR: UIColor {
        themed(light: "#FBFBFB", dark: "#3c3936")
    }
    
    static var FAST_LOGIN_CONTENT_COLOR: UIColor {
        themed(light: "#0042BA", dark: "#e3dfd6")
    }
    
    static var FAST_LOGIN_BUTTON_TEXT_COLOR: UIColor {
        themed(light: "#FFFFFF", dark: "#292826")
    }
    
    static var WARNING_IMAGE_COLOR: UIColor {
        themed(light: "#F2B8B5", dark: "#F2B8B5")
    }
}


extension UIColor {
    convenience init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}
