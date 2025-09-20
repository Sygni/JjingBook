//
//  BookSearchService.swift
//  JjingBook
//
//  Created by Jeongah Seo on 8/16/25.
//

import Foundation

struct SearchBook: Identifiable, Hashable {
    let id: String
    var title: String
    var authors: [String]
    var pageCount: Int?
    var languageCode: String?
    var coverURL: URL?
}

protocol BookSearchService {
    func search(query: String) async throws -> [SearchBook]
}
