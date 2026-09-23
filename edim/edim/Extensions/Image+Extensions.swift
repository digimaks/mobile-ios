// SPDX-License-Identifier: EUPL-1.2

//
//  Image+Extensions.swift
//  edim
//
//  Created by Matīss Mamedovs on 11/06/2025.
//

import UIKit

extension UIImage {
    func toBase64() -> String? {
        guard let imageData = self.pngData() else { return nil }
        return imageData.base64EncodedString(options: .lineLength64Characters)
    }
}
