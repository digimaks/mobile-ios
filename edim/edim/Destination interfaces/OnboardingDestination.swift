// SPDX-License-Identifier: EUPL-1.2

//
//  OnboardingDestination.swift
//  edim
//
//  Created by Matīss Mamedovs on 22/01/2025.
//

import Foundation
import AuthWrapperPackage
import UtilitiesPackage
import Crypto
import SwiftCBOR
import FirebaseCrashlytics

final class OnboardingDestination: Destination, Sendable {
    static let MAIN_PID_ISSUED: String = "MAIN_PID_ISSUED"
    
    public static let shared = OnboardingDestination()
    
    fileprivate var issuanceMethodType: IssuanceMethodType?
    
    public override init() {
        super.init()
    }
    
    override func start() {
        Task {
            guard let localInit = await self.local else {
                return
            }
            
            switch localInit.funcName {
            case .initiateEParaksts:
                await self.initiateEParaksts()
            case .initiateSmartID:
                await self.initiateSmartID()
            case .submitEmail:
                await self.submitEmail()
            case .verifyEmailOTP:
                await self.verifyEmailOTP()
            case .submitSms:
                await self.submitSms()
            case .verifySmsOTP:
                await self.verifySmsOTP()
            case .initialiseWallet:
                await self.initialiseWallet()
            case .activateWallet:
                await self.activateWallet()
            default:
                break
            }
        }
    }
}

extension OnboardingDestination {
    fileprivate func initiateEParaksts() {
        Task {
            if let local = self.local {
                self.issuanceMethodType = .eparaksts
                let vc = EparakstsViewController(isEparaksts: true)
                vc.delegate = self
                self.parent?.present(vc, animated: true)
                await self.inject(id: local.id, status: .SUCCESS, message: nil, data: nil as String?)
            }
        }
    }
    
    fileprivate func initiateSmartID() {
        Task {
            if let local = self.local {
                self.issuanceMethodType = .smart_id
                let vc = EparakstsViewController(isEparaksts: false)
                vc.delegate = self
                self.parent?.present(vc, animated: true)
                await self.inject(id: local.id, status: .SUCCESS, message: nil, data: nil as String?)
            }
        }
    }
    
    fileprivate func submitEmail() {
        Task {
            if let local = self.local {
                let email = local.params?["email"] as? String ?? ""
                PersonService.shared.onboardEmail(email: email, completionCallback: {
                    Task {
                        await self.inject(id: local.id, status: .SUCCESS, message: nil, data: nil as String?)
                    }
                }, errorCallback: {
                    Task {
                        await self.inject(id: local.id, status: .ERROR, message: nil, data: nil as String?)
                    }
                })
            }
        }
    }
    
    fileprivate func verifyEmailOTP() {
        Task {
            if let local = self.local {
                let code = local.params?["otp"] as? String ?? ""
                PersonService.shared.verifyEmail(code: code, completionCallback: {
                    Task {
                        await self.inject(id: local.id, status: .SUCCESS, message: nil, data: nil as String?)
                    }
                }, errorCallback: { error in
                    Task {
                        await self.inject(id: local.id, status: .ERROR, message: nil, data: nil as String?, error: String(error))
                    }
                })
            }
        }
    }
    
    fileprivate func submitSms() {
        Task {
            if let local = self.local {
                let phone = local.params?["number"] as? String ?? ""
                PersonService.shared.onboardPhone(phone: phone, completionCallback: {
                    Task {
                        await self.inject(id: local.id, status: .SUCCESS, message: nil, data: nil as String?)
                    }
                }, errorCallback: {
                    Task {
                        await self.inject(id: local.id, status: .ERROR, message: nil, data: nil as String?)
                    }
                })
            }
        }
    }
    
    fileprivate func verifySmsOTP() {
        Task {
            if let local = self.local {
                let code = local.params?["otp"] as? String ?? ""
                PersonService.shared.verifyPhone(code: code, completionCallback: {
                    Task {
                        await self.inject(id: local.id, status: .SUCCESS, message: nil, data: nil as String?)
                    }
                }, errorCallback: { error in
                    Task {
                        await self.inject(id: local.id, status: .ERROR, message: nil, data: nil as String?, error: String(error))
                    }
                })
            }
        }
    }
    
    fileprivate func activateWallet() {
        Task {
            if let local = self.local {
                Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
                await self.inject(id: local.id, status: .SUCCESS, message: nil, data: nil as String?)
            }
        }
    }
    
    fileprivate func initialiseWallet() {
        Task {
            if let local = self.local {
                if await walletKeyExists() {
                    self.issuePid(local: local)
                } else {
                    WUAService.shared.getNonce(completionCallback: { nonce in
                        AppSecurityLayer.shared.initWalletAttestation(nonce: nonce.nonce, completionHandler: { data, keyId, baseNonce in
                            DispatchQueue.main.async(execute: {
                                guard let data = data, let keyId = keyId else {
                                    Task {
                                        await self.inject(id: local.id, status: .ERROR, message: nil, data: nil as String?)
                                        
                                    }
                                    return
                                }
                               
                                let attestationData = data.base64URLDecodedData()!
                                
                                // Extract public key from attestationObject
                                guard let secKey = self.extractPublicKey(from: attestationData) else {
                                    AppLog.error("Could not extract public key from attestation x5c")
                                    return
                                }
                                
                                // Raw public key (65 bytes)
                                guard let publicKeyRaw = self.rawPublicKeyDER(secKey) else {
                                    AppLog.error("Could not export raw public key")
                                    return
                                }

                                // SHA256(public key)
                                let publicKeyHash = self.sha256(publicKeyRaw)
                                
                                WUAService.shared.createInstance(data: data, keyId: keyId, nonce: baseNonce, completionCallback: { success in
                                    if success {
                                        self.issuePid(local: local)
                                    } else {
                                        Task {
                                            await self.inject(id: local.id, status: .ERROR, message: nil, data: nil as String?)
                                        }
                                    }
                                }, errorCallback: {})
                            })
                        }, errorHandler: { error in
                            Task {
                                await self.inject(id: local.id, status: .ERROR, message: nil, data: nil as String?)
                            }
                        })
                        
                    }, errorCallback: {
                        Task {
                            await self.inject(id: local.id, status: .ERROR, message: nil, data: nil as String?)
                        }
                    })
                }
            }
        }
    }
    
    func walletKeyExists() async -> Bool {
        await withCheckedContinuation { continuation in
            AppSecurityLayer.shared.getKeyID(completion: { keyId in
                continuation.resume(returning: !(keyId?.isEmpty ?? true))
            })
        }
    }
    
    func issuePid(local: LocalInitObject) {
        WalletService.shared.getOfferUri(type: "pid", completionCallback: { uri in
            Task {
                UserDefaultsManager.shared.set(value: true, key: OnboardingDestination.MAIN_PID_ISSUED)
                let models = await WalletInstance.shared.qrcodeIssue(uri: uri.urlData)
                let result = await WalletInstance.shared.issueDocumentOffer(uri: uri.urlData, models: models?.docModels ?? [], txCode: nil)
                
                Task {
                    if result.0 {
                        if let method = self.issuanceMethodType, let id = result.1 {
                            RealmManager.shared.insertIssuanceMethod(id: id, method: method)
                            self.issuanceMethodType = nil
                        }
                        await WalletInstance.shared.loadDocuments()
                        self.navigate(pathName: "documentOfferManual", params: "status: 'success'")
                        await self.inject(id: local.id, status: .SUCCESS, message: nil, data: nil as String?)
                    } else {
                        await self.inject(id: local.id, status: .ERROR, message: nil, data: nil as String?, error: "authentication_error")
                    }
                }
            }
        }, eparakstsErrorCallback: {
            Task {
                await self.inject(id: local.id, status: .ERROR, message: nil, data: nil as String?)
            }
        }, errorCallback: {
            Task {
                await self.inject(id: local.id, status: .ERROR, message: nil, data: nil as String?)
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
            AppLog.error("Failed to decode CBOR attestationObject")
            return nil
        }
        
        // Root must be a CBOR map
        guard case let CBOR.map(attMap) = decoded else {
            AppLog.error("AttestationObject root is not a CBOR map")
            return nil
        }
        
        // Get "attStmt"
        guard let attStmtItem = attMap[CBOR.utf8String("attStmt")] else {
            AppLog.error("No attStmt in attestationObject")
            return nil
        }
        
        guard case let CBOR.map(attStmt) = attStmtItem else {
            AppLog.error("AttStmt is not a map")
            return nil
        }
        
        // Get "x5c" certificate array
        guard let x5cItem = attStmt[CBOR.utf8String("x5c")] else {
            AppLog.error("No x5c array in attStmt")
            return nil
        }
        
        guard case let CBOR.array(certs) = x5cItem,
              let firstCert = certs.first else {
            AppLog.error("x5c is not an array")
            return nil
        }
        
        // Extract leaf certificate (byteString)
        guard case let CBOR.byteString(certBytes) = firstCert else {
            AppLog.error("x5c[0] is not byteString")
            return nil
        }
        
        let certData = Data(certBytes)
        
        guard let certificate = SecCertificateCreateWithData(nil, certData as CFData) else {
            AppLog.error("Could not create SecCertificate")
            return nil
        }
        
        // Extract public key
        guard let publicKey = SecCertificateCopyKey(certificate) else {
            AppLog.error("Could not extract public key from certificate")
            return nil
        }
        
        return publicKey
    }
}

extension OnboardingDestination: EparakstsAuthFinishedDelegate {
    nonisolated func eparakstsAuthFinished(isSuccess: Bool) {
        if isSuccess {
            Task {
                await self.navigate(pathName: "loading")
            }
        }
    }
}

public extension String {
    public func base64URLDecodedData() -> Data? {
        var str = self
        str = str.replacingOccurrences(of: "-", with: "+")
        str = str.replacingOccurrences(of: "_", with: "/")

        // Pad with "=" to make length % 4 == 0
        let padding = 4 - (str.count % 4)
        if padding < 4 {
            str += String(repeating: "=", count: padding)
        }

        return Data(base64Encoded: str)
    }
}
