// SPDX-License-Identifier: EUPL-1.2

//
//  PersonService.swift
//  edim
//
//  Created by Matīss Mamedovs on 16/01/2025.
//

import Moya
import Foundation

final public class PersonService: Sendable {
    public static let shared = PersonService()
    
    @MainActor public func getPersonData(completionCallback: @escaping(Person?) -> (), errorCallback: @escaping() -> ()) {
        AppApiProvider.shared.provider.request(.getPersonData, completion: {  [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                self.parsePersonData(response: response, completionCallback: completionCallback, errorCallback: errorCallback)
            case .failure:
                errorCallback()
            }
        })
    }
    
    private func parsePersonData(response: Response, completionCallback: @escaping(Person?) -> (), errorCallback: @escaping() -> ()) {
        if response.statusCode == 404 {
            // new user
            completionCallback(nil)
        } else {
            if let data = try? JSONDecoder().decode(Person.self, from: response.data) {
                completionCallback(data)
            } else {
                errorCallback()
            }
        }
        
    }
    
    @MainActor public func onboardEmail(email: String, completionCallback: @escaping() -> (), errorCallback: @escaping() -> ()) {
        AppApiProvider.shared.provider.request(.personEmail(body: constructOnboardEmail(email: email)), completion: {  [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                if response.statusCode == 204 {
                    completionCallback()
                } else {
                    errorCallback()
                }
            case .failure:
                errorCallback()
            }
        })
    }
    
    @MainActor public func verifyEmail(code: String, completionCallback: @escaping() -> (), errorCallback: @escaping(String) -> ()) {
        AppApiProvider.shared.provider.request(.personEmailVerify(body: constructVerify(code: code)), completion: {  [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                self.parseVerifyResponse(response: response, completionCallback: completionCallback, errorCallback: errorCallback)
            case .failure:
                errorCallback("null")
            }
        })
    }
    
    @MainActor public func onboardPhone(phone: String, completionCallback: @escaping() -> (), errorCallback: @escaping() -> ()) {
        AppApiProvider.shared.provider.request(.personPhone(body: constructOnboardPhone(phone: phone)), completion: {  [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                if response.statusCode == 204 {
                    completionCallback()
                } else {
                    errorCallback()
                }
            case .failure:
                errorCallback()
            }
        })
    }
    
    @MainActor public func verifyPhone(code: String, completionCallback: @escaping() -> (), errorCallback: @escaping(String) -> ()) {
        AppApiProvider.shared.provider.request(.personPhoneVerify(body: constructVerify(code: code)), completion: {  [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                self.parseVerifyResponse(response: response, completionCallback: completionCallback, errorCallback: errorCallback)
            case .failure:
                errorCallback("null")
            }
        })
    }
    
    fileprivate func parseVerifyResponse(response: Response, completionCallback: @escaping() -> (), errorCallback: @escaping(String) -> ()) {
        if response.statusCode == 204 {
            completionCallback()
        } else {
            if let data = String(data: response.data, encoding: .utf8) {
                if data.contains("toomanyattempts") {
                    errorCallback("toomanyattempts")
                } else if data.contains("invalid") {
                    errorCallback("invalid")
                } else {
                    errorCallback("null")
                }
            } else {
                errorCallback("null")
            }
        }
    }
}

extension PersonService {
    private func constructOnboardEmail(email: String) -> [String: Sendable] {
        return ["email": email]
    }
    
    private func constructOnboardPhone(phone: String) -> [String: Sendable] {
        return ["phoneNumber": phone]
    }
    
    private func constructVerify(code: String) -> [String: Sendable] {
        return ["verificationCode": code]
    }
}

