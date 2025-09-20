//
//  MultiSourceSearchService.swift
//  JjingBook
//
//  Created by Jeongah Seo on 9/20/25.
//

import Foundation

/// 메인: 알라딘, 보조: 구글
struct MultiSourceSearchService: BookSearchService {
    let aladin = AladinClient()
    let google = GoogleBooksClient()

    func search(query: String) async throws -> [SearchBook] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let digits  = trimmed.filter(\.isNumber)
        let isISBN  = digits.count == 13 || digits.count == 10 || trimmed.lowercased().hasPrefix("isbn:")

        if isISBN {
            // ISBN이면 알라딘 우선, 구글로 보강
            let isbn13: String = {
                if trimmed.lowercased().hasPrefix("isbn:") { return digits }
                if digits.count == 13 { return digits }
                return digits
            }()

            async let a: SearchBook?  = try? await aladin.lookup(isbn13: isbn13)
            async let g: [SearchBook] = (try? await google.search(query: "isbn:\(isbn13)")) ?? []

            if let hit = await a {
                return merge(primary: [hit], others: await g)
            } else {
                return await g
            }
        } else {
            // 제목 검색: 알라딘 우선, 구글 보강
            async let a: [SearchBook] = (try? await aladin.search(title: trimmed, max: 20)) ?? []
            async let g: [SearchBook] = (try? await google.search(query: "intitle:\(trimmed)")) ?? []
            return merge(primary: await a, others: await g)
        }
    }

    // 제목+첫 저자로 중복제거, 페이지수/언어만 보강 (커버 병합 제거)
    private func merge(primary: [SearchBook], others: [SearchBook]) -> [SearchBook] {
        func key(_ b: SearchBook) -> String {
            "\(b.title.lowercased())|\(b.authors.first?.lowercased() ?? "")"
        }
        var dict: [String: SearchBook] = [:]
        for b in primary { dict[key(b)] = b }

        for o in others {
            let k = key(o)
            if var base = dict[k] {
                // 페이지 수: 기본값이 없으면 보강, 있으면 더 큰 값 우선(보수적)
                if (base.pageCount ?? 0) <= 0, let gp = o.pageCount, gp > 0 {
                    base.pageCount = gp
                } else if let gp = o.pageCount, let bp = base.pageCount, gp > bp {
                    base.pageCount = gp
                }
                // 언어코드 보강
                if base.languageCode == nil, let lang = o.languageCode {
                    base.languageCode = lang
                }
                dict[k] = base
            } else {
                dict[k] = o
            }
        }
        return Array(dict.values)
    }
}
