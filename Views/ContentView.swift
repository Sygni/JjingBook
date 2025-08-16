import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Book.dateRead, ascending: true)],
        animation: .default)
    private var books: FetchedResults<Book>
    
    @State private var showingAddBook = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 2) { // 책들이 쌓인 느낌으로 간격 최소화
                    ForEach(books) { book in
                        BookStackView(book: book)
                            .onTapGesture {
                                // TODO: 책 상세 정보 표시
                                print("Tapped: \(book.title ?? "")")
                            }
                    }
                }
                .padding()
            }
            .navigationTitle("Reading Stack")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddBook = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddBook) {
                AddBookView()
            }
        }
    }
}
 
#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
