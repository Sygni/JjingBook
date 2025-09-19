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
    @State private var editingBook: Book? = nil
    @State private var showEditSheet = false
    @State private var bookToDelete: Book? = nil        // ✅ 삭제 대상 보관

    var body: some View {
        NavigationView {
          GeometryReader { proxy in
            let fullW = proxy.size.width
            let bookW = min(fullW * 0.58, 340)        // 화면의 약 58%, 최대 340pt 정도
            let centerBase = (fullW - bookW) / 2      // 기본은 중앙 정렬

            //let list = Array(books)              // FetchedResults -> Array
              // ✅ nil 날짜를 항상 아래로 보내는 정렬 보정
              let listSorted: [Book] = Array(books).sorted { a, b in
                  let da = a.dateRead ?? .distantPast
                  let db = b.dateRead ?? .distantPast
                  if da != db { return da > db }                         // 최신이 위
                  return (a.title ?? "") < (b.title ?? "")               // 보조정렬
              }
              
            let toneFlags = alternatingToneFlags(for: listSorted)
              
            ScrollView {
              LazyVStack(spacing: 0) {
                ForEach(Array(listSorted.enumerated()), id: \.1.objectID) { idx, book in
                  // 각 책마다 시작 여백 결정 (중앙 기준 ±24pt)
                  let key = (book.title ?? "") + "|" + (book.author ?? "")
                  let jitter = startOffsetX(from: key, maxJitter: 24)
                  let start = centerBase + jitter
                    
                  // 🔹 홀수 런이면 살짝 어둡게 (원하면 0.95/1.05 등으로 바꿔도 됨)
                  let tone: CGFloat = toneFlags[idx] ? 0.90 : 1.0
                    
                  // 행 하나: [여백 spacer] [책등 고정폭] [오른쪽 남은 공간]
                  HStack(spacing: 0) {
                    Spacer().frame(width: max(0, start))
                      BookStackView(book: book, tone: tone)
                      .frame(width: bookW, alignment: .leading)
                      // ✅ 편집/삭제 진입
                      .contextMenu {
                          Button {
                              editingBook = book
                              showEditSheet = true
                          } label: {
                              Label("편집", systemImage: "pencil")
                          }
                          Button(role: .destructive) {
                              bookToDelete = book
                          } label: {
                              Label("삭제", systemImage: "trash")
                          }
                      }
                    Spacer() // 남은 공간 자동 흡수
                  }
                  .contentShape(Rectangle()) // (길게 눌러 메뉴 잘 뜨게 히트영역 확보)
                  /*.contextMenu {
                    Button(role: .destructive) { bookToDelete = book } label: {
                      Label("삭제", systemImage: "trash")
                    }
                  }*/
                    // ✅ 스와이프 액션(리스트가 아니라도 잘 동작)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            bookToDelete = book
                        } label: {
                            Label("삭제", systemImage: "trash")
                        }
                        Button {
                            editingBook = book
                            showEditSheet = true
                        } label: {
                            Label("편집", systemImage: "pencil")
                        }.tint(.blue)
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
          // ✅ 추가 시트(기존)
          .sheet(isPresented: $showingAddBook) {
            AddBookView(context: viewContext)
          }
        // ✅ 편집 시트 (EditBookView 사용)
            .sheet(isPresented: $showEditSheet) {
                if let bk = editingBook {
                    // BookSearchViewModel이 필요한 EditBookView를 위해 즉석 생성
                    EditBookView(
                        vm: BookSearchViewModel(context: viewContext),
                        book: bk
                    )
                }
            }
          // ✅ 삭제 확인 알럿
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
    
    // 런 인덱스 플래그 계산
    private func alternatingToneFlags(for books: [Book]) -> [Bool] {
        var flags: [Bool] = []
        var lastIsKo: Bool? = nil
        var runIndex = 0
        for b in books {
            if let last = lastIsKo, last == b.isKorean {
                runIndex += 1
            } else {
                runIndex = 0
                lastIsKo = b.isKorean
            }
            flags.append(runIndex % 2 == 1) // 홀수번째만 토글
        }
        return flags
    }
}

