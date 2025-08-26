//
//  TextDetect.swift
//  JjingBook
//
//  Created by Jeongah Seo on 8/16/25.
//

import Foundation

enum QueryType {
    case isbn10or13(String)
    case normal(String, isKorean: Bool)
}

enum TextDetect {
    static func parseQuery(_ raw: String) -> QueryType {
        let q = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let digits = q.replacingOccurrences(of: "-", with: "")
        if digits.count == 10 || digits.count == 13, CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: digits)) {
            return .isbn10or13(digits)
        }
        let isKorean = q.contains { $0 >= "가" && $0 <= "힣" }
        return .normal(q, isKorean: isKorean)
    }
}
