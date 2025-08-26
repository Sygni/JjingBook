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

    init(context: NSManagedObjectContext) {
        _vm = StateObject(wrappedValue: BookSearchViewModel(context: context))
    }

    @State private var toast: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                TextField("책 제목/저자/ISBN 검색", text: $vm.query)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                if vm.isLoading { ProgressView().padding(.top, 6) }
                if let msg = vm.errorMessage {
                    Text(msg).foregroundStyle(.red).padding(.horizontal)
                }

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
        }
    }

    private func itemKey(_ s: SearchBook) -> String {
        "\(s.title.lowercased())|\((s.authors.first ?? "").lowercased())"
    }
}
