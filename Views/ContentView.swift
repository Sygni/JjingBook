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

    // 시트 표출 상태
    @State private var showingAddBook = false
    @State private var editingBook: Book? = nil
    @State private var showEditSheet = false
    @State private var bookToDelete: Book? = nil        // 삭제 대상 보관

    init() {
        let ap = UINavigationBarAppearance()
        ap.configureWithTransparentBackground()  // 스크롤/고정 상태 모두 투명
        ap.backgroundColor = .clear              // 배경 제거
        ap.shadowColor = .clear                  // 경계선(헤어라인) 제거

        let navBar = UINavigationBar.appearance()
        navBar.standardAppearance = ap
        navBar.scrollEdgeAppearance = ap
        navBar.compactAppearance = ap
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // 배경
                //BookshelfBackground()             // 가로대 책장 스타일.. 별로임
                AppBackground(imageName: "StackBG")
                    .ignoresSafeArea()              // 배경은 네비 영역까지 꽉 채우기

                VStack(spacing: 0){
                    // 🔹 고정 헤더 (항상 위에)
                    TitleBar()
                        .padding(.top, 20)    // Dynamic Island 밑 여유
                        .padding(.bottom, 12)
                    
                    // 🔹 책 스크롤 영역
                    GeometryReader { proxy in
                        let fullW = proxy.size.width
                        let bookW = min(fullW * 0.58, 340)        // 화면의 약 58%, 최대 340pt 정도
                        let centerBase = (fullW - bookW) / 2      // 기본은 중앙 정렬
                        
                        // ✅ nil 날짜를 항상 아래로 보내는 정렬 보정
                        let listSorted: [Book] = Array(books).sorted { a, b in
                            let da = a.dateRead ?? .distantPast
                            let db = b.dateRead ?? .distantPast
                            if da != db { return da > db }        // 최신이 위
                            return (a.title ?? "") < (b.title ?? "")
                        }
                        
                        let toneFlags = alternatingToneFlags(for: listSorted)
                        
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(Array(listSorted.enumerated()), id: \.1.objectID) { idx, book in
                                    // 각 책마다 시작 여백 결정 (중앙 기준 ±24pt)
                                    let key = (book.title ?? "") + "|" + (book.author ?? "")
                                    let jitter = startOffsetX(from: key, maxJitter: 24)
                                    let start = centerBase + jitter
                                    
                                    // 🔹 홀수 런이면 살짝 어둡게
                                    let tone: CGFloat = toneFlags[idx] ? 0.90 : 1.0
                                    
                                    // 행 하나: [여백 spacer] [책등 고정폭] [오른쪽 남은 공간]
                                    HStack(spacing: 0) {
                                        Spacer().frame(width: max(0, start))
                                        BookStackView(book: book, tone: tone)
                                            .frame(width: bookW, alignment: .leading)
                                        // 편집/삭제 진입
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
                                    .contentShape(Rectangle()) // 길게 눌러 메뉴 잘 뜨게
                                    // 스와이프 액션
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
                                        }
                                        .tint(.blue)
                                    }
                                }
                            }
                            // ✅ 헤더만큼 상단 여백 / 화면이 비어 보일 때 바닥 정렬
                            .padding(.horizontal, 8)
                            .padding(.bottom, 48)       // 하단 책 잘리기 방지
                            .frame(minHeight: proxy.size.height, alignment: .bottom)
                        }
                        
                        /*
                        .ignoresSafeArea(edges: .horizontal) // 가로만 확장, 세로 safe area는 유지
                        // ⬇️⬇️ 상단에 '제목 영역'을 안전영역 인셋으로 삽입 (겹침 없음)
                        .safeAreaInset(edge: .top) {
                            VStack{
                                // ⬇️ 타이틀을 아래로 내리는 ‘위쪽 여백’
                                Color.clear.frame(height: 20)      // 원하는 만큼 조절: 12~28 권장
                                
                                TitleBar()
                                    .padding(.bottom, 12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(.clear)     // 필요 시 .ultraThinMaterial 등
                                // 아래 코드는 타이틀영역 불투명으로 만들어서 책 스택 스크롤 안 보이게 하려는 것.. 맘에 안 들어서 안 씀
                                //.background(.regularMaterial) // 또는 .ultraThinMaterial
                                //.overlay(Divider(), alignment: .bottom)
                                //.zIndex(1)
                            }
                        }
                         */
                    }
                }
            }
            
            .navigationTitle("")        // 기본 타이틀은 비워서 중복 제거 + 대타이틀(스크롤 시 못생김) 비활성화
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAddBook = true } label: { Image(systemName: "plus") }
                }
            }
            // ✅ 추가 시트(기존)
            .sheet(isPresented: $showingAddBook) {
                AddBookView(context: viewContext)
            }
            // ✅ 편집 시트
            .sheet(isPresented: $showEditSheet) {
                if let bk = editingBook {
                    EditBookView(
                        // MultiSource 쓰는 중이면 아래 한 줄만 바꿔도 됨
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

struct TitleBar: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "books.vertical.fill")
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, Color.black.opacity(0.25))
                .padding(6)
                .background(Circle().fill(Palette.titleIcon))
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)

            Text("Books I've Read")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .kerning(0.5)
                .foregroundStyle(Palette.titleFont)     // (Color(hex: "#1B1C1E"))
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        //.padding(.bottom, 12)
    }
}
