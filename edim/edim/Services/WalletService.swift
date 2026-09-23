// SPDX-License-Identifier: EUPL-1.2

//
//  WalletService.swift
//  edim
//
//  Created by Matīss Mamedovs on 04/02/2025.
//

import Moya
import Foundation
import AuthWrapperPackage

final public class WalletService: Sendable {
    
    public static let shared = WalletService()
    
    @MainActor public func getOfferUri(type: String, completionCallback: @escaping(WalletOfferUri) -> (), eparakstsErrorCallback: @escaping() -> (), errorCallback: @escaping() -> ()) {
        self.checkToken(completionCallback: { success in
            if success {
                AppApiProvider.shared.provider.request(.getOfferUri(type: type), completion: {  [weak self] result in
                    guard let self = self else { return }
                    
                    switch result {
                    case .success(let response):
                        self.parsePidOffer(response: response, completionCallback: completionCallback, errorCallback: errorCallback)
                    case .failure:
                        errorCallback()
                    }
                })
            } else {
                PasscodeManager.shared.deleteSessionToken()
                eparakstsErrorCallback()
            }
        })
        
    }
    
    private func parsePidOffer(response: Response, completionCallback: @escaping(WalletOfferUri) -> (), errorCallback: @escaping() -> ()) {
        if let data = try? JSONDecoder().decode(WalletOfferUri.self, from: response.data) {
            completionCallback(data)
        } else {
            errorCallback()
        }
    }
    
    @MainActor func checkToken(completionCallback: @escaping(Bool) -> ()) {
        AppApiProvider.shared.provider.request(.checkSessionToken, completion: {  [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                self.parseCheckTOken(response: response, completionCallback: completionCallback)
            case .failure:
                completionCallback(false)
            }
        })
    }
    
    private func parseCheckTOken(response: Response, completionCallback: @escaping(Bool) -> ()) {
        if let data = try? JSONDecoder().decode(CheckTokenResponse.self, from: response.data) {
            completionCallback(data.active)
        } else {
            completionCallback(false)
        }
    }
    
    @MainActor func getRedirectUrlForLVRTC(crossdevice: Bool, completionCallback: @escaping(String) -> ()) {
        AppApiProvider.shared.provider.request(.redirectForLVRTC(crossdevice: crossdevice), completion: {  [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                self.parseRedirectUri(response: response, completionCallback: completionCallback)
            case .failure:
                completionCallback("")
            }
        })
    }
    
    private func parseRedirectUri(response: Response, completionCallback: @escaping(String) -> ()) {
        if let data = try? JSONDecoder().decode(RedirectURL.self, from: response.data) {
            completionCallback(data.redirectUrl)
        } else {
            completionCallback("")
        }
    }
    
    @MainActor func getLVRTCIdentities(token: String, completionCallback: @escaping(ElectronicSignature?) -> ()) {
        AppApiProvider.shared.provider.request(.getLVRTCIdentities(token: token), completion: {  [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                self.parseLVRTCIdentities(response: response, completionCallback: completionCallback)
            case .failure:
                completionCallback(nil)
            }
        })
    }
    
    private func parseLVRTCIdentities(response: Response, completionCallback: @escaping(ElectronicSignature?) -> ()) {
        if let data = try? JSONDecoder().decode(ElectronicSignature.self, from: response.data) {
            completionCallback(data)
        } else {
            completionCallback(nil)
        }
    }
    
    @MainActor func sendFileForValidation(data: Data, name: String, extens: String, completionCallback: @escaping(FileValidationResponses?) -> (), eparakstsErrorCallback: @escaping() -> ()) {
        AppApiProvider.shared.provider.request(.validateFile(data: data, name: name, extens: extens), completion: {  [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                self.praseFileValidation(response: response, completionCallback: completionCallback)
            case .failure:
                completionCallback(nil)
            }
        })
    }
    
    private func praseFileValidation(response: Response, completionCallback: @escaping(FileValidationResponses?) -> ()) {
        do {
            let data = try JSONDecoder().decode(FileValidationResponses.self, from: response.data)
            completionCallback(data)
        } catch {
            completionCallback(nil)
            AppLog.error(error)
        }
    }
    
    @MainActor func signDocument(data: Data, isESign: Bool, requestId: String, asice: Bool, fileName: String, redirectUrl: String, redirectError: String, esealSid: String?, crossdevice: Bool, completionCallback: @escaping(SignResponse?) -> ()) {
        if isESign {
            AppApiProvider.shared.provider.request(.signWithSignature(filename: fileName, data: data, body: constructSignBody(requestId: requestId, asice: asice, fileName: fileName, redirectUrl: redirectUrl, redirectError: redirectError, esealSid: esealSid, crossdevice: crossdevice)), completion: {  [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success(let response):
                    self.parseSign(response: response, completionCallback: completionCallback)
                case .failure:
                    completionCallback(nil)
                }
            })
        } else {
            AppApiProvider.shared.provider.request(.signWithSeal(filename: fileName, data: data, body: constructSignBody(requestId: requestId, asice: asice, fileName: fileName, redirectUrl: redirectUrl, redirectError: redirectError, esealSid: esealSid, crossdevice: crossdevice)), completion: {  [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success(let response):
                    self.parseSign(response: response, completionCallback: completionCallback)
                case .failure:
                    completionCallback(nil)
                }
            })
        }
    }
    
    private func parseSign(response: Response, completionCallback: @escaping(SignResponse?) -> ()) {
        if let data = try? JSONDecoder().decode(SignResponse.self, from: response.data) {
            completionCallback(data)
        } else {
            completionCallback(nil)
        }
    }
    
    @MainActor func downloadSignedfile(requestId: String, filename: String, completionCallback: @escaping() -> ()) {
        AppApiProvider.shared.provider.request(.downloadSignedFile(requestId: requestId, filename: filename), completion: {  [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                completionCallback()
            case .failure:
                completionCallback()
            }
        })
    }
    
    private func parseDownloadedFile(response: Response, completionCallback: @escaping(FileValidationResponses?) -> ()) {
        if let data = try? JSONDecoder().decode(FileValidationResponses.self, from: response.data) {
            completionCallback(data)
        } else {
            completionCallback(nil)
        }
    }
    
    @MainActor func deleteSession(isESign: Bool, requestId: String, completionCallback: @escaping(Bool) -> ()) {
        if isESign {
            AppApiProvider.shared.provider.request(.closeSignSession(requestId: requestId), completion: {  [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success(let response):
                    completionCallback(response.statusCode == 200 || response.statusCode == 204)
                case .failure:
                    completionCallback(false)
                }
            })
        } else {
            AppApiProvider.shared.provider.request(.closeSealSession(requestId: requestId), completion: {  [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success(let response):
                    completionCallback(response.statusCode == 200 || response.statusCode == 204)
                case .failure:
                    completionCallback(false)
                }
            })
        }
    }
}


extension WalletService {
    private func constructSignBody(requestId: String, asice: Bool, fileName: String, redirectUrl: String, redirectError: String, esealSid: String?, crossdevice: Bool) -> [String: Sendable] {
        var responseDictionary: [String: Sendable] = [:]
        
        responseDictionary["requestId"] = requestId
        responseDictionary["asice"] = asice
        responseDictionary["fileName"] = fileName
        responseDictionary["redirectUrl"] = redirectUrl
        responseDictionary["redirectError"] = redirectError
        responseDictionary["crossdevice"] = crossdevice
        if let esealSid = esealSid {
            responseDictionary["esealSid"] = esealSid
        }

        return responseDictionary
    }
}
