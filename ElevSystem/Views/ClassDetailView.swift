import SwiftUI
import SwiftData

struct ClassDetailView: View {
    @Bindable var schoolClass: SchoolClass
    @Environment(\.modelContext) private var context
    @State private var showImporter = false
    @State private var csv: String?
    @State private var first = ""
    @State private var last = ""

    var body: some View {
        List {
            Section {
                ForEach(schoolClass.sortedStudents) { s in
                    NavigationLink { StudentDetailView(student: s, course: nil) } label: {
                        Text("\(s.lastName), \(s.firstName)")
                    }
                    .contextMenu { Button("Ta bort elev", role: .destructive) { context.delete(s) } }
                }
            } header: { Text("\(schoolClass.students?.count ?? 0) elever") }
            Section("Lägg till elev") {
                HStack {
                    TextField("Förnamn", text: $first)
                    TextField("Efternamn", text: $last)
                    Button("Lägg till") {
                        context.insert(Student(firstName: first, lastName: last, schoolClass: schoolClass))
                        first = ""; last = ""
                    }.disabled(first.isEmpty && last.isEmpty)
                }
            }
        }
        .navigationTitle(schoolClass.name)
        .toolbar {
            Button { showImporter = true } label: { Label("Importera CSV", systemImage: "square.and.arrow.down") }
        }
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.commaSeparatedText, .plainText, .text]) { r in
            guard case .success(let url) = r else { return }
            let access = url.startAccessingSecurityScopedResource()
            defer { if access { url.stopAccessingSecurityScopedResource() } }
            if let d = try? Data(contentsOf: url) { csv = CSVImport.decode(d) }
        }
        .sheet(isPresented: Binding(get: { csv != nil }, set: { if !$0 { csv = nil } })) {
            if let csv { ImportClassView(csv: csv, targetClass: schoolClass) }
        }
    }
}
