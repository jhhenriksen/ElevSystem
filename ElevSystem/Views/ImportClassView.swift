import SwiftUI
import SwiftData

/// Förhandsgranskar en inläst CSV och skapar klass(er) med elever.
struct ImportClassView: View {
    let csv: String
    var targetClass: SchoolClass? = nil

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var existing: [SchoolClass]
    @State private var defaultClassName = ""

    private var parsed: [ImportedStudent] { CSVImport.students(from: csv) }
    private var hasClassColumn: Bool { parsed.contains { $0.className != nil } }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Importera klasslista").font(.title2.bold())
            Text("\(parsed.count) elever hittades. Kolumner som känns igen: Förnamn, Efternamn (eller Namn) och Klass.")
                .foregroundStyle(.secondary)
            if targetClass == nil {
                TextField(hasClassColumn ? "Klassnamn för rader utan klass" : "Klassnamn", text: $defaultClassName)
            }
            List(Array(parsed.enumerated()), id: \.offset) { _, s in
                HStack {
                    Text("\(s.lastName), \(s.firstName)")
                    Spacer()
                    Text(s.className ?? targetClass?.name ?? defaultClassName).foregroundStyle(.secondary)
                }
            }
            .frame(minHeight: 240)
            HStack {
                Spacer()
                Button("Avbryt", role: .cancel) { dismiss() }
                Button("Importera") { importAll(); dismiss() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(parsed.isEmpty || (targetClass == nil && !hasClassColumn && defaultClassName.isEmpty))
            }
        }
        .padding()
        .frame(minWidth: 520, minHeight: 440)
    }

    private func importAll() {
        var byName: [String: SchoolClass] = Dictionary(existing.map { ($0.name, $0) }, uniquingKeysWith: { a, _ in a })
        for s in parsed {
            let cls: SchoolClass
            if let t = targetClass { cls = t }
            else {
                let name = s.className ?? defaultClassName
                if let c = byName[name] { cls = c }
                else { cls = SchoolClass(name: name); context.insert(cls); byName[name] = cls }
            }
            let dup = (cls.students ?? []).contains { $0.firstName == s.firstName && $0.lastName == s.lastName }
            if !dup { context.insert(Student(firstName: s.firstName, lastName: s.lastName, schoolClass: cls)) }
        }
    }
}
