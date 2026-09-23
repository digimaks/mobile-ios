// SPDX-License-Identifier: EUPL-1.2

//
//  RealmManager.swift
//  edim
//
//  Created by Matīss Mamedovs on 20/02/2025.
//

import RealmSwift
import Foundation
import Security
import KeychainWrapperPackage

final public class RealmManager: Sendable {
    
    public enum TransactionState: String, CaseIterable {
        case SUCCESS, ERROR, CANCELLED
    }
    
    @MainActor public static let shared = RealmManager()
    
    @MainActor public func insertTransaction(id: String, type: TransactionStatus, status: TransactionState = .SUCCESS, authority: String = "") {
        let item = self.constructTransaction(id: id, type: type, status: status, authority: authority)
        let realm = try? Realm(configuration: RealmManager.configuration)
        do {
            try realm?.write {
                realm?.add(item)
                AppLog.debug("transaction added succesfully")
            }
        } catch {
            AppLog.error("An error occurred while saving the status: \(error)")
        }
    }
    
    public func deleteTransactions() {
        let realm = try? Realm(configuration: RealmManager.configuration)
        
        if let items = realm?.objects(Transaction.self) {
            do {
                try realm?.write {
                    realm?.delete(items)
                    AppLog.debug("transactions delete succesfully")
                }
            } catch {
                AppLog.error("An error occurred while saving the status: \(error)")
            }
        }
    }
    
    public func getTransactions(for identifier: String?) -> [Transaction]? {
        let realm = try? Realm(configuration: RealmManager.configuration)
        if let identifier = identifier {
            let items = realm?.objects(Transaction.self).where {
                $0.documentId == identifier
            }.sorted(by: { $0.timestamp > $1.timestamp })
            
            return items?.map{$0}
        } else {
            return realm?.objects(Transaction.self).sorted(by: { $0.timestamp > $1.timestamp }).map(\.self)
        }
    }
    
    @MainActor fileprivate func constructTransaction(id: String, type: TransactionStatus, status: TransactionState, authority: String) -> Transaction {
        if let detailDoc = WalletInstance.shared.fetchDocument(id: id)?.transformToDocumentDetailsUi() {
            return Transaction(id: UUID().uuidString,
                               documentId: id,
                               docType: detailDoc.type.rawValue,
                               nameSpace: detailDoc.documentName,
                               timestamp: Int(Date().timeIntervalSince1970 * 1000),
                               status: status.rawValue,
                               authority: authority.isEmpty ? detailDoc.getIssuanceAuthority() : authority,
                               eventType: type.rawValue)
        } else if let signature = RealmManager.shared.getSignature(Sid: id) {
            return Transaction(id: UUID().uuidString,
                               documentId: id,
                               docType: signature.isSign ? SignatureHelper.ESIGN_TYPE : SignatureHelper.ESEAL_TYPE,
                               nameSpace: signature.isSign ? SignatureHelper.ESIGN_NAME : SignatureHelper.ESEAL_NAME,
                               timestamp: Int(Date().timeIntervalSince1970 * 1000),
                               status: status.rawValue,
                               authority: "",
                               eventType: type.rawValue)
        } else if id == "eparaksts" {
            return Transaction(id: UUID().uuidString,
                               documentId: id,
                               docType: SignatureHelper.ESIGN_TYPE,
                               nameSpace: SignatureHelper.ESIGN_NAME,
                               timestamp: Int(Date().timeIntervalSince1970 * 1000),
                               status: status.rawValue,
                               authority: "",
                               eventType: type.rawValue)
        } else {
            return Transaction(id: UUID().uuidString, documentId: id, docType: "", nameSpace: "", timestamp: Int(Date().timeIntervalSince1970 * 1000), status: "ERROR", authority: "", eventType: type.rawValue)
        }
    }
    
    @MainActor public func insertFavoriteDocument(documentID: String) {
        let item = self.constructFavoriteDocument(id: UUID().uuidString, documentID: documentID)
        let realm = try? Realm(configuration: RealmManager.configuration)
        do {
            try realm?.write {
                realm?.add(item)
                AppLog.debug("favorite document added succesfully")
            }
        } catch {
            AppLog.error("An error occurred while saving the status: \(error)")
        }
    }
    
    @MainActor public func deleteFavoriteDocument(documentID: String) {
        let realm = try? Realm(configuration: RealmManager.configuration)
        
        let item = realm?.objects(FavoriteDocument.self).where {
            $0.documentID == documentID
        }.first
        
        guard let item = item else { return }
        
        do {
            try realm?.write {
                realm?.delete(item)
                AppLog.debug("favorite document deleted succesfully")
            }
        } catch {
            AppLog.error("An error occurred while saving the status: \(error)")
        }
    }
    
    @MainActor public func isFavoriteDocument(documentID: String) -> Bool {
        let realm = try? Realm(configuration: RealmManager.configuration)
        let item = realm?.objects(FavoriteDocument.self).where {
            $0.documentID == documentID
        }.first
        
        return item != nil
    }
    
    @MainActor fileprivate func constructFavoriteDocument(id: String, documentID: String) -> FavoriteDocument {
        let doc = FavoriteDocument(id: id, documentId: documentID)
        
        return doc
    }
    
    @MainActor fileprivate func constructSignature(signature: ElectronicSignatureItem, isSign: Bool) -> Signature {
        let item = Signature(Sid: signature.Sid, cn: signature.cn, expiresOn: signature.expiresOn, issuedOn: signature.issuedOn, isSign: isSign)
        
        return item
    }
    
    @MainActor public func insertElectronicSignature(signature: ElectronicSignatureItem, isSign: Bool) {
        let item = self.constructSignature(signature: signature, isSign: isSign)
        let realm = try? Realm(configuration: RealmManager.configuration)
        do {
            try realm?.write {
                realm?.add(item)
                AppLog.debug("electronic signature added succesfully")
            }
        } catch {
            AppLog.error("An error occurred while saving the status: \(error)")
        }
    }
    
    public func getSignatures() -> [Signature]? {
        let realm = try? Realm(configuration: RealmManager.configuration)
        let items = realm?.objects(Signature.self)
        
        return items?.map{$0}
    }
    
    @MainActor public func hasESign() -> Bool {
        let realm = try? Realm(configuration: RealmManager.configuration)
        
        let item = realm?.objects(Signature.self).where {
            $0.isSign
        }.first
        
        return item != nil
    }
    
    @MainActor public func deleteSignature(Sid: String) {
        RealmManager.shared.deleteIssuanceMethod(id: Sid)

        let realm = try? Realm(configuration: RealmManager.configuration)
        
        let item = realm?.objects(Signature.self).where {
            $0.Sid == Sid
        }.first
        
        guard let item = item else { return }
        
        do {
            try realm?.write {
                realm?.delete(item)
                
                AppLog.debug("signature deleted succesfully")
            }
        } catch {
            AppLog.error("An error occurred while saving the status: \(error)")
        }
    }
    
    public func deleteSignatures() {
        let realm = try? Realm(configuration: RealmManager.configuration)
        
        if let items = realm?.objects(Signature.self) {
            do {
                try realm?.write {
                    realm?.delete(items)
                    AppLog.debug("signatures delete succesfully")
                }
            } catch {
                AppLog.error("An error occurred while saving the status: \(error)")
            }
        }
    }
    
    @MainActor public func signatureExists(Sid: String) -> Bool {
        let realm = try? Realm(configuration: RealmManager.configuration)
        
        let item = realm?.objects(Signature.self).where {
            $0.Sid == Sid
        }.first
        
        return item != nil
    }
    
    @MainActor public func getSignature(Sid: String) -> Signature? {
        let realm = try? Realm(configuration: RealmManager.configuration)
        
        let item = realm?.objects(Signature.self).where {
            $0.Sid == Sid
        }.first
        
        return item
    }
    
    @MainActor public func isSign(Sid: String) -> Bool {
        if Sid == "eparaksts" {
            return true
        }
        if let signature = self.getSignature(Sid: Sid) {
            return signature.isSign
        }
        
        return false
    }
    
    @MainActor public func insertVendor(id: String, fields: [String]) {
        let list = List<String>()
        list.append(objectsIn: fields)
        let vendor = Vendor()
        vendor.vendorID = id
        vendor.attributeFields = list

        let realm = try? Realm(configuration: RealmManager.configuration)
        do {
            try realm?.write {
                realm?.add(vendor, update: .modified)
                AppLog.debug("vendor added/modified succesfully")
            }
        } catch {
            AppLog.error("An error occurred while saving the status: \(error)")
        }
    }
    
    fileprivate func getVendor(vendorID: String) -> Vendor? {
        let realm = try? Realm(configuration: RealmManager.configuration)
        
        let item = realm?.objects(Vendor.self).where {
            $0.vendorID == vendorID
        }.first
        
        return item
    }
    
    func hasVendor(id: String) -> Bool {
        let realm = try? Realm(configuration: RealmManager.configuration)
        
        let item = realm?.objects(Vendor.self).where {
            $0.vendorID == id
        }.first
        
        return item != nil
    }
    
    func hasSameFields(vendorID: String, fields: [String]) -> Bool {
        if let vendor = self.getVendor(vendorID: vendorID) {
            let incomingSet = List<String>()
            incomingSet.append(objectsIn: fields)
            
            return areEqual(vendor.attributeFields, incomingSet)
        } else {
            return false
        }
    }
    
    fileprivate func areEqual(_ lhs: List<String>, _ rhs: List<String>) -> Bool {
        return Set(lhs) == Set(rhs)
    }
    
    @MainActor public func deleteVendor(id: String) {
        let realm = try? Realm(configuration: RealmManager.configuration)
        
        let item = realm?.objects(Vendor.self).where {
            $0.vendorID == id
        }.first
        
        guard let item = item else { return }
        
        do {
            try realm?.write {
                realm?.delete(item)
                AppLog.debug("vendor deleted succesfully")
            }
        } catch {
            AppLog.error("An error occurred while saving the status: \(error)")
        }
    }
    
    @MainActor public func insertIssuanceMethod(id: String, method: IssuanceMethodType) {
        let vendor = IssuanceMethod()
        vendor.documentID = id
        vendor.method = method

        let realm = try? Realm(configuration: RealmManager.configuration)
        do {
            try realm?.write {
                realm?.add(vendor)
                AppLog.debug("issuance method added/modified succesfully")
            }
        } catch {
            AppLog.error("An error occurred while saving the status: \(error)")
        }
    }
    
    @MainActor public func getIssuanceMethod(id: String) -> String? {
        let realm = try? Realm(configuration: RealmManager.configuration)
        
        let item = realm?.objects(IssuanceMethod.self).where {
            $0.documentID == id
        }.first
        
        return item?.method.rawValue
    }
    
    @MainActor public func deleteIssuanceMethod(id: String) {
        let realm = try? Realm(configuration: RealmManager.configuration)
        
        let item = realm?.objects(IssuanceMethod.self).where {
            $0.documentID == id
        }.first
        
        guard let item = item else { return }
        
        do {
            try realm?.write {
                realm?.delete(item)
                AppLog.debug("issuance method deleted succesfully")
            }
        } catch {
            AppLog.error("An error occurred while saving the status: \(error)")
        }
    }
    
    @MainActor func deleteAllIssuanceMethods() {
        let realm = try? Realm(configuration: RealmManager.configuration)
        
        if let items = realm?.objects(IssuanceMethod.self) {
            do {
                try realm?.write {
                    realm?.delete(items)
                    AppLog.debug("issuance methods delete succesfully")
                }
            } catch {
                AppLog.error("An error occurred while saving the status: \(error)")
            }
        }
    }
    
}

extension RealmManager {
    fileprivate static let ENCRYPTION_KEY_ACCOUNT = "REALM_ENCRYPTION_KEY"
    fileprivate static let ENCRYPTION_KEY_LENGTH = 64
    
    static let configuration: Realm.Configuration = {
        let resolved = makeConfiguration()
        Realm.Configuration.defaultConfiguration = resolved
        return resolved
    }()
    
    fileprivate static func makeConfiguration() -> Realm.Configuration {
        var config = Realm.Configuration.defaultConfiguration

        guard let key = getOrCreateEncryptionKey() else {
            realmLog("Keychain unavailable - continuing without at-rest encryption.")
            config.encryptionKey = nil
            return config
        }
        
        config.encryptionKey = key
        
        if let fileURL = config.fileURL {
            encryptExistingDatabaseIfNeeded(at: fileURL, key: key)
        }
        
        if canOpen(config) {
            return config
        }
        
        realmLog("Encrypted database could not be opened - recreating local cache.")
        if let fileURL = config.fileURL {
            removeDatabaseFiles(at: fileURL)
        }
        
        if canOpen(config) {
            return config
        }
        
        realmLog("Falling back to an unencrypted Realm - encrypted open failed.")
        config.encryptionKey = nil
        return config
    }
    
    fileprivate static func encryptExistingDatabaseIfNeeded(at fileURL: URL, key: Data) {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: fileURL.path) else { return }
        
        var plaintextConfig = Realm.Configuration.defaultConfiguration
        plaintextConfig.fileURL = fileURL
        plaintextConfig.encryptionKey = nil
        
        guard canOpen(plaintextConfig) else { return }
        
        let temporaryURL = fileURL
            .deletingLastPathComponent()
            .appendingPathComponent("migration-\(UUID().uuidString).realm")
        
        var didWriteCopy = false
        autoreleasepool {
            do {
                let source = try Realm(configuration: plaintextConfig)
                try source.writeCopy(toFile: temporaryURL, encryptionKey: key)
                didWriteCopy = true
            } catch {
                realmLog("Could not create encrypted copy: \(error)")
            }
        }
        
        guard didWriteCopy else {
            removeDatabaseFiles(at: temporaryURL)
            return
        }
        
        let backupURL = URL(fileURLWithPath: fileURL.path + ".plaintext-backup")
        removeDatabaseFiles(at: backupURL)
        
        do {
            try fileManager.moveItem(at: fileURL, to: backupURL)
        } catch {
            realmLog("Could not set aside plaintext database: \(error)")
            removeDatabaseFiles(at: temporaryURL)
            return
        }
        
        do {
            try fileManager.moveItem(at: temporaryURL, to: fileURL)
        } catch {
            realmLog("Could not install encrypted database: \(error)")
            try? fileManager.moveItem(at: backupURL, to: fileURL)
            removeDatabaseFiles(at: temporaryURL)
            return
        }

        removeAuxiliaryFiles(at: fileURL)
        removeDatabaseFiles(at: backupURL)
        realmLog("Local database migrated to encrypted storage.")
    }
    
    fileprivate static func getOrCreateEncryptionKey() -> Data? {
        let readQuery = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: ENCRYPTION_KEY_ACCOUNT,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ] as CFDictionary
        
        if let existingKey = try? KeychainManager.shared.throwRetrieve(query: readQuery),
           existingKey.count == ENCRYPTION_KEY_LENGTH {
            return existingKey
        }
        
        var keyBytes = [UInt8](repeating: 0, count: ENCRYPTION_KEY_LENGTH)
        guard SecRandomCopyBytes(kSecRandomDefault, keyBytes.count, &keyBytes) == errSecSuccess else {
            realmLog("Unable to generate a secure random Realm encryption key.")
            return nil
        }
        let newKey = Data(keyBytes)
        
        let addQuery = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: ENCRYPTION_KEY_ACCOUNT,
            kSecValueData as String: newKey,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ] as CFDictionary
        
        var didStore = false
        KeychainManager.shared.addItemToKeychain(query: addQuery) { didStore = $0 }
        
        guard didStore else {
            realmLog("Could not persist the Realm encryption key.")
            return nil
        }
        
        return newKey
    }
    
    fileprivate static func canOpen(_ configuration: Realm.Configuration) -> Bool {
        var succeeded = false
        autoreleasepool {
            do {
                _ = try Realm(configuration: configuration)
                succeeded = true
            } catch {
                succeeded = false
            }
        }
        return succeeded
    }
    
    fileprivate static func removeDatabaseFiles(at fileURL: URL) {
        try? FileManager.default.removeItem(at: fileURL)
        removeAuxiliaryFiles(at: fileURL)
    }
    
    fileprivate static func removeAuxiliaryFiles(at fileURL: URL) {
        for suffix in ["lock", "note", "management"] {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: fileURL.path + ".\(suffix)"))
        }
    }
    
    fileprivate static func realmLog(_ message: String) {
        #if DEBUG
        AppLog.debug("[RealmManager] \(message)")
        #endif
    }
}
