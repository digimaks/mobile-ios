// SPDX-License-Identifier: EUPL-1.2

//
//  AppSecurityLayer.swift
//  edim
//
//  Created by Matīss Mamedovs on 03/12/2024.
//

import Foundation
@preconcurrency import DeviceCheck
import CommonCrypto
import Crypto
import CryptoKit
import KeychainWrapperPackage
import SwiftCBOR

final public class AppSecurityLayer: Sendable {
    fileprivate let ENCLAVE_KEY_ID: String = "ENCLAVE_KEY_ID"
    
    public static let shared = AppSecurityLayer()
    
    let service = DCAppAttestService.shared
    
    public func isSupported() -> Bool {
        return service.isSupported
    }
    
    public func initWalletAttestation(nonce: String, completionHandler: @escaping (String?, String?, String) -> Void, errorHandler: @escaping (Error?) -> Void) {
        service.generateKey(completionHandler: { keyID, error in
            // save key in keychain
            guard let keyID = keyID else {
                AppLog.error("Error generating key: \(error?.localizedDescription ?? "")")
                errorHandler(error)
                return
            }
            
            self.insertKey(keyID: keyID, completion: { success in
                if success {
                    if let nonceData = nonce.data(using: .utf8) {
                        let clientDataHash = Data(SHA256.hash(data: nonceData))
                        self.service.attestKey(keyID, clientDataHash: clientDataHash, completionHandler: { data, error in
                            if let data = data?.base64URLEncodedString() {
                                completionHandler(data, keyID, nonce)
                            } else {
                                AppLog.error("Error attestating key: \(error?.localizedDescription ?? "")")
                                errorHandler(error)
                                return
                            }
                        })
                    }
                    
                }
            })
        })
    }
    
    public func getAttestation(nonce: String, completionHandler: @escaping (String) -> Void, errorHandler: @escaping (Error?) -> Void) {
        self.getKeyID(completion: { keyID in
            if let keyID = keyID {
                if let nonceData = nonce.data(using: .utf8) {
                    let clientDataHash = Data(SHA256.hash(data: nonceData))
                    self.service.attestKey(keyID, clientDataHash: clientDataHash, completionHandler: { data, error in
                        
                        // Convert Base64URL string to Data
                        guard let attestationRawData = data else {
                            AppLog.error("❌ Could not decode attestation data")
                            errorHandler(nil)
                            return
                        }
                        
                        // Extract public key
                        guard let secKey = self.extractPublicKey(from: attestationRawData),
                              let rawPubKey = self.rawPublicKeyDER(secKey) else {
                            AppLog.error("❌ Could not extract public key from attestation")
                            errorHandler(nil)
                            return
                        }
                        
                        let pubKeyHash = Data(SHA256.hash(data: rawPubKey))
                        
                        // Print everything for comparison
                        AppLog.debug("✅ Raw Public Key:", rawPubKey.base64EncodedString())
                        AppLog.debug("✅ Public Key SHA256:", pubKeyHash.base64EncodedString())
                        
                        
                        if let data = data?.base64URLEncodedString() {
                            completionHandler(data)
                        } else {
                            AppLog.error("Error attestating key: \(error?.localizedDescription ?? "")")
                            errorHandler(error)
                            return
                        }
                    })
                }
            }
        })
    }
    
    func sha256(_ data: Data) -> Data {
        Data(SHA256.hash(data: data))
    }
    
    func rawPublicKeyDER(_ publicKey: SecKey) -> Data? {
        var error: Unmanaged<CFError>?
        return SecKeyCopyExternalRepresentation(publicKey, &error) as Data?
    }
    
    func extractPublicKey(from attestationObject: Data) -> SecKey? {
        // Decode CBOR → result is CBOR?
        guard let decoded = try? CBOR.decode([UInt8](attestationObject)) else {
            AppLog.error("❌ Failed to decode CBOR attestationObject")
            return nil
        }
        
        // Root must be a CBOR map
        guard case let CBOR.map(attMap) = decoded else {
            AppLog.error("❌ attestationObject root is not a CBOR map")
            return nil
        }
        
        // Get "attStmt"
        guard let attStmtItem = attMap[CBOR.utf8String("attStmt")] else {
            AppLog.error("❌ No attStmt in attestationObject")
            return nil
        }
        
        guard case let CBOR.map(attStmt) = attStmtItem else {
            AppLog.error("❌ attStmt is not a map")
            return nil
        }
        
        // Get "x5c" certificate array
        guard let x5cItem = attStmt[CBOR.utf8String("x5c")] else {
            AppLog.error("❌ No x5c array in attStmt")
            return nil
        }
        
        guard case let CBOR.array(certs) = x5cItem,
              let firstCert = certs.first else {
            AppLog.error("❌ x5c is not an array")
            return nil
        }
        
        // Extract leaf certificate (byteString)
        guard case let CBOR.byteString(certBytes) = firstCert else {
            AppLog.error("❌ x5c[0] is not byteString")
            return nil
        }
        
        let certData = Data(certBytes)
        
        guard let certificate = SecCertificateCreateWithData(nil, certData as CFData) else {
            AppLog.error("❌ Could not create SecCertificate")
            return nil
        }
        
        // Extract public key
        guard let publicKey = SecCertificateCopyKey(certificate) else {
            AppLog.error("❌ Could not extract public key from certificate")
            return nil
        }
        
        return publicKey
    }
    
    func signWithAppAttestKey(
        keyID: String,
        message: Data,
        completion: @escaping (String?) -> Void,
        errorHandler: @escaping (Error?) -> Void) {
            service.generateAssertion(keyID, clientDataHash: message) { assertion, error in
                if let error = error {
                    errorHandler(error)
                    return
                }
                
                guard let assertion = assertion else {
                    errorHandler(NSError(domain: "AppAttest", code: -1,
                                         userInfo: [NSLocalizedDescriptionKey: "No assertion returned"]))
                    return
                }
                
                do {
                    // Decode CBOR
                    let decoded = try CBORDecoder(input: [UInt8](assertion)).decodeItem()
                    guard case let .map(map) = decoded,
                          case let .byteString(sigBytes)? = map[CBOR.utf8String("signature")] else {
                        throw NSError(domain: "AppAttest", code: -2,
                                      userInfo: [NSLocalizedDescriptionKey: "Signature not found in CBOR map"])
                    }
                    
                    // Convert DER → raw (r||s)
                    let derSig = Data(sigBytes)
                    let rawSig = try self.derToRaw(signature: derSig)
                    
                    // Base64URL encode
                    let base64Sig = rawSig.base64URLEncodedString()
                    completion(base64Sig)
                } catch {
                    errorHandler(error)
                }
            }
        }
    
    // MARK: - DER to Raw Conversion
    func derToRaw(signature derSig: Data) throws -> Data {
        var raw = Data()
        var parser = ASN1Parser(data: derSig)
        let sequence = try parser.parseSequence()
        guard sequence.count == 2 else {
            throw NSError(domain: "AppAttest", code: -3,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid DER signature"])
        }
        raw.append(sequence[0]) // r
        raw.append(sequence[1]) // s
        return raw
    }
    
    
    
    enum JWTError: Error {
        case keyGenerationFailed
        case keyNotFound
        case signingFailed
        case encodingFailed
        case invalidKey
        case attestationFailed
        case attestationNotSupported
    }
}

extension AppSecurityLayer {
    fileprivate func insertKey(keyID: String, completion: @escaping (Bool) -> Void) {
        if let keyData = KeychainManager.shared.convertToData(item: keyID) {
            let query = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: self.ENCLAVE_KEY_ID,
                kSecValueData as String: keyData,
            ] as CFDictionary
            
            KeychainManager.shared.addItemToKeychain(query: query, completion: completion)
        }
    }
    
    public func getKeyID(completion: @escaping (String?) -> Void) {
        let query = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: self.ENCLAVE_KEY_ID,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ] as CFDictionary
        
        KeychainManager.shared.retrieve(query: query, completion: { data in
            if let data = data, let dataString = KeychainManager.shared.convertToString(item: data) {
                completion(dataString)
                return
            }
            
            completion(nil)
        })
    }
    
    public func deleteKeyID(completion: @escaping (Bool) -> Void) {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount as String: self.ENCLAVE_KEY_ID,
            kSecAttrSynchronizable: kSecAttrSynchronizableAny
        ] as CFDictionary
        
        KeychainManager.shared.delete(query: query, completion: completion)
    }
    
    fileprivate func createSEKeys(tagData: Data, completion: @escaping (Data?) -> Void) {
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: tagData
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        let keyAttrs: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String: 256,
            kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave,
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String: true,
                kSecAttrApplicationTag as String: tagData
            ]
        ]
        
        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(keyAttrs as CFDictionary, &error) else {
            completion(nil)
            return
        }
        
        // Step 3: Get public key
        guard let publicKey = SecKeyCopyPublicKey(privateKey),
              let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error) as Data?  else {
            completion(nil)
            return
        }
        
        completion(publicKeyData)
    }
}


struct ASN1Parser {
    private var data: Data
    private var index: Int = 0
    
    init(data: Data) {
        self.data = data
    }
    
    mutating func parseSequence() throws -> [Data] {
        guard readByte() == 0x30 else { throw NSError(domain: "ASN1", code: -1, userInfo: nil) }
        _ = try readLength()
        var items: [Data] = []
        while index < data.count {
            guard readByte() == 0x02 else { break }
            let len = try readLength()
            let value = readBytes(len)
            items.append(value)
        }
        return items
    }
    
    private mutating func readByte() -> UInt8 {
        let byte = data[index]
        index += 1
        return byte
    }
    
    private mutating func readLength() throws -> Int {
        let first = readByte()
        if first & 0x80 == 0 {
            return Int(first)
        }
        let count = Int(first & 0x7F)
        var length = 0
        for _ in 0..<count {
            length = (length << 8) | Int(readByte())
        }
        return length
    }
    
    private mutating func readBytes(_ count: Int) -> Data {
        let slice = data[index..<index+count]
        index += count
        return slice
    }
}
