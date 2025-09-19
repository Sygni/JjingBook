//
//  AddBookManualView.swift
//  JjingBook
//
//  Created by Jeongah Seo on 9/19/25.
//

import SwiftUI
import CoreData

struct AddBookManualView: View {
    @ObservedObject var vm: BookSearchViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var author: String = ""
    @State private var pageText: String = ""
    @State private var isKorean: Bool = true
    @State private var isbn: String = ""
    @State private var note: String = ""

    @State private var showAlert = false
    @State private var alertMsg = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("기본 정보") {
                    TextField("제목(필수)", text: $title)
                        .textInputAutocapitalization(.sentences)
                    TextField("저자", text: $author)
                    TextField("페이지 수(필수, 숫자)", text: $pageText)
                        .keyboardType(.numberPad)
                    Toggle("한국어 책", isOn: $isKorean)
                    TextField("ISBN(선택)", text: $isbn)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section("메모") {
                    TextField("메모(선택)", text: $note, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }
            }
            .navigationTitle("수동 등록")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") { save() }
                        .bold()
                }
            }
            .alert("저장 실패", isPresented: $showAlert) {
                Button("확인", role: .cancel) {}
            } message: {
                Text(alertMsg)
            }
        }
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            alertMsg = "제목을 입력해 주세요."
            showAlert = true
            return
        }
        guard let pages = Int(pageText), pages > 0 else {
            alertMsg = "페이지 수를 올바르게 입력해 주세요."
            showAlert = true
            return
        }

        do {
            // ⚠️ isbn, note는 아직 VM 메서드에 파라미터가 없으니 전달하지 않습니다.
            _ = try vm.addManualBook(
                title: trimmedTitle,
                author: author.trimmingCharacters(in: .whitespacesAndNewlines),
                pages: pages,
                isKorean: isKorean
                // dateRead: Date()  // 필요하면 명시 가능(기본값 Date())
            )
            dismiss()
        } catch {
            alertMsg = error.localizedDescription
            showAlert = true
        }
    }
}
