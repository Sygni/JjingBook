//
//  SearchBook+Merge.swift
//  JjingBook
//
//  Created by Jeongah Seo on 8/26/25.
//

import Foundation

extension Array where Element == SearchBook {
    /// 여러 후보(SearchBook)를 정책에 따라 하나로 병합
    func merged() -> SearchBook? {
        guard let first = self.first else { return nil }

        // 제목: 가장 길고(정보 풍부), 한글 제목 우선
        let title = self
            .map(\.title)
            .sorted {
                let aKo = $0.range(of: #"\p{Hangul}"#, options: .regularExpression) != nil
                let bKo = $1.range(of: #"\p{Hangul}"#, options: .regularExpression) != nil
                if aKo != bKo { return aKo } // 한글 우선
                return $0.count > $1.count   // 길이 우선
            }
            .first ?? first.title

        // 저자: 가장 많은 저자 목록
        let authors = self
            .map(\.authors)
            .sorted { $0.count > $1.count }
            .first ?? first.authors

        // 페이지 수: 최빈값(동수면 최대값)
        let pages: Int? = {
            let counts = Dictionary(grouping: self.compactMap(\.pageCount), by: { $0 })
                .mapValues(\.count)
            if let mode = counts.max(by: { $0.value < $1.value })?.key { return mode }
            return self.compactMap(\.pageCount).max()
        }()

        // 언어: ko 우선, 없으면 첫번째 non-nil
        let lang = self.compactMap(\.languageCode)
            .sorted { ($0?.lowercased() == "ko" ? 0 : 1) < ($1?.lowercased() == "ko" ? 0 : 1) }
            .first ?? first.languageCode

        // 표지: 해상도/길이 큰 URL 우선(간단 근사치)
        let cover = self.compactMap(\.coverURL)
            .sorted { ($0.absoluteString.count) > ($1.absoluteString.count) }
            .first ?? first.coverURL

        return SearchBook(
            id: first.id, // 하나로 통일(또는 "merge-\(…)" 규칙)
            title: title,
            authors: authors,
            pageCount: pages,
            languageCode: lang,
            coverURL: cover
        )
    }
}
