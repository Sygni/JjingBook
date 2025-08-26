//
//  Config.swift
//  JjingBook
//
//  Created by Jeongah Seo on 8/20/25.
//

import Foundation

enum Config {
    static var googleBooksKey: String {
        (Bundle.main.infoDictionary?["GOOGLE_BOOKS_KEY"] as? String) ?? ""
    }
}
