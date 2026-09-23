// SPDX-License-Identifier: EUPL-1.2

//
//  NameValue+Extensions.swift
//  edim
//
//  Created by Matīss Mamedovs on 27/01/2025.
//

import Foundation
import EudiWalletKit
import MdocSecurity18013
import MdocDataTransfer18013
import MdocDataModel18013

extension RangeReplaceableCollection where Element == DocClaim {

  public func parseDates(parser: (String) -> String) -> [DocClaim] {
    self.map {
      return switch $0.dataValue {
      case .date:
        DocClaim(
          name: $0.name,
          displayName: $0.displayName,
          dataValue: $0.dataValue,
          stringValue: parser($0.stringValue),
          isOptional: $0.isOptional,
          order: $0.order,
          namespace: $0.namespace,
          children: $0.children
        )
      default: $0
      }
    }
  }

  public func parseUserPseudonym() -> [DocClaim] {
    self.map {
      if $0.name == DocumentJsonKeys.USER_PSEUDONYM {
        return DocClaim(
          name: $0.name,
          displayName: $0.displayName,
          dataValue: $0.dataValue,
          stringValue: $0.dataValue.base64.orEmpty,
          isOptional: $0.isOptional,
          order: $0.order,
          namespace: $0.namespace,
          children: $0.children
        )
      } else {
        return $0
      }
    }
  }
}

public extension DocClaim {
  func flattenNested(nested: [DocClaim]) -> DocClaim {
    let flat = nested
      .parseDates(
        parser: {
          Locale.current.localizedDateTime(
            date: $0,
            uiFormatter: "dd MMM yyyy"
          )
        }
      )
      .parseUserPseudonym()
      .reduce(into: "") { partialResult, docClaim in
        if let nestedChildren = docClaim.children {
          let deepNested = flattenNested(nested: nestedChildren.sorted(by: {$0.order < $1.order}))
          partialResult += "\(deepNested.stringValue)\n"
        } else {
          partialResult += "\(docClaim.displayName.ifNilOrEmpty { docClaim.name }): \(docClaim.stringValue)\n"
        }
      }
      .dropLast()

    return DocClaim(
      name: self.name,
      displayName: self.displayName,
      dataValue: self.dataValue,
      stringValue: String(flat),
      isOptional: self.isOptional,
      order: self.order,
      namespace: self.namespace,
      children: nil
    )
  }
}
