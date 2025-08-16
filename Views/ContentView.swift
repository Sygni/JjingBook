//
//  ContentView.swift
//  JjingBook
//
//  Created by Jeongah Seo on 8/16/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    // Core Data 목록
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Book.dateRead, ascending: false)],
        animation: .default
    )
    private var books: FetchedResults<Book>

    // ✅ 시트 표출 상태
    @State private var showingAddBook = false
    @State private var bookToDelete: Book?            // ✅ 삭제 대상 보관

    var body: some View {
        NavigationView {
          GeometryReader { proxy in
            let fullW = proxy.size.width
            let bookW = min(fullW * 0.58, 340)        // 화면의 약 58%, 최대 340pt 정도
            let centerBase = (fullW - bookW) / 2      // 기본은 중앙 정렬

            ScrollView {
              LazyVStack(spacing: 0) {
                ForEach(books) { book in
                  // 각 책마다 시작 여백 결정 (중앙 기준 ±24pt)
                  let key = (book.title ?? "") + "|" + (book.author ?? "")
                  let jitter = startOffsetX(from: key, maxJitter: 24)
                  let start = centerBase + jitter

                  // 행 하나: [여백 spacer] [책등 고정폭] [오른쪽 남은 공간]
                  HStack(spacing: 0) {
                    Spacer().frame(width: max(0, start))
                    BookStackView(book: book)
                      .frame(width: bookW, alignment: .leading)
                    Spacer() // 남은 공간 자동 흡수
                  }
                  .contentShape(Rectangle()) // (길게 눌러 메뉴 잘 뜨게 히트영역 확보)
                  .contextMenu {
                    Button(role: .destructive) { bookToDelete = book } label: {
                      Label("삭제", systemImage: "trash")
                    }
                  }
                }
              }
              // 화면이 비어 보일 때 바닥 정렬
              .frame(minHeight: proxy.size.height, alignment: .bottom)
            }
          }
          .navigationTitle("Reading Stack")
          .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
              Button { showingAddBook = true } label: { Image(systemName: "plus") }
            }
          }
          .sheet(isPresented: $showingAddBook) {
            AddBookView(context: viewContext)
          }
          .alert("이 책을 삭제할까요?", isPresented: .constant(bookToDelete != nil)) {
            Button("취소", role: .cancel) { bookToDelete = nil }
            Button("삭제", role: .destructive) {
              if let b = bookToDelete { delete(b) }
              bookToDelete = nil
            }
          } message: { Text(bookToDelete?.title ?? "") }
        }
    }

    private func delete(_ book: Book) {
        viewContext.delete(book)
        do { try viewContext.save() } catch { print("Delete error: \(error)") }
    }
}

