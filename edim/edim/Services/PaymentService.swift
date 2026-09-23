// SPDX-License-Identifier: EUPL-1.2

//
//  PaymentService.swift
//  edim
//
//  Created by Matīss Mamedovs on 04/06/2025.
//

import Moya
import Foundation

final public class PaymentService: Sendable {
    public static let shared = PaymentService()
    
    @MainActor public func pingPaymentStatus(requestUrl: String, completionCallback: @escaping(String) -> (), errorCallback: @escaping() -> ()) {
        AppApiProvider.shared.provider.request(.pingPaymentStatus(requestUrl: requestUrl), completion: {  [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                self.parsePersonData(response: response, completionCallback: completionCallback, errorCallback: errorCallback)
            case .failure:
                errorCallback()
            }
        })
    }
    
    private func parsePersonData(response: Response, completionCallback: @escaping(String) -> (), errorCallback: @escaping() -> ()) {
        if let data = try? JSONDecoder().decode(PaymentStatusResponse.self, from: response.data) {
            completionCallback(data.paymentStatus)
        } else {
            errorCallback()
        }
    }
}
