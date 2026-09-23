// SPDX-License-Identifier: EUPL-1.2

//
//  ShareViewController.swift
//  SigningFileExtension
//
//  Created by Matīss Mamedovs on 01/04/2025.
//

import UIKit
import Social
import CoreServices
import UniformTypeIdentifiers

class ShareViewController: UIViewController {
    private let typeURL = String(kUTTypeURL)
    
    private let urlDefaultName = "ShareCommonExtension"
    private let groupName = "group.lv.zzdats.edim.share1"
    private let appURL = "NobidShareExtension.lv://"
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let itemProvider = extensionItem.attachments?.first else {
            self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            return
        }
        
        if itemProvider.hasItemConformingToTypeIdentifier(typeURL) {
            handleIncomingURL(itemProvider: itemProvider)
        } else {
            AppLog.error("Error: No url or text found")
            self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        }
    }
    
    @objc func openURL(_ url: URL) -> Bool {
        var responder: UIResponder? = self
            while responder != nil {
                if let application = responder as? UIApplication {
                    if #available(iOS 18.0, *) {
                        application.open(url, options: [:], completionHandler: nil)
                        return true
                    } else {
                        return application.perform(#selector(openURL(_:)), with: url) != nil
                    }
                }
                responder = responder?.next
            }
            return false
    }
    
    private func handleIncomingURL(itemProvider: NSItemProvider) {
        itemProvider.loadItem(forTypeIdentifier: typeURL, options: nil) { (item, error) in
            if let error = error { AppLog.error("URL-Error: \(error.localizedDescription)") }
                        
            if let url = item as? NSURL, let urlString = url.absoluteString {
                let success = url.startAccessingSecurityScopedResource()
                
                let fullName = url.lastPathComponent ?? ""
                let savedUrl = fullName
                
                let fileManager = FileManager.default
                if let groupPath = fileManager.containerURL(forSecurityApplicationGroupIdentifier: self.groupName)?.appendingPathComponent(fullName) {
                    if success {
                        do {
                            if fileManager.fileExists(atPath: groupPath.path()) {
                                try fileManager.removeItem(at: groupPath)
                            }
                            let data = try Data(contentsOf: url as URL)
                            try data.write(to: groupPath)
                            AppLog.debug("EDIM-EUDIW path: \(groupPath)")
                            AppLog.debug("EDIM-EUDIW path path: \(groupPath.path())")
                            url.stopAccessingSecurityScopedResource()
                        } catch {
                            url.stopAccessingSecurityScopedResource()
                            AppLog.error(error)
                        }
                    }
                    self.saveURLString(savedUrl)
                }
            }
            
            self.openMainApp()
        }
    }
        
    private func saveURLString(_ urlString: String) {
        UserDefaults(suiteName: self.groupName)?.set(urlString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed), forKey: self.urlDefaultName)
    }
    
    private func openMainApp() {
        self.extensionContext?.completeRequest(returningItems: nil, completionHandler: { _ in
            guard let url = URL(string: self.appURL) else { return }
            _ = self.openURL(url)
        })
    }
}
