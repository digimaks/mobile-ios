// SPDX-License-Identifier: EUPL-1.2

//
//  WUAService.swift
//  edim
//
//  Created by Matīss Mamedovs on 27/10/2025.
//

import Moya
import Foundation
import EudiWalletKit
import CryptoKit
import OpenID4VCI
import CryptoSwift
import SwiftASN1
import Crypto
import JOSESwift
import UIKit

final public class WUAService: Sendable {
    
    public static let shared = WUAService()

    @MainActor public func getNonce(completionCallback: @escaping(Nonce) -> (), errorCallback: @escaping() -> ()) {
        AppApiProvider.shared.provider.request(.getNonce, completion: {  [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                self.parseNonce(response: response, completionCallback: completionCallback, errorCallback: errorCallback)
            case .failure:
                errorCallback()
            }
        })
    }
    
    private func parseNonce(response: Response, completionCallback: @escaping(Nonce) -> (), errorCallback: @escaping() -> ()) {
        if let data = try? JSONDecoder().decode(Nonce.self, from: response.data) {
            completionCallback(data)
        } else {
            errorCallback()
        }
    }
    
    @MainActor public func createInstance(data: String, keyId: String, nonce: String, completionCallback: @escaping(Bool) -> (), errorCallback: @escaping() -> ()) {
        AppApiProvider.shared.provider.request(.createInstance(body: constructInstanceBody(data: data, keyId: keyId, nonce: nonce)), completion: { result in
            switch result {
            case .success(let response):
                completionCallback(response.statusCode == 200 || response.statusCode == 201)
            case .failure:
                errorCallback()
            }
        })
    }
    
    private func parseInstance(response: Response, completionCallback: @escaping(Nonce) -> (), errorCallback: @escaping() -> ()) {
        if let data = try? JSONDecoder().decode(Nonce.self, from: response.data) {
            completionCallback(data)
        } else {
            errorCallback()
        }
    }
    
    func jsonBase64UrlEncode(_ dictionary: [String: Any]) throws -> String {
        let jsonData = try JSONSerialization.data(withJSONObject: dictionary, options: [])
        return jsonData.base64URLEncodedString()
    }
    
    // Convert raw ECDSA signature (r||s) to DER format
    func convertRawSignatureToDER(r: Data, s: Data) -> Data? {
        AppLog.debug("🔍 Converting raw signature to DER, r: \(r.count) bytes, s: \(s.count) bytes")
        
        // Helper to encode an integer in DER format
        func encodeDERInteger(_ value: Data) -> Data {
            var data = value
            
            // Remove leading zeros, but keep at least one byte
            while data.count > 1 && data.first == 0x00 {
                data = data.dropFirst()
            }
            
            // If the high bit is set, prepend 0x00 (DER integers are signed)
            if let firstByte = data.first, firstByte & 0x80 != 0 {
                data = Data([0x00]) + data
            }
            
            // INTEGER tag (0x02) + length + data
            var result = Data([0x02, UInt8(data.count)])
            result.append(data)
            return result
        }
        
        let rDER = encodeDERInteger(r)
        let sDER = encodeDERInteger(s)
        
        AppLog.debug("📏 r DER length: \(rDER.count), s DER length: \(sDER.count)")
        
        // Combine into SEQUENCE
        let contentLength = rDER.count + sDER.count
        var result = Data([0x30, UInt8(contentLength)]) // SEQUENCE tag + length
        result.append(rDER)
        result.append(sDER)
        
        AppLog.debug("✅ Final DER signature: \(result.count) bytes")
        AppLog.debug("🔐 DER hex: \(result.map { String(format: "%02x", $0) }.joined())")
        
        return result
    }
   
}




extension WUAService {
    private func constructInstanceBody(data: String, keyId: String, nonce: String) -> [String: Sendable] {
        var responseDictionary: [String: Sendable] = [:]
        
        responseDictionary["challenge"] = nonce
        responseDictionary["key_attestation"] = data
        responseDictionary["hardware_key_tag"] = keyId
        responseDictionary["deviceLabel"] = UIDevice.current.name
        responseDictionary["deviceIdentifiers"] = [[
            "manufacturer": "Apple",
            "model": modelIdentifier()
        ]]
        

        return responseDictionary
    }
    
    private func constructWuaBody(assertation: String) -> [String: String] {
        var responseDictionary: [String: String] = [:]
        
        responseDictionary["grant_type"] = "urn:ietf:params:oauth:grant-type:jwt-bearer"
        responseDictionary["assertion"] = assertation

        return responseDictionary
    }
    
    
    
    
    func modelIdentifier() -> String {
        if let simulatorModelIdentifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] { return simulatorModelIdentifier }
        var sysinfo = utsname()
        uname(&sysinfo) // ignore return value
        return String(bytes: Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)!.trimmingCharacters(in: .controlCharacters)
    }
}
