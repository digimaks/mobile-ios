// SPDX-License-Identifier: EUPL-1.2

//
//  PkceUtils.swift
//  edim
//
//  Created by Matīss Mamedovs on 08/07/2025.

import Foundation
import CryptoKit
import os

private let pkceLog = Logger(subsystem: Bundle.main.bundleIdentifier ?? "lv.zzdats.edim",
                             category: "pkce")

class PkceUtils {
    
    @MainActor public static let shared = PkceUtils()
    
    func generateCodeVerifier() -> String {
        Self.randomString(length: 64, alphabet: Self.unreservedAlphabet)
    }
    
    func generateCodeChallenge(codeVerifier: String) -> String? {
        guard let data = codeVerifier.data(using: .ascii) else { return nil }
        
        return Data(SHA256.hash(data: data)).base64URLEncodedString()
    }
    
    func generateRandomState() -> String {
        Self.randomString(length: 32, alphabet: Self.alphanumericAlphabet)
    }
}

// MARK: - Random generation

extension PkceUtils {
    
    fileprivate static let unreservedAlphabet = Array(
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
    )
    
    fileprivate static let alphanumericAlphabet = Array(
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    )
    
    fileprivate static func randomString(length: Int, alphabet: [Character]) -> String {
        precondition(length > 0, "length must be positive")
        precondition(!alphabet.isEmpty, "alphabet must not be empty")
        
        let count = alphabet.count
        let acceptanceLimit = 256 - (256 % count)
        
        var result = ""
        result.reserveCapacity(length)
        
        while result.count < length {
            // Draw a batch rather than one byte at a time; some will be rejected.
            for byte in randomBytes(count: length) where result.count < length {
                if Int(byte) < acceptanceLimit {
                    result.append(alphabet[Int(byte) % count])
                }
            }
        }
        
        return result
    }
    
    fileprivate static func randomBytes(count: Int) -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: count)
        let status = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
        
        guard status == errSecSuccess else {
            pkceLog.error("SecRandomCopyBytes failed (OSStatus \(status)); using system RNG")
            var generator = SystemRandomNumberGenerator()
            return (0..<count).map { _ in UInt8.random(in: .min ... .max, using: &generator) }
        }
        
        return bytes
    }
}
