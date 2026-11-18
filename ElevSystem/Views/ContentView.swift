import SwiftUI
import SwiftData

enum SidebarItem: Hashable {
    case course(PersistentIdentifier)
    case schoolClass(PersistentIdentifier)
}

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Course.name) private var courses: [Course]
    @Query(sort: \SchoolClass.name) private var classes: [SchoolClass]

    @State private var selection: SidebarItem?
    @State private var showNewCourse = false
    @State private var showImporter = false
    @State private var importedCSV: String?
    @State private var newClassName = ""
    @State private var showNewClass = false

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section("Kurser") {
                    ForEach(courses) { course in
                        VStack(alignment: .leading) {
                            Text(course.name)
                            if let c = course.schoolClass { Text(c.name).font(.caption).foregroundStyle(.secondary) }
                        }
                        .tag(SidebarItem.course(course.persistentModelID))
                        .contextMenu { Button("Ta bort kurs", role: .destructive) { delete(course) } }
                    }
                }
                Section("Klasser") {
                    ForEach(classes) { c in
                        Label("\(c.name) (\(c.students?.count ?? 0))", systemImage: "person.3")
                            .tag(SidebarItem.schoolClass(c.persistentModelID))
                            .contextMenu { Button("Ta bort klass", role: .destructive) { delete(c) } }
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 240)
            .toolbar {
                ToolbarItemGroup {
                    Button { showNewCourse = true } label: { Label("Ny kurs", systemImage: "plus.rectangle.on.rectangle") }
                    Menu {
                        Button("Ny tom klass…") { newClassName = ""; showNewClass = true }
                        Button("Importera klasslista (CSV)…") { showImporter = true }
                    } label: { Label("Klasser", systemImage: "person.3.fill") }
                }
            }
        } detail: {
            NavigationStack {
                switch selection {
                case .course(let id):
                    if let course = courses.first(where: { $0.persistentModelID == id }) {
                        CourseDetailView(course: course).id(id)
                    }
                case .schoolClass(let id):
                    if let c = classes.first(where: { $0.persistentModelID == id }) {
                        ClassDetailView(schoolClass: c).id(id)
                    }
                case nil:
                    ContentUnavailableView("Välj en kurs eller klass", systemImage: "graduationcap",
                                           description: Text("Skapa en kurs eller importera en klasslista för att börja."))
                }
            }
        }
        .sheet(isPresented: $showNewCourse) {
            CourseEditorView(course: nil) { selection = .course($0.persistentModelID) }
        }
        .sheet(isPresented: Binding(get: { importedCSV != nil }, set: { if !$0 { importedCSV = nil } })) {
            if let csv = importedCSV { ImportClassView(csv: csv) }
        }
        .alert("Ny klass", isPresented: $showNewClass) {
            TextField("Klassnamn", text: $newClassName)
            Button("Skapa") {
                let c = SchoolClass(name: newClassName)
                context.insert(c)
                selection = .schoolClass(c.persistentModelID)
            }
            Button("Avbryt", role: .cancel) {}
        }
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.commaSeparatedText, .plainText, .text]) { result in
            guard case .success(let url) = result else { return }
            let access = url.startAccessingSecurityScopedResource()
            defer { if access { url.stopAccessingSecurityScopedResource() } }
            if let data = try? Data(contentsOf: url) { importedCSV = CSVImport.decode(data) }
        }
        .frame(minWidth: 900, minHeight: 560)
    }

    private func delete(_ course: Course) {
        if selection == .course(course.persistentModelID) { selection = nil }
        context.delete(course)
    }
    private func delete(_ c: SchoolClass) {
        if selection == .schoolClass(c.persistentModelID) { selection = nil }
        context.delete(c)
    }
}
