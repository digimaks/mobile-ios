// SPDX-License-Identifier: EUPL-1.2

//
//  Locale+Extensions.swift
//  edim
//
//  Created by Matīss Mamedovs on 25/11/2024.
//

import Foundation

import Foundation

public extension Locale {
    
    static let serviceDateFormatters = [
        "yyyy.MM.dd'T'HH:mm:ss.SSS",
        "yyyy.MM.dd'T'HH:mm:ss",
        "yyyy.MM.dd'T'HH:mm:ss.SSSZ",
        "yyyy.MM.dd'T'HH:mm:ssZ",
        "yyyy.MM.dd",
        "yyyy/MM/dd"
    ]
    
    private var userSelectedLocale: Locale {
        return Locale.current
    }
    
    func localizedDateTime(date: String, uiFormatter: String, formatters: [String] = serviceDateFormatters) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = uiFormatter
        dateFormatter.locale = userSelectedLocale
        
        return parseDate(date: date, uiFormatter: dateFormatter, formatters: formatters)
    }
    
    func localizedDateTime(date: String, formatters: [String] = serviceDateFormatters, dateStyle: DateFormatter.Style = .short, timeStyle: DateFormatter.Style = .none) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = dateStyle
        dateFormatter.timeStyle = timeStyle
        dateFormatter.locale = userSelectedLocale
        
        return parseDate(date: date, uiFormatter: dateFormatter, formatters: formatters)
    }
    
    private func parseDate(date: String, uiFormatter: DateFormatter, formatters: [String] = serviceDateFormatters) -> String {
        var current: Date?
        for formatter in formatters {
            let parseDateFormatter = DateFormatter()
            parseDateFormatter.dateFormat = formatter
            if let normalDate = parseDateFormatter.date(from: date) {
                current = normalDate
                break
            }
        }
        guard let parsedDate = current else {
            return date
        }
        return uiFormatter.string(from: parsedDate)
    }
    
    func parseDate(
        date: String,
        formatters: [String] = serviceDateFormatters
    ) -> Date? {
        for formatter in formatters {
            let parseDateFormatter = DateFormatter()
            parseDateFormatter.dateFormat = formatter
            if let normalDate = parseDateFormatter.date(from: date) {
                return normalDate
            }
        }
        return nil
    }
    
    
    func convertFromYearsAtStart(_ string: String) -> String? {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        inputFormatter.locale = userSelectedLocale

        guard let date = inputFormatter.date(from: string) else {
            return nil
        }

        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "dd.MM.yyyy."
        outputFormatter.locale = userSelectedLocale

        return outputFormatter.string(from: date)
    }

}
