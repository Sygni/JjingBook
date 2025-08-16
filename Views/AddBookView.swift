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
    @Environment(\.presentationMode) var presentationMode
    
    @State private var title = ""
    @State private var author = ""
    @State private var pages = ""
    @State private var isKorean = true
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Book Information")) {
                    TextField("Title", text: $title)
                    TextField("Author", text: $author)
                    TextField("Pages", text: $pages)
                        .keyboardType(.numberPad)
                    
                    Toggle("Korean Book", isOn: $isKorean)
                }
            }
            .navigationTitle("Add Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveBook()
                    }
                    .disabled(title.isEmpty || pages.isEmpty)
                }
            }
        }
    }
    
    private func saveBook() {
        guard let pagesInt = Int32(pages) else { return }
        
        withAnimation {
            let newBook = Book(context: viewContext)
            newBook.title = title
            newBook.author = author
            newBook.pages = pagesInt
            newBook.isKorean = isKorean
            newBook.dateRead = Date()

            do {
                try viewContext.save()
                presentationMode.wrappedValue.dismiss()
            } catch {
                let nsError = error as NSError
                print("Save error: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
