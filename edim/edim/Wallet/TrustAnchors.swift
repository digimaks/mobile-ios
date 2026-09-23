// SPDX-License-Identifier: EUPL-1.2

//
//  TrustAnchors.swift
//  edim
//
//  Bundled root certificates used to build the wallet's static trust list.
//
//  Created by Matīss Mamedovs on 13/04/2026.

import Foundation

enum TrustAnchors {
    private static let productionAnchorNames = [
        "issuer_ca",
        "verifier_ca_prod",
        "pidissuerca02_eu",
        "reader_ca"
    ]
    
    private static let developmentOnlyAnchorNames = [
        "verifier_ca_dev",
        "eudi_pid_issuer_ut",
        "pidissuerca02_ut"
    ]
    
    static var activeAnchorNames: [String] {
        AppEnvironment.isProduction
            ? productionAnchorNames
            : productionAnchorNames + developmentOnlyAnchorNames
    }
    
    static func rootCertificates() -> [Data] {
        let anchors = activeAnchorNames.compactMap { name -> Data? in
            guard let data = Data(name: name, ext: "der") else {
                // The .der files are not committed (see TRUST_ANCHORS.md), so a
                // checkout without them would otherwise silently build a wallet
                // that trusts fewer issuers/verifiers than intended. Debug builds
                // trap; release builds cannot crash the wallet on launch, so the
                // shortfall is at least made observable.
                assertionFailure("Missing bundled trust anchor: \(name).der")
                AppLog.error("Missing bundled trust anchor: \(name).der")
                return nil
            }
            return data
        }
        
        if anchors.count != activeAnchorNames.count {
            AppLog.error(
                "Trust list incomplete: loaded \(anchors.count) of \(activeAnchorNames.count) anchors."
            )
        }
        
        return anchors
    }
}
