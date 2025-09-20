//
//  GoogleBooksClient.swift
//  JjingBook
//
//  Created by Jeongah Seo on 8/16/25.
//

import Foundation

// Google Books API response 최소 모델
private struct GBResponse: Decodable {
    let items: [GBItem]?
}
private struct GBItem: Decodable {
    let id: String
    let volumeInfo: GBVolume
}
private struct GBVolume: Decodable {
    let title: String?
    let authors: [String]?
    let pageCount: Int?
    let language: String?
    let imageLinks: GBImageLinks?
}
private struct GBImageLinks: Decodable {
    let thumbnail: String?
    let smallThumbnail: String?
}

struct GoogleBooksClient: BookSearchService {
    func search(query: String) async throws -> [SearchBook] {
        
        /*
        switch TextDetect.parseQuery(query) {
        case .isbn10or13(let isbn):
            // ISBN 단일 검색
            let r = try await fetch(qItems: [
                ("q", "isbn:\(isbn)"),
                ("maxResults","20"),
                ("printType","books"),
                ("key", Config.googleBooksKey)
            ])
            return r

        case .normal(let q, let isKorean):
            // 1) 제목 정밀 검색
            async let r1 = fetch(qItems: [
                ("q", #"intitle:"\#(q)""#),
                ("maxResults","20"),
                ("orderBy","relevance"),
                ("printType","books"),
                ("key", Config.googleBooksKey),
                // 한글이면 한국어 우선
                ] + (isKorean ? [("langRestrict","ko")] : [])
            )

            // 2) 보조 광역 검색
            async let r2 = fetch(qItems: [
                ("q", q),
                ("maxResults","20"),
                ("orderBy","relevance"),
                ("printType","books"),
                ("key", Config.googleBooksKey)
            ])

            var merged = try await Set((r1 + r2)) // SearchBook: Hashable
            // 스코어링 정렬
            let scored = merged.map { ($0, score(book: $0, rawQuery: q, isKorean: isKorean)) }
                .sorted { $0.1 > $1.1 }
                .map { $0.0 }
            return scored
         
        }
         */
        
        let key = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_BOOKS_KEY") as? String ?? ""
        let isISBN = query.trimmingCharacters(in: .whitespaces).hasPrefix("isbn:")
        
        // URL 파라미터 보강: key, printType, orderBy, country, maxResults
        var items: [(String, String)] = [
            ("q", query),                      // "isbn:978..." or "intitle:..."
            ("key", key),
            //("maxResults", "20"),
            ("printType", "books"),
            //("orderBy", "relevance"),
            ("country", "KR"),                  // 선택: 한국 우선
            ("projection", "full"),             // 더 풍부한 volumeInfo
            /*(
              "fields",              // 필요한 필드만 슬림하게
              "items(volumeInfo/title,volumeInfo/authors,volumeInfo/industryIdentifiers,volumeInfo/pageCount,volumeInfo/imageLinks,volumeInfo/language,volumeInfo/publishedDate,volumeInfo/publisher,volumeInfo/printType),totalItems"
            )*/
        ]

        // ISBN 검색이면 정렬/언어 제한 필요 없음, 결과 수도 소폭
        if isISBN {
            items.append(("maxResults", "5"))
        } else {
            items.append(contentsOf: [
                ("maxResults", "20"),
                ("orderBy", "relevance")
            ])
            // (선택) 쿼리 한글이면 한국어 우선
            if query.range(of: #"\p{Hangul}"#, options: .regularExpression) != nil {
                items.append(("langRestrict", "ko"))
            }
        }

        return try await fetch(qItems: items)   // ⬅️ 이미 GBResponse→SearchBook 매핑 포함
    }

    // MARK: - Private

    private func fetch(qItems: [(String,String)]) async throws -> [SearchBook] {
        var comps = URLComponents(string: "https://www.googleapis.com/books/v1/volumes")!
        comps.queryItems = qItems.map { URLQueryItem(name: $0.0, value: $0.1) }
        let url = comps.url!

        let res: GBResponse = try await HTTPClient.shared.get(url, as: GBResponse.self)
        guard let items = res.items else { return [] }

        return items.compactMap { item in
            let v = item.volumeInfo
            let thumb = v.imageLinks?.thumbnail ?? v.imageLinks?.smallThumbnail
            return SearchBook(
                id: item.id,
                title: v.title ?? "(No Title)",
                authors: v.authors ?? [],
                pageCount: v.pageCount,
                languageCode: v.language,
                coverURL: thumb.flatMap { URL(string: $0.replacingOccurrences(of: "http://", with: "https://")) }
            )
        }
    }

    // 간단 스코어: 제목 포함 + 언어일치 + 저자일치
    private func score(book: SearchBook, rawQuery: String, isKorean: Bool) -> Int {
        let q = rawQuery.lowercased()
        var s = 0
        if book.title.lowercased().contains(q) { s += 100 }
        if let lang = book.languageCode?.lowercased(), isKorean && lang == "ko" { s += 40 }
        if let firstAuthor = book.authors.first?.lowercased(), firstAuthor.contains(q) { s += 20 }
        if book.pageCount != nil { s += 3 }
        return s
    }
}
