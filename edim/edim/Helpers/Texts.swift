// SPDX-License-Identifier: EUPL-1.2

//
//  Texts.swift
//  edim
//
//  Created by Matīss Mamedovs on 12/02/2025.
//

import UtilitiesPackage

@MainActor
public struct Texts: Sendable {
    static var lang: Language = Language(rawValue: UserDefaultsManager.shared.get(key: AppDestination.LANGUAGE_CODE) ?? "lv") ?? .lv
    
    static var ONBOARDING_HEADER_TITLE: String {
        switch lang {
        case .lv:
            return "Identitātes pievienošana"
        case .en:
            return "Add identity"
        }
    }
    
    static var ONBOARDING_CREATE_PIN_TITLE: String {
        switch lang {
        case .lv:
            return "Izveidojiet un atceraties savu PIN"
        case .en:
            return "Create and memorize your PIN"
        }
    }
    
    static var ONBOARDING_CONFIRM_PIN_TITLE: String {
        switch lang {
        case .lv:
            return "Atkārtojiet PIN"
        case .en:
            return "Repeat your PIN"
        }
    }
    
    static var ONBOARDING_CREATE_PIN_SUBTITLE: String {
        switch lang {
        case .lv:
            return "PIN būs jāievada katru reizi atverot digitālo maku, tāpēc svarīgi to iegaumēt"
        case .en:
            return "You will use this PIN every time you need to unlock your wallet, so make sure you memorize it"
        }
    }
    
    static var ONBOARDING_CONFIRM_PIN_SUBTITLE: String {
        switch lang {
        case .lv:
            return "Vēlamies pārliecināties, ka esat to iegaumējis"
        case .en:
            return "We want to make sure you’ve memorized it"
        }
    }

    static var ENTER_PIN: String {
        switch lang {
        case .lv:
            return "Ievadiet PIN"
        case .en:
            return "Enter your PIN"
        }
    }
    
    static var WRONG_CONFIRMATION_CODE: String {
        switch lang {
        case .lv:
            return "Drošības kods nav pareizs"
        case .en:
            return "Safety code is incorrect"
        }
    }
    
    static var FAILED_PIN_BEFORE_SUSPENSION: String {
        switch lang {
        case .lv:
            return "Atlikuši %d mēģinājumi līdz maka apturēšanai"
        case .en:
            return "%d attempts remaining before wallet suspension"
        }
    }
    
    static var FAILED_PIN_BEFORE_DELETION: String {
        switch lang {
        case .lv:
            return "Līdz maka dzēšanai atlikuši %d mēģinājumi"
        case .en:
            return "%d attempts remaining before wallet deletion"
        }
    }
    
    static var FAILED_PIN_SUSPENDED_MULTIPLE: String {
        switch lang {
        case .lv:
            return "Pārāk daudz neveiksmīgu mēģinājumu. Mēģiniet vēlreiz pēc %d minūtēm"
        case .en:
            return "Too many failed attempts. Try again in %d minutes"
        }
    }
    
    static var FAILED_PIN_SUSPENDED_SINGLE: String {
        switch lang {
        case .lv:
            return "Pārāk daudz neveiksmīgu mēģinājumu. Mēģiniet vēlreiz pēc %d minūtes"
        case .en:
            return "Too many failed attempts. Try again in %d minute"
        }
    }
    
    static var PINS_DONT_MATCH: String {
        switch lang {
        case .lv:
            return "PINi nesakrīt"
        case .en:
            return "PINs do not match"
        }
    }
    
    static var ROOTED_DEVICE_TITLE: String {
        switch lang {
        case .lv:
            return "Drošības pārbaude neizdevās"
        case .en:
            return "Security check failed"
        }
    }
    
    static var ROOTED_DEVICE_SUBTITLE: String {
        switch lang {
        case .lv:
            return "Jūsu ierīce neatbilst lietošanas drošības prasībām"
        case .en:
            return "Your device does not meet the safety requirements for use"
        }
    }
    
    static var NO_PASSCODE_DEVICE_SUBTITLE: String {
        switch lang {
        case .lv:
            return "Jūsu ierīcei nav uzstādīts ekrāna bloķēšanas kods. Lūdzu, iestatiet to ierīces iestatījumos"
        case .en:
            return "Your device does not have a screen lock passcode set. Please enable it in your device settings"
        }
    }
    
    
    static var ROOTED_DEVICE_HELP: String {
        switch lang {
        case .lv:
            return "Lai saņemtu palīdzību, sazinieties ar atbalsta dienestu digimaks@dativa.lv"
        case .en:
            return "For assistance, contact support digimaks@dativa.lv"
        }
    }
    
    static var LOGIN_TITLE: String {
        switch lang {
        case .lv:
            return "Autentificēties"
        case .en:
            return "Log in"
        }
    }
    
    static var SIGNATURE_TEXT_SID: String {
        switch lang {
        case .lv:
            return "ID numurs"
        case .en:
            return "ID number"
        }
    }
    
    static var SIGNATURE_TEXT_CN: String {
        switch lang {
        case .lv:
            return "Vārds"
        case .en:
            return "Name"
        }
    }
    
    static var SIGNATURE_TEXT_EXPIRES: String {
        switch lang {
        case .lv:
            return "Derīguma termiņš"
        case .en:
            return "Expires on"
        }
    }
    
    static var SIGNATURE_TEXT_ISSUED: String {
        switch lang {
        case .lv:
            return "Izsniegšanas datums"
        case .en:
            return "Issued on"
        }
    }
    
    static var SIGNATURE_TEXT_TYPE: String {
        switch lang {
        case .lv:
            return "Tips"
        case .en:
            return "Type"
        }
    }
    
    static var SIGNATURE_TEXT_CN_SEAL: String {
        switch lang {
        case .lv:
            return "Nosaukums"
        case .en:
            return "Name"
        }
    }
    
    static var CAMERA_PERMISSION_TITLE: String {
        switch lang {
        case .lv:
            return "Nepieciešama piekļuve kamerai"
        case .en:
            return "Camera Access Needed"
        }
    }
    
    static var CAMERA_PERMISSION_SUBTITLE: String {
        switch lang {
        case .lv:
            return "Lai skenētu kvadrātkodu, lūdzu, atļaujiet piekļuvi kamerai iestatījumos."
        case .en:
            return "Please allow camera access in Settings to scan QR code."
        }
    }
    
    static var CAMERA_PERMISSION_OPEN_SETTINGS: String {
        switch lang {
        case .lv:
            return "Atvērt iestatījumus"
        case .en:
            return "Open Settings"
        }
    }
    
    static var CAMERA_PERMISSION_CANCEL: String {
        switch lang {
        case .lv:
            return "Atcelt"
        case .en:
            return "Cancel"
        }
    }
    
    static var DEPRICATED_VERSION_TITLE: String {
        switch lang {
        case .lv:
            return "Nepieciešama atjaunināšana"
        case .en:
            return "Update required"
        }
    }
    
    static var DEPRICATED_VERSION_SUBTITLE: String {
        switch lang {
        case .lv:
            return "Lai turpinātu, nepieciešama jaunāka lietotnes versija. Lūdzu, atjauniniet, lai turpinātu lietot Digimaks."
        case .en:
            return "A newer version of the app is required to continue. Please update to keep using Digimaks."
        }
    }
    
    static var DEPRICATED_VERSION_BUTTON_TITLE: String{
        switch lang {
        case .lv:
            return "Atjaunināt lietotni"
        case .en:
            return "Update app"
        }
    }
}

public enum Language: String, Sendable, CaseIterable {
    case lv, en
}
