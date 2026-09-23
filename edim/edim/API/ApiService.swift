// SPDX-License-Identifier: EUPL-1.2

//
//  ApiService.swift
//  edim
//
//  Created by Matīss Mamedovs on 21/11/2024.
//

import Foundation
import NetworkWrapperPackage
import Moya
import SwiftyJSON
import UtilitiesPackage

public enum ApiService: Sendable {
    case getPersonData
    case personEmail(body: [String: Sendable])
    case personEmailVerify(body: [String: Sendable])
    case personPhone(body: [String: Sendable])
    case personPhoneVerify(body: [String: Sendable])
    case getOfferUri(type: String)
    case checkSessionToken
    case redirectForLVRTC(crossdevice: Bool)
    case getLVRTCIdentities(token: String)
    case validateFile(data: Data, name: String, extens: String)
    case signWithSignature(filename: String, data: Data, body: [String: Sendable])
    case signWithSeal(filename: String, data: Data, body: [String: Sendable])
    case downloadSignedFile(requestId: String, filename: String)
    case closeSignSession(requestId: String)
    case closeSealSession(requestId: String)
    case pingPaymentStatus(requestUrl: String)
    case getToken(body: [String: String])
    case getNonce
    case createInstance(body: [String: Sendable])
    case getWua(body: [String: String], assertation: String)
    case getWalletUnitAttest(body: [String: Sendable])
    case getWalletInstanceAttest(body: [String: Sendable])
    case getVersionConfig
    
    var localLocation: URL {
        switch self {
        case .downloadSignedFile(_, let filename):
            return self.getFileURL(filename: filename)
        default:
            return URL(fileURLWithPath: "")
        }
    }
    
    var downLoadDestination: DownloadDestination {
        return { _, _ in return (self.localLocation, [.removePreviousFile, .createIntermediateDirectories]) }
    }
    
    func getFileURL(filename: String) -> URL {
        let documentsURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(filename)
        
        return fileURL
    }
    
}
@MainActor
extension ApiService: @preconcurrency TargetType {
    public var baseURL: URL {
        switch self {
        case .getPersonData, .personEmail, .personEmailVerify, .personPhone, .personPhoneVerify:
            guard let url = URL(string: AppApiProvider.shared.getPersonBackendBase()) else {
                return URL(fileURLWithPath: "")
            }
            
            return url
        case .getOfferUri:
            guard let url = URL(string: AppApiProvider.shared.getWalletBackendBase()) else {
                return URL(fileURLWithPath: "")
            }
            
            return url
        case .checkSessionToken:
            guard let url = URL(string: AppApiProvider.shared.getSessionBackendBase()) else {
                return URL(fileURLWithPath: "")
            }
            return url
        case .redirectForLVRTC, .getLVRTCIdentities, .validateFile, .signWithSignature, .signWithSeal, .downloadSignedFile, .closeSignSession, .closeSealSession:
            guard let url = URL(string: AppApiProvider.shared.getEparakstsWalletBackendBase()) else {
                return URL(fileURLWithPath: "")
            }
            
            return url
        case .pingPaymentStatus(let requestUrl):
            guard let url = URL(string: requestUrl) else {
                return URL(fileURLWithPath: "")
            }
            
            return url
        case .getToken:
            guard let url = URL(string: AppApiProvider.shared.getWalletBackendBase()) else {
                return URL(fileURLWithPath: "")
            }
            
            return url
        case .getNonce, .createInstance, .getWua:
            guard let url = URL(string: AppApiProvider.shared.getEparakstsWalletBackendBase()) else {
                return URL(fileURLWithPath: "")
            }
            
            return url
            
        case .getWalletUnitAttest, .getWalletInstanceAttest, .getVersionConfig:
            guard let url = URL(string: AppApiProvider.shared.getEparakstsWalletBackendBase()) else {
                return URL(fileURLWithPath: "")
            }
            
            return url
            
        }
        
    }
    
    public var path: String {
        switch self {
        case .getPersonData:
            return ""
        case .personEmail:
            return "/email"
        case .personEmailVerify:
            return "/email/verify"
        case .personPhone:
            return "/phone"
        case .personPhoneVerify:
            return "/phone/verify"
        case .getOfferUri(let type):
            return "/\(type)"
        case .checkSessionToken:
            return "/session"
        case .redirectForLVRTC(let _):
            return "/eparaksts/identities"
        case .getLVRTCIdentities(let token):
            return "/eparaksts/identities/\(token)"
        case .validateFile:
            return "/eparaksts/validate"
        case .signWithSignature:
            return "/eparaksts/sign"
        case .signWithSeal:
            return "/eparaksts/eseal"
        case .downloadSignedFile(let requestId, _):
            return "/eparaksts/download/\(requestId)"
        case .closeSignSession(let requestId):
            return "/eparaksts/sign/\(requestId)"
        case .closeSealSession(let requestId):
            return "/eparaksts/seal/\(requestId)"
        case .pingPaymentStatus:
            return ""
        case .getToken:
            return "/token"
        case .getNonce:
            return "/nonce"
        case .createInstance:
            return "/instance"
        case .getWua:
            return "/token"
        case .getWalletUnitAttest:
            return "/wallet-unit-attestation/jwk-set"
        case .getWalletInstanceAttest:
            return "/wallet-instance-attestation/jwk"
        case .getVersionConfig:
            return "/.well-known/appspecific/version.json"
        }
    }
    
    public var method: Moya.Method {
        switch self {
        case .checkSessionToken, .redirectForLVRTC, .getLVRTCIdentities, .downloadSignedFile, .pingPaymentStatus, .getVersionConfig:
            return .get
        case .closeSignSession, .closeSealSession:
            return .delete
        case .getNonce:
            return .post
        default:
            return .post
        }
    }
    
    public var task: Moya.Task {
        switch self {
        case .getPersonData:
            return .requestPlain
        case .personEmail(let body):
            return .requestParameters(parameters: body, encoding: JSONEncoding.default)
        case .personEmailVerify(let body):
            return .requestParameters(parameters: body, encoding: JSONEncoding.default)
        case .personPhone(let body):
            return .requestParameters(parameters: body, encoding: JSONEncoding.default)
        case .personPhoneVerify(let body):
            return .requestParameters(parameters: body, encoding: JSONEncoding.default)
        case .getOfferUri:
            return .requestPlain
        case .checkSessionToken:
            return .requestPlain
        case .redirectForLVRTC(let crossdevice):
            return .requestParameters(parameters: ["redirecturl": "digimaks://auth-done",
                                                   "crossdevice": crossdevice ? "true" : "false"],
                                      encoding: URLEncoding.queryString)
        case .getLVRTCIdentities:
            return .requestPlain
        case .validateFile(let data, let name, let extens):
            let fullFileName: String = name + "." + extens
            let fileData = MultipartFormData(provider: .data(data), name: fullFileName, fileName: fullFileName)
            let urlParameters = ["files":[["FileName": fullFileName]]]
            
            if let json = try? JSONSerialization.data(withJSONObject: urlParameters, options: []) {
                let jsonForm = MultipartFormData(provider: .data(json), name: "json")
                
                let multipartData = [fileData, jsonForm]
                return .uploadMultipart(multipartData)
            } else {
                return .uploadMultipart([fileData])
            }
        case .signWithSignature(let fileName, let data, let body):
            let dat = MultipartFormData(provider: .data(data), name: fileName, fileName: fileName)
            
            if let json = try? JSONSerialization.data(withJSONObject: body, options: []) {
                let jsonForm = MultipartFormData(provider: .data(json), name: "json")
                
                let multipartData = [dat, jsonForm]
                return .uploadMultipart(multipartData)
            } else {
                return .uploadMultipart([dat])
            }
        case .signWithSeal(let fileName, let data, let body):
            let dat = MultipartFormData(provider: .data(data), name: fileName, fileName: fileName)
            
            if let json = try? JSONSerialization.data(withJSONObject: body, options: []) {
                let jsonForm = MultipartFormData(provider: .data(json), name: "json")
                
                let multipartData = [dat, jsonForm]
                return .uploadMultipart(multipartData)
            } else {
                return .uploadMultipart([dat])
            }
        case .downloadSignedFile:
            return .downloadDestination(DefaultDownloadDestination)
        case .closeSignSession:
            return .requestPlain
        case .closeSealSession:
            return .requestPlain
        case .pingPaymentStatus:
            return .requestPlain
        case .getToken(let body):
            return .requestParameters(parameters: body, encoding: URLEncoding.httpBody)
        case .getNonce:
            return .requestPlain
        case .createInstance(let body):
            return .requestParameters(parameters: body, encoding: JSONEncoding.default)
        case .getWua(let body, _):
            return .requestParameters(parameters: body, encoding: URLEncoding.default)
        case .getWalletUnitAttest(let body), .getWalletInstanceAttest(let body):
            return .requestCompositeParameters(
                bodyParameters: body,
                bodyEncoding: JSONEncoding.default,
                urlParameters: ["platform": "ios"]
            )
        case .getVersionConfig:
            return .requestPlain
        }
    }
    
    public var headers: [String : String]? {
        let instance = UserDefaultsManager.shared.get(key: AppDelegate.INSTANCE_ID) ?? ""
        switch self {
        case .getToken:
            return ["content-type": "application/x-www-form-urlencoded",
                    "X-App-Instance-Id": instance]
        case .getWua(_, let assertation):
            let token = SessionData.shared.getAuthToken() ?? ""
            return ["Authorization": "Bearer \(token)",
                    "content-type": "application/x-www-form-urlencoded",
                    "X-Apple-Attest-Assertion": assertation,
                    "X-App-Instance-Id": instance]
        default:
            let token = SessionData.shared.getAuthToken() ?? ""
            if !token.isEmpty {
                return ["Authorization": "Bearer \(token)",
                        "content-type": "application/json",
                        "X-App-Instance-Id": instance]
            } else {
                return ["content-type": "application/json",
                        "X-App-Instance-Id": instance]
            }
        }
    }
}

class FileSystem {
    static let documentsDirectory: URL = {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.endIndex - 1]
    }()
    
    static let cacheDirectory: URL = {
        let urls = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        return urls[urls.endIndex - 1]
    }()
    
    static let downloadDirectory: URL = {
        let directory: URL = FileSystem.documentsDirectory.appendingPathComponent("/Download/")
        return directory
    }()
    
}


let DOWNLOAD_DESTINATION = "DOWNLOAD_DESTINATION"
private let DefaultDownloadDestination: DownloadDestination = { temporaryURL, response in
    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let fileURL = documentsURL.appendingPathComponent(response.suggestedFilename!)
    UserDefaultsManager.shared.set(value: fileURL.absoluteString, key: DOWNLOAD_DESTINATION)
    return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
    
}
