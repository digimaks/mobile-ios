// SPDX-License-Identifier: EUPL-1.2

//
//  IssuanceDestination.swift
//  edim
//
//  Created by Matīss Mamedovs on 28/01/2025.
//
import QRCodeScannerPackage
import Foundation
import MdocDataTransfer18013
import MdocDataModel18013
import EudiWalletKit
import UtilitiesPackage
import UIKit
import CryptoKit
import FirebaseCrashlytics
import AVFoundation

final class IssuanceDestination: Destination, Sendable {
    
    public static let shared = IssuanceDestination()
    
    @MainActor fileprivate var offerIssuanceModel: OfferedIssuanceModel?
    @MainActor fileprivate var offerUri: String = ""
    public var tempRemotePresentation: RemotePresentationLocalResponse?
    
    var isSignAction: Bool = true
    @MainActor var eSeals: [ElectronicSignatureItem] = []
    
    fileprivate var paymentTimer: Timer?
    fileprivate var paymentTimerCounter: Int = 0
    fileprivate var paymentPingUrl: String = ""
    fileprivate var paymentCompleteUrl: String = ""
    fileprivate var creditor: String = ""
    
    public override init() {
        super.init()
    }
    
    override func start() {
        Task {
            guard let localInit = await self.local else {
                return
            }
            
            switch localInit.funcName {
            case .getDocumentOptions:
                await self.getDocumentOptions(localInit: localInit)
            case .issueDocument:
                await self.issue(localInit: localInit)
            case .scanQrCode:
                await self.scanQrCode(localInit: localInit)
            case .resolveDocumentOffer:
                await self.resolveDocumentOffer(localInit: localInit)
            case .getOfferCodeData:
                await self.getOfferCodeData(localInit: localInit)
            case .issueDocumentOffer:
                await self.issueDocumentOffer(localInit: localInit)
            case .getPidDetails:
                await self.getPidDetails(localInit: localInit)
            case .getUserSignatureOptions:
                await self.getUserSignatureOptions(localInit: localInit)
            case .selectUserSignatures:
                await self.selectUserSignatures(localInit: localInit)
                // PRESENTATION
            case .getRequestDocuments:
                await self.getRequestDocuments(localInit: localInit)
            case .confirmRequest:
                await self.confirmRequest(localInit: localInit)
            case .setVendorPresentationPreference:
                await self.setVendorPresentationPreference(localInit: localInit)
            case .presentationCanceled:
                await self.presentationCanceled(localInit: localInit)
            default:
                break
            }
        }
    }
    
    private let PID_TYPE_CONSTANT: String = "eu.europa.ec.eudi.pid_mdoc"
    private let MDL_TYPE_CONSTANT: String = "eu.europa.ec.eudi.mdl_mdoc"
    private let DIPLOMA_TYPE_CONSTANT: String = "eu.europa.ec.eudi.rtu_diploma_mdoc"
}

extension IssuanceDestination {
    fileprivate func issue(localInit: LocalInitObject) async {
        if let type = localInit.params?["documentType"] as? String {
            if let local = self.local {
                Task {
                    await self.inject(id: local.id, status: .SUCCESS, message: nil, data: nil as String?)
                }
            }
            
            var offerType = ""
            if type == self.PID_TYPE_CONSTANT {
                offerType = "pid"
            } else if type == self.MDL_TYPE_CONSTANT {
                offerType = "mdl"
            } else if type == self.DIPLOMA_TYPE_CONSTANT {
                offerType = "rtu"
            }
            
            if offerType.isEmpty {
                if type == SignatureHelper.ESIGN_TYPE {
                    isSignAction = true
                } else {
                    isSignAction = false
                }
                WalletService.shared.getRedirectUrlForLVRTC(crossdevice: !EparakstsHelper.shared.canOpenLocallyEparaksts(), completionCallback: { redirectUrl in
                    let vc = LVRTCAuthViewController(redirectUrl: redirectUrl)
                    vc.delegate = self
                    self.parent?.present(vc, animated: true)
                })
            } else {
                WalletService.shared.getOfferUri(type: offerType, completionCallback: { uri in
                    Task {
                        let models = await WalletInstance.shared.qrcodeIssue(uri: uri.urlData)
                        let success = await WalletInstance.shared.issueDocumentOffer(uri: uri.urlData, models: models?.docModels ?? [], txCode: nil)
                        
                        await WalletInstance.shared.loadDocuments()
                        
                        if success.0 {
                            if let id = success.1 {
                                RealmManager.shared.insertIssuanceMethod(id: id, method: .qr)
                            }
                            UserDefaultsManager.shared.set(value: true, key: OnboardingDestination.MAIN_PID_ISSUED)
                            self.navigate(pathName: "documentOfferManual", params: "status: 'success'")
                        } else {
                            Crashlytics.crashlytics().log("issueDocumentOffer failed. offerType=\(offerType)")
                            self.navigate(pathName: "documentOfferManual", params: "status: 'error'")
                        }
                    }
                }, eparakstsErrorCallback: {
                    Task {
                        let vc = EparakstsViewController(isEparaksts: true)
                        vc.delegate = self
                        self.parent?.present(vc, animated: true)
                    }
                }, errorCallback: {
                    Task {
                        Crashlytics.crashlytics().log("getOfferUri failed. offerType=\(offerType)")
                        self.navigate(pathName: "documentOfferManual", params: "status: 'error'")
                    }
                })
            }
        }
    }
    
    fileprivate func getDocumentOptions(localInit: LocalInitObject) async {
        do {
            var returnItems: [[String: String]] = []
            var types = try await WalletInstance.shared.getScopedDocuments().filter( { !$0.configId.contains("jwt") })
            types.append(contentsOf: WalletInstance.shared.addSignAndSealType())
            let docs = await WalletInstance.shared.fetchDocuments() ?? []
            if docs.isEmpty {
                let type = types.first(where: { $0.isPid })
                var item: [String: String] = [:]
                item["text"] = type?.name
                item["type"] = type?.configId
                item["exists"] = "false"
                returnItems.append(item)
            } else {
                for type in types {
                    var item: [String: String] = [:]
                    
                    item["text"] = type.isPid ? "PID" : type.name
                    item["type"] = type.configId
                    if type.configId == SignatureHelper.ESEAL_TYPE {
                        item["exists"] = "false"
                    } else {
                        // CANNOT GET HERE WITHOUT ISSUED PID
                        if type.isPid {
                            item["exists"] = "true"
                        } else {
                            item["exists"] = !docs.contains(where: { $0.value.title == type.name }) ? "false" : "true"
                        }
                    }
                    
                    returnItems.append(item)
                }
            }
            
            let docDict = ["options": returnItems]
            if let local = self.local {
                Task {
                    await self.inject(id: local.id, status: .SUCCESS, message: nil, data: docDict)
                }
            }
            
        } catch {
            Crashlytics.crashlytics().record(error: error)
            Crashlytics.crashlytics().log("getDocumentOptions failed")

        }
    }
    
    fileprivate func scanQrCode(localInit: LocalInitObject) async {
        if let parent = self.parent {
            QRScannerManager.shared.setUp(completion: { granted in
                if granted {
                    QRScannerManager.shared.delegate = self
                    QRScannerManager.shared.runSession(for: parent)
                    
                    if let local = self.local {
                        Task {
                            await self.inject(id: local.id, status: .SUCCESS, message: nil, data: nil as String?)
                        }
                    }
                } else {
                    if let local = self.local {
                        Task {
                            Crashlytics.crashlytics().log("Camera permission denied")
                            await self.inject(id: local.id, status: .ERROR, message: nil, data: nil as String?)
                        }
                    }
                    
                    let alert = UIAlertController(
                        title: Texts.CAMERA_PERMISSION_TITLE,
                        message: Texts.CAMERA_PERMISSION_SUBTITLE,
                        preferredStyle: .alert
                    )
                    
                    alert.addAction(UIAlertAction(title: Texts.CAMERA_PERMISSION_OPEN_SETTINGS, style: .default) { _ in
                        if let url = URL(string: UIApplication.openSettingsURLString),
                           UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        }
                    })
                    
                    alert.addAction(UIAlertAction(title: Texts.CAMERA_PERMISSION_CANCEL, style: .cancel))
                    
                    parent.present(alert, animated: true)
                }
                
            })
            
        }
    }
    
    fileprivate func resolveDocumentOffer(localInit: LocalInitObject) async {
        if let model = self.offerIssuanceModel {
            var isPid: Bool = false
            var docs: [[String: String]] = []
            for doc in model.docModels {
                if doc.displayName == "PID" || doc.displayName == "eu.europa.ec.eudi.pid.1" {
                    isPid = true
                }
                let item: [String: String] = ["title": doc.displayName]
                docs.append(item)
            }
            
            let respObj = ResolveOfferLocalResponseObject(documents: docs, issuerName: model.issuerName, txCodeLength: model.txCodeSpec?.length)
            
            if let local = self.local {
                Task {
                    if isPid {
                        await self.inject(id: local.id, status: .SUCCESS, message: nil, data: respObj)
                    } else {
                        if WalletInstance.shared.hasMainPid() {
                            await self.inject(id: local.id, status: .SUCCESS, message: nil, data: respObj)
                        } else {
                            Crashlytics.crashlytics().log("resolveDocumentOffer failed: no pid found")
                            await self.inject(id: local.id, status: .ERROR, message: nil, data: nil as String?)
                        }
                    }
                    
                }
            }
        } else {
            if let local = self.local {
                Task {
                    Crashlytics.crashlytics().log("resolveDocumentOffer failed: offerIssuanceModel is nil")
                    await self.inject(id: local.id, status: .ERROR, message: nil, data: nil as String?)
                }
            }
        }
    }
    
    fileprivate func getOfferCodeData(localInit: LocalInitObject) async {
        if let model = self.offerIssuanceModel {
            let respObj = OfferCodeLocalResponseObject(offerUri: self.offerUri, issuerName: model.issuerName, txCodeLength: model.txCodeSpec?.length ?? 0)
            
            if let local = self.local {
                Task {
                    await self.inject(id: local.id, status: .SUCCESS, message: nil, data: respObj)
                }
            }
        } else {
            if let local = self.local {
                Task {
                    Crashlytics.crashlytics().log("getOfferCodeData failed: offerIssuanceModel is nil")
                    await self.inject(id: local.id, status: .ERROR, message: nil, data: nil as String?)
                }
            }
        }
    }
    
    fileprivate func issueDocumentOffer(localInit: LocalInitObject) async {
        if let model = self.offerIssuanceModel, let uri = localInit.params?["offerUri"] as? String {
            let res = await WalletInstance.shared.issueDocumentOffer(uri: uri, models: model.docModels, txCode: localInit.params?["txCode"] as? String)
            if let local = self.local {
                Task {
                    if res.0 {
                        if let id = res.1 {
                            RealmManager.shared.insertIssuanceMethod(id: id, method: .qr)
                        }
                        await WalletInstance.shared.loadDocuments()
                        UserDefaultsManager.shared.set(value: true, key: OnboardingDestination.MAIN_PID_ISSUED)
                        await self.inject(id: local.id, status: .SUCCESS, message: nil, data: res.0)
                    } else {
                        Crashlytics.crashlytics().log("issueDocumentOffer failed. Wrong tx code or issuer error")
                        await self.inject(id: local.id, status: .ERROR, message: nil, data: nil as String?, error: Texts.WRONG_CONFIRMATION_CODE)
                    }
                }
            }
        }
    }
    
    fileprivate func getPidDetails(localInit: LocalInitObject) async {
        let name = WalletInstance.shared.fetchMainPidDocument()?.transformToDocumentDetailsUi().holdersName ?? ""
        if let local = self.local {
            Task {
                await self.inject(id: local.id, status: .SUCCESS, message: nil, data: ["firstName": name])
            }
        }
    }
    
    fileprivate func getUserSignatureOptions(localInit: LocalInitObject) async {
        var seals: [[String: String]] = []
        
        for seal in self.eSeals {
            var item: [String: String] = [:]
            item["id"] = seal.Sid
            item["name"] = seal.cn
            item[Signature.codingKey(for: \.expiresOn) ?? ""] = seal.expiresOn
            item[Signature.codingKey(for: \.issuedOn) ?? ""] = seal.issuedOn
            item["type"] = SignatureHelper.ESEAL_NAME
            
            seals.append(item)
        }
        
        var eSeals = ["eSeal": seals]
        
        if let local = self.local {
            Task {
                await self.inject(id: local.id, status: .SUCCESS, message: nil, data: ["options": eSeals])
            }
        }
    }
    
    fileprivate func selectUserSignatures(localInit: LocalInitObject) async {
        if let ids = localInit.params?["selectedIds"] as? [String] {
            for id in ids {
                for sign in self.eSeals {
                    if id == sign.Sid {
                        if !RealmManager.shared.signatureExists(Sid: sign.Sid) {
                            RealmManager.shared.insertElectronicSignature(signature: sign, isSign: false)
                            RealmManager.shared.insertTransaction(id: sign.Sid, type: .DOCUMENT_ISSUED)
                            RealmManager.shared.insertFavoriteDocument(documentID: sign.Sid)
                        }
                    }
                }
            }
        }
        
        if let local = self.local {
            Task {
                await self.inject(id: local.id, status: .SUCCESS, message: nil, data: nil as String?)
            }
        }
        self.navigate(pathName: "documentOfferManual", params: "status: 'success'")
    }
    
    fileprivate func issueFromQr(result: String) {
        Task { @MainActor in
            if result.isEmpty {
                Crashlytics.crashlytics().log("QR scan returned empty result")
                self.navigate(pathName: "documentOfferManual", params: "status: 'error'")
            } else {
                let model = await WalletInstance.shared.qrcodeIssue(uri: result)
                self.offerUri = result
                self.offerIssuanceModel = model
                self.navigate(pathName: "documentOffer")
            }
        }
    }
    
    fileprivate func createTempObj(result: String) async throws -> Bool {
        let result = await WalletInstance.shared.startRemotePresentation(uri: result)
        if let session = result.0, let item = result.1 {
            var verifierName: String = session.readerCertIssuer ?? ""
            let verifierIsTrusted: Bool = session.readerCertIssuerValid ?? false
            var presentationTransactionData: PresentationTransactionData?
            var docs: [RemotePresentationDocument] = []
            
            // Unwrap optional docElements before iterating
            let docElements = session.disclosedDocumentSets.first?.docElements ?? []
            for document in docElements {
                var fields: [RemotePresentationField] = []
                if document.isMsoMdoc {
                    for field in document.msoMdoc?.nameSpacedElements.first?.elements ?? [] {
                        var value = WalletInstance.shared.valueForElementIdentifier(with: document.docId, elementIdentifier: field.elementIdentifier, isMandatory: !field.isOptional, parser: {
                            Locale.current.localizedDateTime(
                                date: $0,
                                uiFormatter: "dd.MM.yyyy"
                            )
                        })
                        if field.elementIdentifier == "driving_privileges" {
                            guard let doc1 = WalletInstance.shared.fetchDocument(id: document.docId) else { return false}
                            guard let claim = doc1.docClaims.first(where: { $0.name == "driving_privileges" } ) else { return false}
                            var privileges: String = ""
                            
                            for children in claim.children ?? [] {
                                for child in children.children ?? [] {
                                    if child.name == "vehicle_category_code" {
                                        privileges += child.stringValue + ", "
                                    }
                                }
                            }
                            privileges = String(privileges.dropLast())
                            privileges = String(privileges.dropLast())
                            value = .string(privileges)
                        }
                        let fld = RemotePresentationField(id: field.elementIdentifier + document.docId, readableName: field.docClaim?.displayName ?? field.elementIdentifier, value: value.string?.replacingOccurrences(of: "PNOLV-", with: "") ?? "Not available", checked: field.isSelected, enabled: field.isSelected, elementIdentifier: field.elementIdentifier, isRequired: field.intentToRetain)
                        fields.append(fld)
                    }
                } else if document.isSdJwt {
                    for field in document.sdJwt?.sdJwtElements ?? [] {
                        AppLog.debug(field)
                        let elementIdentifier: String = field.elementPath.first ?? ""
                        let value = WalletInstance.shared.valueForElementIdentifier(with: document.docId, elementIdentifier: elementIdentifier, isMandatory: !field.isOptional, parser: {
                            Locale.current.localizedDateTime(
                                date: $0,
                                uiFormatter: "dd.MM.yyyy"
                            )
                        })
                        
                        let fld = RemotePresentationField(id: elementIdentifier + document.docId, readableName: field.docClaim?.displayName ?? elementIdentifier, value: value.string ?? "Not available", checked: field.isSelected, enabled: field.isSelected, elementIdentifier: elementIdentifier, isRequired: field.intentToRetain)
                        fields.append(fld)
                    }
                    
                    do {
                        var verName = verifierName
                        
                        let offset = verName.count % 4
                        if offset != 0 {
                            for _ in 1...offset {
                                verName += "="
                            }
                        }
                        
                        
                        guard let transactionData = verName.fromBase64()?.data(using: .utf8) else {
                            Crashlytics.crashlytics().log("Failed to decode verifier transaction data")
                            return false
                        }
                        let payment = try JSONDecoder().decode(Payment.self, from: transactionData)
                        presentationTransactionData = PresentationTransactionData(paymentId: payment.paymentId, amount: String(payment.instructedAmount), currency: payment.currency, creditor: payment.creditor, purpose: payment.purpose)
                        self.creditor = payment.creditor
                    } catch {
                        Crashlytics.crashlytics().record(error: error)
                        Crashlytics.crashlytics().log("Failed to decode payment transaction data")
                    }
                }
                
                
                if let doc = WalletInstance.shared.fetchDocument(id: document.docId) {
                    let meta = MetaHelper.shared.constructMeta(item: doc)
                    var masterDoc = RemotePresentationDocument(title: document.msoMdoc?.displayName ?? "", meta: meta, fields: fields)
                    docs.append(masterDoc)
                }
            }
            
            var fields: [String] = []
            for doc in docs {
                for field in doc.fields {
                    fields.append(field.elementIdentifier)
                }
            }
            
            let vendorKey = self.vendorKey(from: session.readerCertIssuer ?? "") + (docs.first?.meta.id ?? "")
            let quickFlowAvailable: Bool = RealmManager.shared.hasVendor(id: vendorKey)
            let savedSelectionApplied: Bool = RealmManager.shared.hasSameFields(vendorID: vendorKey, fields: fields)
            
            let respObj = RemotePresentationLocalResponse(vendorKey: vendorKey,
                                                          quickFlowAvailable: quickFlowAvailable,
                                                          savedSelectionApplied: savedSelectionApplied,
                                                          verifierName: verifierName,
                                                          verifierIsTrusted: verifierIsTrusted,
                                                          transactionData: presentationTransactionData,
                                                          documents: docs)
            
            self.tempRemotePresentation = respObj
            return true
        } else {
            Crashlytics.crashlytics().log("startRemotePresentation returned nil session or item")
            return false
        }
    }
    
    fileprivate func startRemotePresentation(result: String) async {
        if WalletInstance.shared.hasMainPid() {
            do {
                let res = try await self.createTempObj(result: result)
                if res {
                    self.navigate(pathName: "documentPresentation")
                } else {
                    self.navigate(pathName: "documentOfferManual", params: "status: 'presentationError'")
                }
            } catch {
                Crashlytics.crashlytics().record(error: error)
                // Deliberately does not include the request URI: it carries the verifier's
                // identity, nonce/state and the presentation definition (i.e. exactly which
                // claims are being requested). Sending that to a third-party crash service
                // would leak who the user transacted with and what was asked of them.
                Crashlytics.crashlytics().log("startRemotePresentation failed")

                self.navigate(pathName: "documentOfferManual", params: "status: 'presentationError'")
            }
        } else {
            self.navigate(pathName: "documentOfferManual", params: "status: 'missingPid'")
        }
    }
    

    func vendorKey(from verifier: String) -> String {
        guard let ver = verifier.data(using: .utf8) else {
            return ""
        }

        let hash = SHA256.hash(data: ver)
        return hash.map { String(format: "%02x", $0) }.joined()
    }
    
    fileprivate func getDocumentId() -> String {
        return tempRemotePresentation?.documents.first?.meta.id ?? ""
    }
    
    public func startDeeplinkPresentation(result: String) async throws -> Bool {
        do {
            let res = try await self.createTempObj(result: result)
            return res
        } catch {
            return false
        }
    }
    

    
    fileprivate func isPresentationAction(url: String) -> Bool {
        for value in OpenIDPresentationScheme.allCases {
            if url.starts(with: value.rawValue) {
                return true
            }
        }
        
        return false
    }
    
    fileprivate func isIssuanceAction(url: String) -> Bool {
        for value in CredentialOfferIssuanceScheme.allCases {
            if url.starts(with: value.rawValue) {
                return true
            }
        }
        
        return false
    }
}

extension IssuanceDestination: QRCodeActionDelegate {
    nonisolated func showQRInvalid() {
        Task { @MainActor in
            self.navigate(pathName: "qrInvalid")
        }
    }
    
    nonisolated func showError(_ error: QRCodeScannerPackage.ScanningError) {
        Crashlytics.crashlytics().log("QR scanner error: \(error)")
    }
    
    nonisolated func showQRCodeResult(result: String) {
        Task { @MainActor in
            if self.isPresentationAction(url: result) {
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                await self.startRemotePresentation(result: result)
            } else if self.isIssuanceAction(url: result) {
                self.issueFromQr(result: result)
            }
        }
    }
}

// PRESENTATION
extension IssuanceDestination {
    fileprivate func getRequestDocuments(localInit: LocalInitObject) async {
        if let resp = self.tempRemotePresentation {
            if let local = self.local {
                Task {
                    await self.inject(id: local.id, status: .SUCCESS, message: nil, data: resp)
                }
            }
        }
    }
    
    fileprivate func confirmRequest(localInit: LocalInitObject) async {
        if let fields = localInit.params?["fields"] as? [String: Bool], let remoteItem = self.tempRemotePresentation {
            var requestItems: RequestItems = [:]
            
            for item in remoteItem.documents {
                let docID = item.meta.id
                
                var typeSt: String = ""
                switch item.meta.documentDisplay.name {
                case "PID":
                    typeSt = DocumentTypeIdentifier.PID.rawValue
                case "mDL":
                    // without .mdl
                    typeSt = "org.iso.18013.5.1"
                case "Diploma":
                    typeSt = DocumentTypeIdentifier.Diploma.rawValue
                default:
                    typeSt = item.meta.documentDisplay.name
                }
                let type: NameSpace = typeSt
                var identifiers: [RequestItem] = []
                
                for field in item.fields {
                    if fields.contains(where: { $0.key == field.id && $0.value == true }) {
                        let requestItem = RequestItem(elementIdentifier: field.elementIdentifier)
                        identifiers.append(requestItem)
                    }
                }
                
                var secondLevelResp: [NameSpace: [RequestItem]] = [type: identifiers]
                requestItems[docID] = secondLevelResp
            }
            
            await WalletInstance.shared.generateResponse(items: requestItems, onCancel: {
                Task {
                    if let local = await self.local {
                        if let id = await self.tempRemotePresentation?.documents.first?.meta.id {
                            await RealmManager.shared.insertTransaction(id: id, type: .DOCUMENT_PRESENTED, status: .CANCELLED)
                        }
                        Crashlytics.crashlytics().log("Presentation cancelled by user")
                        await self.inject(id: local.id, status: .ERROR, message: nil, data: nil as String?)
                    }
                }
            }, onSuccess: { url in
                Task {
                    if await self.isPaymentUrl(url: url?.absoluteString ?? "") {
                        await self.navigate(pathName: "paymentDone", params: "step: 'loading'")
                        await self.setPaymentPingUrl(url: (url?.absoluteString ?? ""))
                        
                        DispatchQueue.main.async {
                            self.paymentTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.ping), userInfo: nil, repeats: true)
                        }
                    } else {
                        await RealmManager.shared.insertTransaction(id: remoteItem.documents.first?.meta.id ?? "", type: .DOCUMENT_PRESENTED, authority: self.tempRemotePresentation?.verifierName ?? "")
                        if let local = await self.local {
                            if let url = url {
                                await self.inject(id: local.id, status: .SUCCESS, message: nil, data: ["redirectUrl": url])
                            } else {
                                await self.inject(id: local.id, status: .SUCCESS, message: nil, data: nil as String?)
                            }
                            Task {
                                if let source = await DeepLinkCoordinator.shared.consumeAppSource(), source == "com.zzdats.dvs" {
                                    if let url = URL(string: "lietvaris://"),
                                        await UIApplication.shared.canOpenURL(url) {
                                        await UIApplication.shared.open(url, options: [:], completionHandler: nil)
                                    }
                                }
                            }
                            
                        }
                    }
                }
            })
        }
    }
    
    fileprivate func presentationCanceled(localInit: LocalInitObject) async {
        if let local = self.local {
            Task {
                if let id = self.tempRemotePresentation?.documents.first?.meta.id {
                    RealmManager.shared.insertTransaction(id: id, type: .DOCUMENT_PRESENTED, status: .CANCELLED)
                }
                await self.inject(id: local.id, status: .SUCCESS, message: nil, data: nil as String?)
            }
        }
    }
    
    @MainActor func setVendorPresentationPreference(localInit: LocalInitObject) async {
        if let vendor = localInit.params?["vendorKey"] as? String, let remember = localInit.params?["remember"] as? Bool {
            if remember, let tempRemotePresentation = self.tempRemotePresentation {
                var fields: [String] = []

                for doc in tempRemotePresentation.documents {
                    for field in doc.fields {
                        fields.append(field.elementIdentifier)
                    }
                }
                
                RealmManager.shared.insertVendor(id: vendor, fields: fields)
            } else {
                RealmManager.shared.deleteVendor(id: vendor)
            }
            
            if let local = self.local {
                Task {
                    await self.inject(id: local.id, status: .SUCCESS, message: nil, data: nil as String?)
                }
            }
        }
    }
    
    @MainActor func setPaymentPingUrl(url: String) {
        self.paymentCompleteUrl = url
        self.paymentPingUrl = url.replacingOccurrences(of: "/complete/", with: "/status/")
    }
    
    @objc fileprivate func ping() {
        AppLog.debug("PING PAYMENT STATUS")
        self.paymentTimerCounter += 1
        if self.paymentTimerCounter == 30 {
            self.removeTimer()
            self.emitPaymentStatus(status: "CANC")
            RealmManager.shared.insertTransaction(id: self.tempRemotePresentation?.documents.first?.meta.id ?? "", type: .DOCUMENT_PAYMENT, status: .ERROR, authority: self.creditor)
        } else {
            PaymentService.shared.pingPaymentStatus(requestUrl: self.paymentPingUrl, completionCallback: { status in
                self.emitPaymentStatus(status: status)
                if status == "ACSC" {
                    // transaction
                    self.removeTimer()
                    self.openPaymentRedirect()
                    RealmManager.shared.insertTransaction(id: self.tempRemotePresentation?.documents.first?.meta.id ?? "", type: .DOCUMENT_PAYMENT, status: .SUCCESS, authority: self.creditor)
                    // success
                } else if ["NAUT", "RJCT", "CANC"].contains(status) {
                    // transaction
                    self.removeTimer()
                    self.openPaymentRedirect()
                    RealmManager.shared.insertTransaction(id: self.tempRemotePresentation?.documents.first?.meta.id ?? "", type: .DOCUMENT_PAYMENT, status: .ERROR, authority: self.creditor)
                    
                    // failed
                }
                // else continue
            }, errorCallback: {
                self.removeTimer()
                self.emitPaymentStatus(status: "CANC")
                RealmManager.shared.insertTransaction(id: self.tempRemotePresentation?.documents.first?.meta.id ?? "", type: .DOCUMENT_PAYMENT, status: .ERROR, authority: self.creditor)
            })
        }
    }
    
    fileprivate func removeTimer() {
        self.paymentTimerCounter = 0
        self.paymentPingUrl = ""
        self.paymentTimer?.invalidate()
        self.paymentTimer = nil
    }
    
    fileprivate func isPaymentUrl(url: String) -> Bool {
        return url.lowercased().contains("a2pay")
    }
    
    fileprivate func openPaymentRedirect() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: {
            if let url = URL(string: self.paymentCompleteUrl) {
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:])
                }
            }
        })
    }
}

extension IssuanceDestination: EparakstsAuthFinishedDelegate {
    nonisolated func eparakstsAuthFinished(isSuccess: Bool) {
        if isSuccess {
            Task {
                if let local = await self.local {
                    await self.issue(localInit: local)
                }
            }
        } else {
            Task {
                Crashlytics.crashlytics().log("eParaksts authentication failed")
                await self.navigate(pathName: "documentOfferManual", params: "status: 'error'")
            }
        }
    }
}

@MainActor extension IssuanceDestination: IdentitiesResultDelegate {
    nonisolated func signResult(success: Bool) {
        Task {
            Crashlytics.crashlytics().log("Signing failed")
            await self.navigate(pathName: "documentOfferManual", params: "status: 'error'")
        }
    }
    
    nonisolated func identitiesResult(result: String) {
        Task {
            if !result.isEmpty {
                await WalletService.shared.getLVRTCIdentities(token: result, completionCallback: { res in
                    Task {
                        if let res = res {
                            if await self.isSignAction {
                                for sign in res.eSign {
                                    if await !RealmManager.shared.signatureExists(Sid: sign.Sid) {
                                        await RealmManager.shared.insertElectronicSignature(signature: sign, isSign: true)
                                        await RealmManager.shared.insertIssuanceMethod(id: sign.Sid, method: .eparaksts)
                                        await RealmManager.shared.insertTransaction(id: sign.Sid, type: .DOCUMENT_ISSUED)
                                        await RealmManager.shared.insertFavoriteDocument(documentID: sign.Sid)
                                    }
                                }
                                
                                if let local = await self.local {
                                    await self.inject(id: local.id, status: .SUCCESS, message: nil, data: nil as String?)
                                }
                                await self.navigate(pathName: "documentOfferManual", params: "status: 'success'")
                            } else {
                                if res.eSeal.count > 1 {
                                    Task { @MainActor in
                                        self.eSeals = res.eSeal
                                        if let local = self.local {
                                            await self.inject(id: local.id, status: .SUCCESS, message: nil, data: nil as String?)
                                        }
                                        self.navigate(pathName: "signatureSelect")
                                    }
                                } else if res.eSeal.count == 0 {
                                    if let local = await self.local {
                                        Crashlytics.crashlytics().log("No eSeal identities found")
                                        await self.navigate(pathName: "documentOfferManual", params: "status: 'error'", query: "error: 'sign_not_found_eseal_signing_identity'")
                                    }
                                } else {
                                    for sign in res.eSeal {
                                        if await !RealmManager.shared.signatureExists(Sid: sign.Sid) {
                                            await RealmManager.shared.insertElectronicSignature(signature: sign, isSign: false)
                                            await RealmManager.shared.insertIssuanceMethod(id: sign.Sid, method: .eparaksts)
                                            await RealmManager.shared.insertTransaction(id: sign.Sid, type: .DOCUMENT_ISSUED)
                                            await RealmManager.shared.insertFavoriteDocument(documentID: sign.Sid)
                                        }
                                    }
                                    
                                    if let local = await self.local {
                                        await self.inject(id: local.id, status: .SUCCESS, message: nil, data: nil as String?)
                                    }
                                    await self.navigate(pathName: "documentOfferManual", params: "status: 'success'")
                                }
                            }
                        }
                    }
                })
            } else {
                Crashlytics.crashlytics().log("LVRTC returned empty token/result")
                await self.navigate(pathName: "documentOfferManual", params: "status: 'error'")
            }
        }
    }
}

