//
//  AddBookView.swift
//  JjingBook
//
//  Created by Jeongah Seo on 8/16/25.
//

import SwiftUI
import CoreData

struct AddBookView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var vm: BookSearchViewModel
    @State private var showScanner = false
    @State private var selectedBook: SearchBook?
    @State private var navPath: [SearchBook] = []
    @State private var showManualSheet = false

    let openLib = OpenLibraryClient()
    
    init(context: NSManagedObjectContext) {
        _vm = StateObject(wrappedValue: BookSearchViewModel(context: context))
    }

    @State private var toast: String?

    var body: some View {
        NavigationStack(path: $navPath) {
            VStack(spacing: 12) {
                /*TextField("책 제목/저자/ISBN 검색", text: $vm.query)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                if vm.isLoading { ProgressView().padding(.top, 6) }
                if let msg = vm.errorMessage {
                    Text(msg).foregroundStyle(.red).padding(.horizontal)
                }*/
                
                HStack {
                    TextField("책 제목/저자/ISBN 검색", text: $vm.query)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    if vm.isLoading { ProgressView().padding(.top, 6) }
                    if let msg = vm.errorMessage {
                        Text(msg).foregroundStyle(.red).padding(.horizontal)
                    }

                    // 바코드 버튼 추가
                    Button(action: { showScanner = true }) {
                        Image(systemName: "barcode.viewfinder")
                            .imageScale(.large)
                    }
                }
                .padding(.horizontal)

                List(vm.results) { item in
                    NavigationLink {
                        ConfirmBookView(vm: vm, candidate: item)
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            AsyncImage(url: item.coverURL) { phase in
                                switch phase {
                                case .empty:
                                    Color.gray.opacity(0.2)
                                case .success(let img):
                                    img.resizable().scaledToFill()
                                case .failure:
                                    Color.gray.opacity(0.2)
                                @unknown default:
                                    Color.gray.opacity(0.2)
                                }
                            }
                            .frame(width: 44, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: 6))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title).font(.headline).lineLimit(2)
                                if !item.authors.isEmpty {
                                    Text(item.authors.joined(separator: ", "))
                                        .font(.subheadline).foregroundStyle(.secondary)
                                }
                                HStack(spacing: 8) {
                                    if let p = item.pageCount { Text("\(p) pages") }
                                    if let lang = item.languageCode?.uppercased() {
                                        Text(lang).font(.caption)
                                          .padding(.horizontal, 6).padding(.vertical, 2)
                                          .background(.thinMaterial)
                                          .clipShape(RoundedRectangle(cornerRadius: 4))
                                    }
                                }.foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.plain)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showManualSheet = true
                        } label: {
                            Label("수동 등록", systemImage: "plus.app")
                        }
                    }
                }
                .sheet(isPresented: $showManualSheet) {
                    AddBookManualView(vm: vm)
                }
            }
            .overlay(alignment: .bottom) {
                if let t = toast {
                    Text(t)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.bottom, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("책 검색")
            // ✅ SearchBook으로 목적지 등록
            .navigationDestination(for: SearchBook.self) { b in
                ConfirmBookView(vm: vm, candidate: b)
            }
        }
       
        // ✅ 스캔 후 검색 → 첫 결과를 선택
        /*.sheet(isPresented: $showScanner) {
            BarcodeScannerView { code in
                showScanner = false
                Task { @MainActor in
                    if let isbn = normalizeISBN(from: code) {
                        await vm.performSearch("isbn:\(isbn)")
                        if let first = vm.results.first {
                            navPath.append(first)
                        } else {
                            toast = "해당 ISBN으로 책을 찾지 못했어요"
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { toast = nil }
                        }
                    } else {
                        toast = "이 바코드는 책이 아니거나 인식이 불완전해요"
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { toast = nil }
                    }
                }
            }
        }*/
        .sheet(isPresented: $showScanner) {
            BarcodeScannerView { code in
                showScanner = false
                Task { @MainActor in
                    if let isbn = normalizeISBN(from: code) {
                        if let merged = await vm.resolveByISBN(isbn) {
                            navPath.append(merged)           // 바로 ConfirmBookView로
                        } else {
                            // 최후 fallback: 기존 검색
                            await vm.performSearch("isbn:\(isbn)")
                            if let first = vm.results.first {
                                navPath.append(first)
                            } else {
                                toast = "검색 결과가 없어요"
                                DispatchQueue.main.asyncAfter(deadline: .now()+1.5) { toast = nil }
                            }
                        }
                    } else {
                        toast = "이 바코드는 책이 아니거나 인식이 불완전해요"
                        DispatchQueue.main.asyncAfter(deadline: .now()+1.5) { toast = nil }
                    }
                }
            }
        }
    }
    
    private func itemKey(_ s: SearchBook) -> String {
        "\(s.title.lowercased())|\((s.authors.first ?? "").lowercased())"
    }
}
