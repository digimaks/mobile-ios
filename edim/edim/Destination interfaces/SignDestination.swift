// SPDX-License-Identifier: EUPL-1.2

//
//  SignDestination.swift
//  edim
//
//  Created by Matīss Mamedovs on 19/03/2025.
//

import Foundation
import MobileCoreServices
import UIKit
import UniformTypeIdentifiers
import ZIPFoundation
import UtilitiesPackage

final class SignDestination: Destination, Sendable {
    
    public static let shared = SignDestination()
    
    fileprivate var requestId: String = ""
    fileprivate var isContainer: Bool = false
    fileprivate var fullName: String = ""
    fileprivate var data: Data?
    fileprivate var isSign: Bool = true
    fileprivate var extens: String = ""
    fileprivate var name: String = ""
    fileprivate var url: URL?
    fileprivate var Sid: String = ""
    
    var pickedFileURL: URL?
    
    @MainActor var needToCreateSessionID: Bool = true

    public override init() {
        super.init()
    }
    
    override func start() {
        Task {
            guard let localInit = await self.local else {
                return
            }
            
            switch localInit.funcName {
            case .pickFiles:
                UserDefaultsManager.shared.remove(key: DOWNLOAD_DESTINATION)
                await self.pickFiles()
            case .openFile:
                await self.openFile(localInit: localInit)
            case .getSigningMethods:
                await self.getSigningMethods()
            case .signDocument:
                await self.signDocument(localInit: localInit)
            case .downloadSignedDocument:
                await self.downloadSignedDocument()
            case .shareSignedDocument:
                await self.shareSignedDocument()
            case .getSharedFile:
                await self.getSharedFile(localInit: localInit)
            default:
                break
            }
        }
        
    }
}

extension SignDestination {
    fileprivate func pickFiles() {
        Task {
            if let local = self.local {
                needToCreateSessionID = true
                let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [ UTType.text, UTType.content, UTType.item, UTType.data])
                documentPicker.delegate = self
                self.parent?.present(documentPicker, animated: true)
            }
        }
    }
    
    fileprivate func openFile(localInit: LocalInitObject) {
        if let containerPath = localInit.params?["containerPath"] as? String {
            let filename = localInit.params?["fileName"] as? String
            let fileManager = FileManager()
            
            let sourceURL = URL(fileURLWithPath: containerPath)
            let destinationURL = FileSystem.documentsDirectory.appendingPathComponent(UUID().uuidString)
            do {
                if let filename = filename {
                    // file is zipped
                    try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
                    try fileManager.unzipItem(at: sourceURL, to: destinationURL)
                    
                    let fileURLs = try fileManager.contentsOfDirectory(at: destinationURL, includingPropertiesForKeys: nil)
                    let realUrl = destinationURL.appendingPathComponent(filename)
                    
                    let documentController = UIDocumentInteractionController(url: realUrl)
                    documentController.delegate = self
                    documentController.presentPreview(animated: true)
                    
                    AppLog.debug(fileURLs)
                } else {
                    let documentController = UIDocumentInteractionController(url: sourceURL)
                    documentController.delegate = self
                    documentController.presentPreview(animated: true)
                }
                
            } catch {
                AppLog.error("Extraction of ZIP archive failed with error:\(error)")
            }
            
            if let local = self.local {
                Task {
                    await self.inject(id: local.id, status: .SUCCESS, message: nil, data: nil as String?)
                }
            }
        }
    }
    
    fileprivate func getSigningMethods() {
        var responseArray: [GetDocumentsLocalResponse] = []
        
        var tempDocs: [DocumentUIModel] = []
        let signatures = RealmManager.shared.getSignatures()
        for sign in signatures ?? [] {
            let docUI = SignatureHelper.shared.constructAsDocument(item: sign)
            tempDocs.append(docUI)
        }
        
        for doc in tempDocs {
            let meta = MetaHelper.shared.constructMeta(signature: doc)
            
            let resp = GetDocumentsLocalResponse(meta: meta, documentDetails: SignatureHelper.shared.constructDocumentDetails(id: doc.id))
            
            responseArray.append(resp)
        }
        
        if let local = self.local {
            Task {
                await self.inject(id: local.id, status: .SUCCESS, message: nil, data: ["methods": responseArray])
            }
        }
    }
    
    fileprivate func signDocument(localInit: LocalInitObject) {
        let documentId = localInit.params?["documentId"] as? String ?? ""
        let filePath = localInit.params?["filePath"] as? String ?? ""
        let outputFormat: String = localInit.params?["outputFormat"] as? String ?? ""
        let isPDF: Bool = outputFormat == OutputFormats.pdf.name

        if let data = self.data {
            let isSign = RealmManager.shared.isSign(Sid: documentId)
            self.Sid = documentId
            self.isSign = isSign
            AppLog.debug("Moya_Logger: ID FOR SIGNING IS \(self.requestId)")
            WalletService.shared.signDocument(data: data, isESign: isSign, requestId: self.requestId, asice: !isPDF, fileName: self.fullName, redirectUrl: "digimaks://eseal-success", redirectError: "digimaks://eseal-error", esealSid: isSign ? nil : documentId, crossdevice: !EparakstsHelper.shared.canOpenLocallyEparaksts(), completionCallback: { signResponse in
                if signResponse == nil {
                    if let local = self.local {
                        Task {
                            await self.inject(id: local.id, status: .ERROR, message: nil, data: nil as String?)
                        }
                    }
                } else {
                    if let local = self.local {
                        Task {
                            await self.inject(id: local.id, status: .SUCCESS, message: nil, data: nil as String?)
                            
                            if let signResponse = signResponse {
                                let vc = LVRTCAuthViewController(redirectUrl: signResponse.redirectUrl)
                                vc.delegate = self
                                self.parent?.present(vc, animated: true)
                            }
                        }
                    }
                    
                }
            })
        }
    }
    
    fileprivate func downloadSignedDocument() {
        do  {
            let getUrl =  try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let url: String = UserDefaultsManager.shared.get(key: DOWNLOAD_DESTINATION) ?? ""
            if let getDestinationUrl = URL(string: url) {
                if FileManager().fileExists(atPath: getDestinationUrl.relativePath) {
                    let contents = try? Data(contentsOf: getDestinationUrl)
                    
                    let activityViewController = UIActivityViewController(activityItems: [getDestinationUrl], applicationActivities: nil)
                    self.parent?.present(activityViewController, animated: true)
                    
                    if let local = self.local {
                        Task {
                            await self.inject(id: local.id, status: .SUCCESS, message: nil, data: nil as String?)
                        }
                    }
                } else {
                    if let local = self.local {
                        Task {
                            await self.inject(id: local.id, status: .ERROR, message: nil, data: nil as String?)
                        }
                    }
                }
            } else if pickedFileURL != nil {
                guard let url = pickedFileURL else { return }
                let accessing = url.startAccessingSecurityScopedResource()
                
                let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                self.parent?.present(activityViewController, animated: true)
                
                if accessing {
                        url.stopAccessingSecurityScopedResource()
                    }
                
                if let local = self.local {
                    Task {
                        await self.inject(id: local.id, status: .SUCCESS, message: nil, data: nil as String?)
                    }
                }
            } else {
                if let local = self.local {
                    Task {
                        await self.inject(id: local.id, status: .ERROR, message: nil, data: nil as String?)
                    }
                }
            }
        } catch (let error) {
            if let local = self.local {
                Task {
                    await self.inject(id: local.id, status: .ERROR, message: nil, data: nil as String?)
                }
            }
        }
    }
    
    fileprivate func shareSignedDocument() {
        self.downloadSignedDocument()
    }
    
    fileprivate func getSharedFile(localInit: LocalInitObject) {
        AppLog.debug(localInit)
        let filePath = localInit.params?["filePath"] as? String ?? ""
        if let url = URL(string: filePath) {
            self.startValidation(url: url)
        } else {
            if let local = self.local {
                Task {
                    await self.inject(id: local.id, status: .ERROR, message: nil, data: nil as String?)
                }
            }
        }
    }
    
    fileprivate func startValidation(url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            do {
                let url: String = UserDefaultsManager.shared.get(key: DOWNLOAD_DESTINATION) ?? ""
                if !url.isEmpty {
                    if let getDestinationUrl = URL(string: url) {
                        if FileManager().fileExists(atPath: getDestinationUrl.relativePath) {
                            let contents = try? Data(contentsOf: getDestinationUrl)
                            self.data = contents
                            self.url = getDestinationUrl
                            
                            let fullName = getDestinationUrl.lastPathComponent
                            self.fullName = fullName
                            let fullNameArr = fullName.components(separatedBy: ".")
                            if fullNameArr.count > 1 {
                                let extens = fullNameArr.last ?? ""
                                self.extens = extens
                                
                                let name = fullName.replacingOccurrences(of: "." + extens, with: "")
                                self.name = name
                                
                                self.validate()
                            }
                        }
                    }
                } else {
                    let fileManager = FileManager.default
                    if #available(iOS 16.0, *) {
                        let deeplink = SessionData.shared.getDeeplinkFilePath() ?? ""
                        if let groupPath = URL(string: fileManager.containerURL(forSecurityApplicationGroupIdentifier: SuiteHelper.shared.getSuiteName())?.appendingPathComponent(deeplink).absoluteString.removingPercentEncoding ?? "") {
                            self.url = groupPath
                            let data = try Data(contentsOf: groupPath)
                            self.data = data
                            let fullName = groupPath.lastPathComponent
                            self.fullName = fullName
                            let fullNameArr = fullName.components(separatedBy: ".")
                            if fullNameArr.count > 1 {
                                let extens = fullNameArr.last ?? ""
                                self.extens = extens
                                
                                let name = fullName.replacingOccurrences(of: "." + extens, with: "")
                                self.name = name
                                
                                self.validate()
                            }
                        } else {
                            if let local = self.local {
                                Task {
                                    await self.inject(id: local.id, status: .SUCCESS, message: nil, data: nil as String?)
                                }
                            }
                        }
                    } else {}
                }
                
            } catch {
                if let local = self.local {
                    Task {
                        await self.inject(id: local.id, status: .SUCCESS, message: nil, data: nil as String?)
                    }
                }
            }
            return
        }
        
        do {
            self.url = url
            let data = try Data(contentsOf: url)
            self.data = data
            let fullName = url.lastPathComponent
            self.fullName = fullName
            let fullNameArr = fullName.components(separatedBy: ".")
            if fullNameArr.count > 1 {
                let extens = fullNameArr.last ?? ""
                self.extens = extens
                
                let name = fullName.replacingOccurrences(of: "." + extens, with: "")
                self.name = name
                
                self.validate()
                url.stopAccessingSecurityScopedResource()
            }
        } catch let error {
            if let local = self.local {
                Task {
                    await self.inject(id: local.id, status: .ERROR, message: nil, data: nil as String?)
                }
            }
        }
    }
}

extension SignDestination: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else {
            if let local = self.local {
                Task {
                    await self.inject(id: local.id, status: .ERROR, message: nil, data: nil as String?)
                }
            }
            return
        }
        self.pickedFileURL = url
        
        self.startValidation(url: url)
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        if let local = self.local {
            Task {
                await self.inject(id: local.id, status: .SUCCESS, message: nil, data: nil as String?)
            }
        }
    }
    
    private func validate() {
        var outputFormats: [String] = []
        
        switch extens {
        case "pdf":
            outputFormats = [".pdf", ".edoc"]
        case "edoc", "asice", "sce":
            outputFormats = [".edoc"]
            //outputFormats = ["." + extens]
        default:
            outputFormats = [".edoc"]
        }

        if let data = self.data, let url = url {
            if needToCreateSessionID {
                self.requestId = UUID().uuidString
                needToCreateSessionID = false
            }
            let isValid = SignatureHelper.shared.isValidFileSize(data: data)
            if isValid {
                if self.needToValidate() {
                    WalletService.shared.sendFileForValidation(data: data, name: name, extens: extens, completionCallback: { validationResponses in
                        if validationResponses == nil {
                            let pickFileObject = PickFileLocalObject(path: url.relativePath, name: self.fullName, size: data.count, type: self.extens, isContainer: false, isValid: isValid, allowedOutputFormats: outputFormats, containerInfo: nil)
                            
                            if let local = self.local {
                                Task {
                                    await self.inject(id: local.id, status: .SUCCESS, message: nil, data: ["files" : [pickFileObject]])
                                }
                            }
                        } else {
                            //self.requestId = validationResponses?.validationResponses.first?.sessionId ?? ""
                            let hasSignatures: Bool = (validationResponses?.validationResponses.first?.data.signatureExt.count ?? 0 > 0)
                            let isContainer = SignatureHelper.shared.isFileContainer(url: url) || hasSignatures
                            self.isContainer = isContainer
                            var containerInfo: ContainerInfoLocalObject?
                            if isContainer {
                                var files: [SignedFile] = []
                                for file in validationResponses?.validationResponses.first?.data.includedFiles ?? [] {
                                    if file.filename.contains(".") {
                                        let fl = SignedFile(name: file.filename)
                                        files.append(fl)
                                    }
                                }
                                
                                var signers: [Signer] = []
                                for signer in validationResponses?.validationResponses.first?.data.signatureExt ?? [] {
                                    let sgn = Signer(name: signer.signedBy, signedAt: signer.info.bestSignatureTime, type: "")
                                    signers.append(sgn)
                                }
                                
                                containerInfo = ContainerInfoLocalObject(signers: signers, files: files)
                            }
                            let pickFileObject = PickFileLocalObject(path: url.relativePath, name: self.fullName, size: data.count, type: self.extens, isContainer: isContainer, isValid: isValid, allowedOutputFormats: outputFormats, containerInfo: containerInfo)
                            
                            if let local = self.local {
                                Task {
                                    await self.inject(id: local.id, status: .SUCCESS, message: nil, data: ["files" : [pickFileObject]])
                                }
                            }
                        }
                    }, eparakstsErrorCallback: {
                        Task {
                            let vc = EparakstsViewController(isEparaksts: true)
                            vc.delegate = self
                            self.parent?.present(vc, animated: true)
                        }
                    })
                } else {
                    let pickFileObject = PickFileLocalObject(path: url.relativePath, name: self.fullName, size: data.count, type: self.extens, isContainer: false, isValid: isValid, allowedOutputFormats: outputFormats, containerInfo: nil)
                    
                    if let local = self.local {
                        Task {
                            await self.inject(id: local.id, status: .SUCCESS, message: nil, data: ["files" : [pickFileObject]])
                        }
                    }
                }
            } else {
                let pickFileObject = PickFileLocalObject(path: url.relativePath, name: self.fullName, size: data.count, type: self.extens, isContainer: false, isValid: isValid, allowedOutputFormats: outputFormats, containerInfo: nil)
                
                if let local = self.local {
                    Task {
                        await self.inject(id: local.id, status: .SUCCESS, message: nil, data: ["files" : [pickFileObject]])
                    }
                }
            }
        }
    }
    
    private func needToValidate() -> Bool {
        let allowedExts: [String] = ["asice", "edoc", "sce", "pdf"]
        return allowedExts.contains(self.extens)
    }
    
    public func setNeedToreateSessionIDTrue() {
        self.needToCreateSessionID = true

    }
}

extension SignDestination: EparakstsAuthFinishedDelegate {
    nonisolated func eparakstsAuthFinished(isSuccess: Bool) {
        if isSuccess {
            Task {
                await self.validate()
            }
        } else {
            Task {
                let type: String = await isSign ? "sign" : "seal"
                let params: String = "step: 'error' , type: '\(type)'"
                
                await RealmManager.shared.insertTransaction(id: self.Sid, type: .DOCUMENT_SIGNED, status: .ERROR)
                await self.navigate(pathName: "signDone", params: params)
            }
        }
    }
}

extension SignDestination: UIDocumentInteractionControllerDelegate {
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        if let parent = self.parent {
            return parent
        } else {
            return UIViewController()
        }
        
    }
}

@MainActor
extension SignDestination: IdentitiesResultDelegate {
    nonisolated func signResult(success: Bool) {
        Task {
            await self.navigate(pathName: "signDone", params: "step: 'loading'")
            let type: String = await isSign ? "sign" : "seal"
            await self.setNeedToreateSessionIDTrue()
            if success {
                await WalletService.shared.downloadSignedfile(requestId: self.requestId, filename: self.fullName, completionCallback: {
                    Task {
                        await WalletService.shared.deleteSession(isESign: self.isSign, requestId: self.requestId, completionCallback: { _ in
                            Task {
                                
                                let path = UserDefaultsManager.shared.get(key: DOWNLOAD_DESTINATION) ?? ""
                                await RealmManager.shared.insertTransaction(id: self.Sid, type: .DOCUMENT_SIGNED, status: .SUCCESS)
                                let params: String = "step: 'success', filePath: '\(path.escapedForJavaScriptSingleQuotedLiteral())' , type: '\(type)'"
                                await self.navigate(pathName: "signDone", params: params)
                            }
                        })
                    }
                })
            } else {
                await WalletService.shared.deleteSession(isESign: self.isSign, requestId: self.requestId, completionCallback: { _ in
                    Task {
                        await RealmManager.shared.insertTransaction(id: self.Sid, type: .DOCUMENT_SIGNED, status: .ERROR)
                        let params: String = "step: 'error' , type: '\(type)'"
                        AppLog.debug(params)
                        await self.navigate(pathName: "signDone", params: params)
                    }
                })
            }
        }
    }
    nonisolated func identitiesResult(result: String) {}
}
