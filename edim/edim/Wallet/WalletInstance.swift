// SPDX-License-Identifier: EUPL-1.2

//
//  WalletInstance.swift
//  edim
//
//  Created by Matīss Mamedovs on 15/11/2024.
//


import Foundation
import EudiWalletKit
import MdocSecurity18013
import MdocDataTransfer18013
import MdocDataModel18013
import OpenID4VCI
import WalletStorage
import UIKit
import UtilitiesPackage
import EudiEtsi1196x2

@MainActor
final public class WalletInstance: Sendable {
    
    fileprivate var wallet: EudiWallet?
    fileprivate var remoteSession: PresentationSession?
    
    @MainActor public static let shared = WalletInstance()
    
    public func setUp() {
        
        let userAuthenticationRequired = WalletPropertyReader.shared.getAuthRequired()
        let uiCulture = UserDefaultsManager.shared.get(key: AppDestination.LANGUAGE_CODE) ?? "lv"
        
        let config = EudiWalletConfiguration(serviceName: "eudi",
                                             userAuthenticationRequired: userAuthenticationRequired,
                                             uiCulture: uiCulture
        )
        
        let certs = TrustAnchors.rootCertificates()

        let staticSource: TrustSource = .staticList(
            StaticListTrustSource(rootCertificates: certs)
        )

        let trustConfig = TrustConfiguration(
            trustSource: staticSource,
            fallbackTrustSource: staticSource,
            defaultPolicy: .enforce,
            docTypePolicies: [:],
            requireSignedMetadata: true,
            statusTrustPolicy: .warning,
            wrprcVpTrustPolicy: .warning,
            wrprcVciTrustPolicy: .warning,
            clockSkew: 60
        )
        
        guard let walletKit = try? EudiWallet(eudiWalletConfig:config,
                                              trustConfig: trustConfig,
                                              openID4VpConfig: .init(clientIdSchemes: [.x509SanDns, .x509Hash],
                                              validateRegistrationCertificate: false),
                                              openID4VciConfigurations: issuersConfig.mapValues { $0.config }) else {
            fatalError("Unable to Initialize WalletKit")
        }
        
        wallet = walletKit
        
    }
    
    public func setUiCulture(_ culture: String) {
        self.wallet?.eudiWalletConfig.uiCulture = culture
    }

    public func fetchDocuments() async -> [DocumentUIModel]? {
        guard let documents = self.wallet?.storage.docModels else {
            return nil
        }
        
        guard !documents.isEmpty else {
            return nil
        }

        var tempDocs = documents.compactMap {
            $0.transformToDocumentUi()
        }
        
        let signatures = RealmManager.shared.getSignatures()
        for sign in signatures ?? [] {
            let docUI = SignatureHelper.shared.constructAsDocument(item: sign)
            tempDocs.append(docUI)
        }
        return tempDocs
    }
    
    public func fetchDocument(id: String) -> (any DocClaimsDecodable)? {
        return wallet?.storage.getDocumentModel(id: id)
    }
    
    public func fetchForDetails(id: String) async -> (any DocClaimsDecodable)? {
        if let doc = await self.loadDocuments().first(where: { $0.id == id }) {
            let docClaim = StorageManager.toClaimsModel(doc: doc, uiCulture: self.wallet?.eudiWalletConfig.uiCulture)
            
            return docClaim
        } else {
            return wallet?.storage.getDocumentModel(id: id)
        }
    }
    
    public func refreshDocuments(uiCulture: String) async {
        try? await self.wallet?.storage.loadDocuments(status: .issued, uiCulture: uiCulture)
    }
    
    public func loadDocuments() async -> [WalletStorage.Document] {
        let docs = try? await wallet?.loadAllDocuments()
        return docs ?? []
    }
    
    public func deleteDocument(identifier: String, type: DocumentTypeIdentifier) async -> DocumentDetailsDeletionPartialState {
        
        let successState: DocumentDetailsDeletionPartialState
        
        do {
            var shouldDeleteAll: Bool {
                if type == .PID {
                    let documentPids = self.fetchIssuedDocuments(type: type)
                    let mainPid = fetchMainPidDocument()
                    
                    guard documentPids.count > 1 else {
                        return true
                    }
                    return mainPid?.id == identifier
                    
                } else {
                    return false
                }
            }
            
            if shouldDeleteAll {
                UserDefaultsManager.shared.set(value: false, key: OnboardingDestination.MAIN_PID_ISSUED)
                try await wallet?.deleteAllDocuments()
                RealmManager.shared.deleteSignatures()
                RealmManager.shared.deleteTransactions()
                RealmManager.shared.deleteAllIssuanceMethods()
                successState = .success(shouldReboot: true)
            } else {
                try await wallet?.deleteDocument(id: identifier, status: .issued)
                RealmManager.shared.deleteIssuanceMethod(id: identifier)
                successState = .success(shouldReboot: false)
            }
            
        } catch {
            return .failure(error)
        }
        
        return successState
    }
    
    public func deleteAllDocuments() async -> Bool {
        do {
            try await wallet?.deleteAllDocuments()
            RealmManager.shared.deleteAllIssuanceMethods()
            UserDefaultsManager.shared.set(value: false, key: OnboardingDestination.MAIN_PID_ISSUED)
            return true
        } catch {
            return false
        }
    }
    
    public func fetchIssuedDocuments(type: DocumentTypeIdentifier) -> [any DocClaimsDecodable] {
        return wallet?.storage.docModels.filter({ $0.docType ==  type.rawValue}) ?? []
    }
    
    public func fetchMainPidDocument() -> (any DocClaimsDecodable)? {
        return fetchIssuedDocuments(type: .PID).sorted { $0.createdAt > $1.createdAt }.last
    }
    
    public func hasMainPid() -> Bool {
        return self.fetchMainPidDocument() != nil
    }
    
    public func getScopedDocuments() async throws -> [ScopedDocument] {
        if let metadata = try await wallet?.getIssuerMetadata(issuerName: WalletPropertyReader.shared.getIssuerUrl()) {
            return metadata.credentialsSupported.compactMap { credential in
                switch credential.value {
                case .msoMdoc(let config):
                    return ScopedDocument(
                        name: config.credentialMetadata?.display.first?.name ?? "",
                        issuer: metadata.display.first?.name ?? "",
                        configId: credential.key.value,
                        isPid: DocumentTypeIdentifier(rawValue: config.docType) == .PID
                    )
                case .sdJwtVc(let config):
                    return ScopedDocument(
                        name: config.credentialMetadata?.display.first?.name ?? "",
                        issuer: metadata.display.first?.name ?? "",
                        configId: credential.key.value,
                        isPid: false
                    )
                default: return nil
                }
            }
        } else {
            return []
        }
    }
    
    public func qrcodeIssue(uri: String) async -> OfferedIssuanceModel? {
        do {
            if let model = try await wallet?.resolveOfferUrlDocTypes(offerUri: uri, authFlowRedirectionURI: nil) {
                let customizedDocTypes = model.docModels.map { docModel in
                    docModel.copy(
                        credentialOptions: CredentialOptions(credentialPolicy: .rotateUse, batchSize: 1),
                        keyOptions: KeyOptions(secureAreaName: "SecureEnclave")
                    )
                }
                return OfferedIssuanceModel(issuerName: model.issuerName, issuerLogoUrl: model.issuerLogoUrl, docModels: customizedDocTypes, txCodeSpec: model.txCodeSpec)
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }
    
    public func issueDocumentOffer(uri: String, models: [OfferedDocModel], txCode: String?) async -> DocumentIssuanceResponse {
        do {
            let doc = try await wallet?.issueDocumentsByOfferUrl(offerUri: uri, docTypes: models, txCodeValue: txCode)
            
            if let doc = doc?.documents.first {
                let id = doc.id
                
                RealmManager.shared.insertTransaction(id: id, type: .DOCUMENT_ISSUED)
                RealmManager.shared.insertFavoriteDocument(documentID: id)
                return (true, id)
            } else {
                return (false, nil)
            }
        } catch {
            #if DEBUG
            AppLog.error(error)
            #endif
            return (false, nil)
        }
    }
    
    public func startRemotePresentation(uri: String) async -> (PresentationSession?, UserRequestInfo?) {
        let data = uri.data(using: .utf8) ?? Data()
        let session = await wallet?.beginPresentation(flow: .openid4vp(qrCode: data))
        self.remoteSession = session
        let item = await session?.receiveRequest()
        return (session, item?.first)
    }
    
    public func generateResponse(items: RequestItems, onCancel: (@Sendable () -> Void)? = nil, onSuccess: (@Sendable (URL?) -> Void)? = nil) async  {
        try? await self.remoteSession?.sendResponse(userAccepted: true, itemsToSend: items, onCancel: onCancel, onSuccess: onSuccess)
        if let error = self.remoteSession?.uiError {
            onCancel?()
        }
    }
    
    public func valueForElementIdentifier(
        with documentId: String,
        elementIdentifier: String,
        isMandatory: Bool,
        parser: (String) -> String
    ) -> DocValue {
        
        guard let document = fetchDocument(id: documentId) else {
            return .unavailable("")
        }
        
        let claims = document.docClaims
            .parseDates(
                parser: {
                    Locale.current.localizedDateTime(
                        date: $0,
                        uiFormatter: "dd.MM.yyyy"
                    )
                }
            )
            .parseUserPseudonym()
        
        guard let element = claims.first(where: { $0.name == elementIdentifier }) else {
            return .unavailable("")
        }
        
        if let image = element.dataValue.image {
            if isMandatory {
                return .mandatory(.image(image))
            } else {
                return .image(image)
            }
        }
        
        var stringValue: String {
            if let nested = element.children {
                return element.flattenNested(nested: nested).stringValue
            } else {
                return element.stringValue
            }
        }
        
        if isMandatory {
            return .mandatory(.string(stringValue))
        } else {
            return .string(stringValue)
        }
    }
    
    public func addSignAndSealType() -> [ScopedDocument] {
        let doc1 = ScopedDocument(name: SignatureHelper.ESIGN_NAME,
                                  issuer: "",
                                  configId: SignatureHelper.ESIGN_TYPE,
                                  isPid: false)
        let doc2 = ScopedDocument(name: SignatureHelper.ESEAL_NAME,
                                  issuer: "",
                                  configId: SignatureHelper.ESEAL_TYPE,
                                  isPid: false)
        
        return [doc1, doc2]
    }
    
    let IBAN_NAME: String = "IBAN"
    let IBAN_TYPE: String = "eu.europa.ec.eudi.iban"
    
    public func addPaymentType() -> [ScopedDocument] {
        let doc = ScopedDocument(name: IBAN_NAME, issuer: "", configId: IBAN_TYPE, isPid: false)
        
        return [doc]
    }
    
    var issuersConfig: [String: VciConfig] {
        let openId4VciConfigurations: [VciConfig] = {
            return [
                .init(
                    config: .init(
                        credentialIssuerURL: WalletPropertyReader.shared.getIssuerUrl(),
                        clientId: ClientIDHelper().getApiClientID(), //WalletPropertyReader.shared.getClientID(),
                        keyAttestationsConfig: KeyAttestationConfiguration(walletAttestationsProvider: MyAttestationProvider()),
                        authFlowRedirectionURI: URL(string: WalletPropertyReader.shared.getRedirectURI())!,
                        cacheIssuerMetadata: true
                    ),
                    order: 1
                ),
                .init(
                  config: .init(
                    credentialIssuerURL: "https://issuer.eudiw.dev",
                    clientId: ClientIDHelper().getApiClientID(),
                    keyAttestationsConfig: KeyAttestationConfiguration(walletAttestationsProvider: MyAttestationProvider()),
                    authFlowRedirectionURI: URL(string: "eu.europa.ec.euidi://authorization")!,
                    requireDpop: true,
                    cacheIssuerMetadata: true
                  ),
                  order: 1
                )
            ]
        }()
        
        return openId4VciConfigurations.reduce(
            into: [String: VciConfig]()
        ) { dict, config in
            guard
                let issuer = config.config.credentialIssuerURL,
                let url = URL(string: issuer),
                let host = url.host
            else {
                return
            }
            dict[host] = config
        }
    }
    
    func isDocumentLowOnCredentials(document: (any DocClaimsDecodable)?) -> Bool {
        if let document, let documentRemainingCredentials = document.credentialsUsageCounts?.remaining {
            return document.credentialPolicy == CredentialPolicy.oneTimeUse && documentRemainingCredentials <= 1
        } else {
            return false
        }
    }
    
}

extension Data {
    init?(name: String, ext: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: ext),
              let data = try? Data(contentsOf: url) else {
            return nil
        }

        self = data
    }
}

public enum DocValue {
    case string(String)
    case unavailable(String)
    case mandatory(MandatoryValue)
    case image(UIImage)
    
    public var string: String? {
        switch self {
        case .string(let string):
            return string
        case .unavailable(let string):
            return string
        case .mandatory(let value):
            if case .string(let string) = value {
                return string
            }
            return nil
        default:
            return nil
        }
    }
    
    public var image: UIImage? {
        switch self {
        case .image(let image):
            return image
        case .mandatory(let value):
            if case .image(let image) = value {
                return image
            }
            return nil
        default:
            return nil
        }
    }
}

extension DocValue {
    public enum MandatoryValue {
        case string(String)
        case image(UIImage)
    }
}

public struct VciConfig: Sendable {
    public let config: OpenId4VciConfiguration
    public let order: Int
}

public typealias DocumentIssuanceResponse = (Bool, String?)
