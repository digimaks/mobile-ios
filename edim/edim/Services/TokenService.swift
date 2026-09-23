// SPDX-License-Identifier: EUPL-1.2

//
//  TokenService.swift
//  edim
//
//  Created by Matīss Mamedovs on 10/07/2025.
//

import Foundation
import Moya

final public class TokenService: Sendable {
    public static let shared = TokenService()
    
    @MainActor public func getToken(grantType: String, code: String, redirectUri: String, codeVerifier: String, completionCallback: @escaping(Token) -> (), errorCallback: @escaping() -> ()) {
        AppApiProvider.shared.provider.request(.getToken(body: constructTokenBody(grantType: grantType, code: code, redirectUri: redirectUri, codeVerifier: codeVerifier)), completion: {  [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                self.parseTokenData(response: response, completionCallback: completionCallback, errorCallback: errorCallback)
            case .failure:
                errorCallback()
            }
        })
    }
    
    private func parseTokenData(response: Response, completionCallback: @escaping(Token) -> (), errorCallback: @escaping() -> ()) {
        if let data = try? JSONDecoder().decode(Token.self, from: response.data) {
            completionCallback(data)
        } else {
            errorCallback()
        }
    }
}

extension TokenService {
    private func constructTokenBody(grantType: String, code: String, redirectUri: String, codeVerifier: String) -> [String: String] {
        var responseDictionary: [String: String] = [:]
        
        responseDictionary["grant_type"] = grantType
        responseDictionary["code"] = code
        responseDictionary["redirect_uri"] = redirectUri
        responseDictionary["code_verifier"] = codeVerifier

        return responseDictionary
    }
}
