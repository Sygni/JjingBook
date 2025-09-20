//
//  AladinClient.swift
//  JjingBook
//
//  Created by Jeongah Seo on 9/20/25.
//

import Foundation

struct AladinClient {
    private let base = "https://www.aladin.co.kr/ttb/api"

    // ISBN 단건 조회
    func lookup(isbn13: String) async throws -> SearchBook? {
        let key = Bundle.main.object(forInfoDictionaryKey: "ALADIN_TTB_KEY") as? String ?? ""
        var comp = URLComponents(string: "\(base)/ItemLookUp.aspx")!
        comp.queryItems = [
            .init(name: "ttbkey", value: key),
            .init(name: "itemIdType", value: "ISBN13"),
            .init(name: "ItemId", value: isbn13),
            .init(name: "output", value: "js"),
            .init(name: "Version", value: "20131101")
        ]
        let (data, _) = try await URLSession.shared.data(from: comp.url!)
        let decoded = try JSONDecoder().decode(AladinLookupResponse.self, from: data)
        guard let it = decoded.item.first else { return nil }
        return it.toSearchBook()
    }

    // 제목 검색
    func search(title: String, max: Int = 10) async throws -> [SearchBook] {
        let key = Bundle.main.object(forInfoDictionaryKey: "ALADIN_TTB_KEY") as? String ?? ""
        var comp = URLComponents(string: "\(base)/ItemSearch.aspx")!
        comp.queryItems = [
            .init(name: "ttbkey", value: key),
            .init(name: "Query", value: title),
            .init(name: "QueryType", value: "Title"),
            .init(name: "SearchTarget", value: "Book"),
            .init(name: "MaxResults", value: "\(max)"),
            .init(name: "output", value: "js"),
            .init(name: "Version", value: "20131101")
        ]
        let (data, _) = try await URLSession.shared.data(from: comp.url!)
        let decoded = try JSONDecoder().decode(AladinSearchResponse.self, from: data)
        return decoded.item.map { $0.toSearchBook() }
    }

    // MARK: - DTOs
    struct AladinSearchResponse: Decodable { let item: [AladinItem] }
    struct AladinLookupResponse: Decodable { let item: [AladinItem] }

    struct AladinItem: Decodable {
        let title: String?
        let author: String?
        let publisher: String?
        let isbn13: String?
        let itemPage: Int?
        let subInfo: SubInfo?

        struct SubInfo: Decodable { let itemPage: Int? }

        func toSearchBook() -> SearchBook {
            let pages = itemPage ?? subInfo?.itemPage
            return SearchBook(
                id: isbn13 ?? UUID().uuidString,
                title: title ?? "",
                authors: (author?.isEmpty == false) ? [author!] : [],
                pageCount: pages,
                languageCode: nil
            )
        }
    }
}
