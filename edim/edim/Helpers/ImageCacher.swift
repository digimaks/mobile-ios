// SPDX-License-Identifier: EUPL-1.2

//
//  ImageCacher.swift
//  edim
//
//  Created by Matīss Mamedovs on 01/08/2025.
//

import UIKit

@MainActor
final class ImageCacheManager {
    static let shared = ImageCacheManager()

    private let cache = NSCache<NSString, UIImage>()

    func image(for url: URL) async -> UIImage? {
        let key = url.absoluteString as NSString

        if let cached = cache.object(forKey: key) {
            return cached
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)

            guard let image = UIImage(data: data) else {
                return nil
            }

            cache.setObject(image, forKey: key)
            return image
        } catch {
            AppLog.error("Image download error:", error)
            return nil
        }
    }
}
