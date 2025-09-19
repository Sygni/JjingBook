//
//  BookSearchViewModel.swift
//  JjingBook
//
//  Created by Jeongah Seo on 8/16/25.
//

import Foundation
import Combine
import CoreData
import UIKit

@MainActor
final class BookSearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var results: [SearchBook] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // ✅ 이미 추가된 결과의 id 저장 → 버튼 상태 변경용
    @Published var addedIDs: Set<String> = []

    private let service: BookSearchService
    private var cancellables = Set<AnyCancellable>()
    private let context: NSManagedObjectContext

    init(service: BookSearchService = GoogleBooksClient(),
         context: NSManagedObjectContext) {
        self.service = service
        self.context = context
        bind()
        preloadAddedIDs()
        
        print("🔑 GOOGLE_BOOKS_KEY =", Bundle.main.object(forInfoDictionaryKey: "GOOGLE_BOOKS_KEY") as? String ?? "<nil>")
    }

    private func bind() {
        $query
            .removeDuplicates()
            .debounce(for: .milliseconds(400), scheduler: DispatchQueue.main)
            .sink { [weak self] q in
                Task { await self?.performSearch(q) }
            }
            .store(in: &cancellables)
    }

    // 앱 시작 시 이미 저장된 책과 매칭되는 id 세팅(제목/저자 키로 추정)
    private func preloadAddedIDs() {
        let req = NSFetchRequest<Book>(entityName: "Book")
        if let saved = try? context.fetch(req) {
            let keys = Set(saved.map { Self.key(title: $0.title ?? "", author: $0.author ?? "") })
            // 검색 결과가 들어오기 전까지는 빈 세트지만, 중복 체크 때 사용
            self.addedIDs = keys
        }
    }

    @MainActor
    func performSearch(_ q: String) async {
        errorMessage = nil
        guard !q.trimmingCharacters(in: .whitespaces).isEmpty else {
            results = []; return
        }
        isLoading = true
        
        // 1) 쿼리 전처리
        let query: String = {
            // 숫자/ISBN만 쓰면 isbn 검색
            let digits = q.filter(\.isNumber)
            if digits.count == 13 || digits.count == 10 { return "isbn:\(digits)" }

            // "제목 / 저자" 형태 지원
            if q.contains("/") {
                let parts = q.split(separator: "/", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
                let title = parts.first ?? ""
                let author = parts.count > 1 ? parts[1] : ""
                if !author.isEmpty { return "intitle:\(title) inauthor:\(author)" }
            }

            // 기본은 제목 위주
            if !q.lowercased().hasPrefix("isbn:") {
                return "intitle:\(q)"
            }
            return q
        }()
        
        do {
            /*let r = try await service.search(query: q)
            results = r
            // 검색 결과 기준으로 “이미 저장됨” 표시 갱신
            let savedKeys = currentSavedKeys()
            addedIDs = Set(
                r.compactMap { b in
                    let k = Self.key(title: b.title, author: b.authors.first ?? "")
                    return savedKeys.contains(k) ? k : nil
                }
            )
             */
            // 2) 1차 요청
            let r1 = try await service.search(query: query)
            if !r1.isEmpty {
                results = r1
            } else if !query.hasPrefix("isbn:") {
                // 3) 2차 요청(백업): 일반 풀 텍스트 검색
                let r2 = try await service.search(query: q)
                results = r2
            } else {
                results = []
            }
        } catch {
            errorMessage = error.localizedDescription
            results = []
        }
        isLoading = false
    }

    // ✅ Core Data 저장
    func addToLibrary(_ s: SearchBook, dateRead: Date = Date()) {
        // 중복 검사(제목+첫 저자 기준 간단키)
        let k = Self.key(title: s.title, author: s.authors.first ?? "")
        if currentSavedKeys().contains(k) {
            addedIDs.insert(k)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            return
        }

        let book = Book(context: context)
        book.title = s.title
        book.author = s.authors.first ?? ""
        book.pages = Int32(s.pageCount ?? 0)
        book.dateRead = dateRead
        let lang = s.languageCode?.lowercased()
        book.isKorean = (lang == "ko") || s.title.contains { $0 >= "가" && $0 <= "힣" }

        do {
            try context.save()
            addedIDs.insert(k)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } catch {
            errorMessage = "Save failed: \(error.localizedDescription)"
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
    
    func addToLibrary(_ s: SearchBook,
                      overrideTitle: String?,
                      overrideAuthor: String?,
                      overridePages: Int?,
                      overrideIsKorean: Bool?,
                      dateRead: Date) {

        let finalTitle = (overrideTitle?.isEmpty == false ? overrideTitle! : s.title)
        let finalAuthor = (overrideAuthor?.isEmpty == false ? overrideAuthor! : (s.authors.first ?? ""))
        let finalPages = overridePages ?? s.pageCount ?? 0
        let finalIsKorean: Bool = overrideIsKorean ?? {
            let lang = s.languageCode?.lowercased()
            return (lang == "ko") || s.title.contains { $0 >= "가" && $0 <= "힣" }
        }()

        let key = Self.key(title: finalTitle, author: finalAuthor)
        if currentSavedKeys().contains(key) {
            addedIDs.insert(key)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            return
        }

        let book = Book(context: context)
        book.title = finalTitle
        book.author = finalAuthor
        book.pages = Int32(finalPages)
        book.isKorean = finalIsKorean
        book.dateRead = dateRead

        do {
            try context.save()
            addedIDs.insert(key)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } catch {
            errorMessage = "Save failed: \(error.localizedDescription)"
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
    
    // ISBN 하나로 여러 소스 조회 후 SearchBook 하나로 병합해서 반환
    func resolveByISBN(_ isbn: String) async -> SearchBook? {
        // Google Books
        async let g: [SearchBook] = (try? await service.search(query: "isbn:\(isbn)")) ?? []
        // Open Library (무료 보강)
        async let o: SearchBook? = OpenLibraryClient().fetchByISBN(isbn)

        var cands = await g
        if let oo = await o { cands.append(oo) }

        return cands.merged()   // ← 앞서 추가한 Array<SearchBook>.merged()
    }

    private func currentSavedKeys() -> Set<String> {
        let req = NSFetchRequest<Book>(entityName: "Book")
        guard let saved = try? context.fetch(req) else { return [] }
        return Set(saved.map { Self.key(title: $0.title ?? "", author: $0.author ?? "") })
    }

    private static func key(title: String, author: String) -> String {
        "\(title.lowercased().trimmingCharacters(in: .whitespaces))|\(author.lowercased())"
    }
    
}

// MARK: - Manual Add (검색 없이 직접 추가)
extension BookSearchViewModel {
    enum ManualAddError: Error, LocalizedError {
        case invalidTitle, invalidPages
        var errorDescription: String? {
            switch self {
            case .invalidTitle: return "제목을 입력해 주세요."
            case .invalidPages: return "페이지 수를 올바르게 입력해 주세요."
            }
        }
    }

    /// 검색 없이 수동 저장
    @discardableResult
    func addManualBook(
        title: String,
        author: String,
        pages: Int,
        isKorean: Bool,
        dateRead: Date = Date()
    ) throws {
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { throw ManualAddError.invalidTitle }
        let p = max(1, pages) // 0/음수 방지

        let key = Self.key(title: t, author: author)
        if currentSavedKeys().contains(key) {
            // 이미 있으면 상태/햅틱만 업데이트하고 종료
            addedIDs.insert(key)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            return
        }

        let book = Book(context: context)
        book.title = t
        book.author = author
        book.pages = Int32(p)
        book.isKorean = isKorean
        book.dateRead = dateRead

        do {
            try context.save()
            // 뷰 갱신 보장
            context.processPendingChanges()
            addedIDs.insert(key)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            throw error
        }
    }
}

// MARK: - Edit / Delete for Book
extension BookSearchViewModel {

    enum EditError: Error, LocalizedError {
        case invalidTitle, invalidPages
        var errorDescription: String? {
            switch self {
            case .invalidTitle: return "제목을 입력해 주세요."
            case .invalidPages: return "페이지 수를 올바르게 입력해 주세요."
            }
        }
    }

    /// 기존 Book 편집
    func update(
        book: Book,
        title: String,
        author: String,
        pages: Int,
        isKorean: Bool,
        dateRead: Date?
    ) throws {
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { throw EditError.invalidTitle }
        let p = max(1, pages) // 0/음수 방지

        book.title = t
        book.author = author
        book.pages = Int32(p)
        book.isKorean = isKorean
        book.dateRead = dateRead   // nil 허용 → “읽은 날짜 없음”

        do {
            try context.save()
            context.processPendingChanges()
            // addedIDs 키 갱신(제목/저자 바뀌면)
            let k = Self.key(title: t, author: author)
            addedIDs.insert(k)
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            throw error
        }
    }

    /// Book 삭제
    func delete(_ book: Book) throws {
        context.delete(book)
        do {
            try context.save()
            context.processPendingChanges()
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            throw error
        }
    }

    /// (선택) 기존에 dateRead가 nil인 항목들 하단 정렬용 보정
    /// nil → .distantPast 로 바꾸면, dateRead 내림차순 정렬에서 항상 맨 아래로 감
    func normalizeMissingDatesToDistantPast() throws {
        let req = NSFetchRequest<Book>(entityName: "Book")
        req.predicate = NSPredicate(format: "dateRead == nil")
        let items = try context.fetch(req)
        for b in items { b.dateRead = .distantPast }
        if !items.isEmpty {
            try context.save()
            context.processPendingChanges()
        }
    }
}
