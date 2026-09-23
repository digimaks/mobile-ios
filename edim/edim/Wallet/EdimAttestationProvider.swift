// SPDX-License-Identifier: EUPL-1.2

//
//  EdimAttestationProvider.swift
//  edim
//
//  Created by Matīss Mamedovs on 13/04/2026.
//

import Foundation
import EudiWalletKit
import JOSESwift
import Moya
import OpenID4VCI


public struct ClientIDHelper {
    public func getApiClientID() -> String {
        AppConfiguration.apiClientID
    }
}

struct MyAttestationProvider: WalletAttestationsProvider {
    func getWalletAttestation(signingKey: SigningKeyProxy) async throws -> String {
        
        let jwkDict = try signingKey.getPublicJWK().toDictionary()
        let clientId: String = ClientIDHelper().getApiClientID()
        
        guard let jwkSendable = jwkDict as? [String: Sendable] else {
            let data = try JSONSerialization.data(withJSONObject: jwkDict, options: [])
            let object = try JSONSerialization.jsonObject(with: data, options: [])
            guard let cast = object as? [String: Sendable] else {
                throw NSError(domain: "AttestationPayloadError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert JWK dictionary to Sendable"])
            }
            
            let clientId: String = ClientIDHelper().getApiClientID()
            let payload: [String: Sendable] = ["jwk": cast, "clientId": clientId]
            let response = try await AttestationRepository.shared.issueWalletInstanceAttestation(payload: payload)
            return response.walletInstanceAttestation
        }

        let payload: [String: Sendable] = ["jwk": jwkSendable, "clientId": clientId]

        let response = try await AttestationRepository.shared.issueWalletInstanceAttestation(payload: payload)
        return response.walletInstanceAttestation
    }
    
    public func getKeysAttestation(keys: [any JOSESwift.JWK], nonce: String?) async throws -> String {
        let jwkDictArray = try keys.map { try $0.toDictionary() }
        let sendableKeys: [[String: Sendable]] = try jwkDictArray.map { dict in
            if let cast = dict as? [String: Sendable] {
                return cast
            }
            let data = try JSONSerialization.data(withJSONObject: dict, options: [])
            let object = try JSONSerialization.jsonObject(with: data, options: [])
            guard let cast = object as? [String: Sendable] else {
                throw NSError(domain: "AttestationPayloadError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to convert JWK set entry to Sendable"])
            }
            return cast
        }

        var payload: [String: Sendable] = [
            "jwkSet": [
                "keys": sendableKeys
            ] as [String: Sendable]
        ]

        if let nonce {
            payload["nonce"] = nonce
            
        }
        
        AppSecurityLayer.shared.getKeyID(completion: { keyID in
            if let keyID = keyID {
                payload["hardwareKeyTag"] = keyID
            }
        })

        let response = try await AttestationRepository.shared.issueWalletUnitAttestation(payload: payload)
        return response.walletUnitAttestation
    }
}

@MainActor final class AttestationRepository {
    
    @MainActor static let shared = AttestationRepository()
    
    func issueWalletUnitAttestation(payload: [String: Sendable]) async throws -> WalletUnitAttestation {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<WalletUnitAttestation, Error>) in
            AppApiProvider.shared.provider.request(.getWalletUnitAttest(body: payload)) { result in
                switch result {
                case .success(let response):
                    do {
                        let decoded = try JSONDecoder().decode(WalletUnitAttestation.self, from: response.data)
                        cont.resume(returning: decoded)
                    } catch {
                        cont.resume(throwing: error)
                    }
                case .failure(let error):
                    cont.resume(throwing: error)
                }
            }
        }
    }

    func issueWalletInstanceAttestation(payload: [String: Sendable]) async throws -> WalletInstanceAttestation {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<WalletInstanceAttestation, Error>) in
            AppApiProvider.shared.provider.request(.getWalletInstanceAttest(body: payload)) { result in
                switch result {
                case .success(let response):
                    do {
                        let decoded = try JSONDecoder().decode(WalletInstanceAttestation.self, from: response.data)
                        cont.resume(returning: decoded)
                    } catch {
                        cont.resume(throwing: error)
                    }
                case .failure(let error):
                    cont.resume(throwing: error)
                }
            }
        }
    }
}

public struct WalletUnitAttestation: Sendable, Decodable {

    public let walletUnitAttestation: String

    public init(walletUnitAttestation: String) {
        self.walletUnitAttestation = walletUnitAttestation
    }
}

public struct WalletInstanceAttestation: Sendable, Decodable {

    public let walletInstanceAttestation: String

    public init(walletInstanceAttestation: String) {
        self.walletInstanceAttestation = walletInstanceAttestation
    }
}
