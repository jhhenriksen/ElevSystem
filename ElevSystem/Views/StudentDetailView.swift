import SwiftUI
import SwiftData

struct StudentDetailView: View {
    let student: Student
    let course: Course?
    @Environment(\.modelContext) private var context

    @State private var date = Date()
    @State private var moment = ""
    @State private var comment = ""
    @State private var grade: Grade = .none
    @State private var exporting = false

    private var items: [TimelineItem] { Timeline.items(for: student, course: course) }

    var body: some View {
        HSplitView {
            Form {
                Section("Ny anteckning") {
                    DatePicker("Datum", selection: $date, displayedComponents: .date)
                    VStack(alignment: .leading) {
                        Text("Moment")
                        TextEditor(text: $moment).frame(minHeight: 70).border(.quaternary)
                    }
                    VStack(alignment: .leading) {
                        Text("Kommentar")
                        TextEditor(text: $comment).frame(minHeight: 90).border(.quaternary)
                    }
                    Picker("Betyg", selection: $grade) {
                        ForEach(Grade.allCases) { Text($0.rawValue).tag($0) }
                    }.pickerStyle(.segmented)
                    Button("Spara") { save() }
                        .keyboardShortcut(.defaultAction)
                        .disabled(course == nil || (moment.isEmpty && comment.isEmpty && grade == .none))
                    if course == nil {
                        Text("Öppna eleven från en kurs för att skriva anteckningar.").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .formStyle(.grouped)
            .frame(minWidth: 320, idealWidth: 360)

            Table(items) {
                TableColumn("Datum") { Text($0.date.formatted(date: .abbreviated, time: .omitted)) }.width(min: 80, ideal: 100)
                if course == nil { TableColumn("Kurs", value: \.courseName) }
                TableColumn("Närvaro", value: \.attendance).width(min: 70, ideal: 110)
                TableColumn("Moment", value: \.moment)
                TableColumn("Kommentar", value: \.comment)
                TableColumn("Betyg", value: \.grade).width(40)
                TableColumn("") { item in
                    if let n = item.note {
                        Button { context.delete(n) } label: { Image(systemName: "trash") }.buttonStyle(.borderless)
                    }
                }.width(30)
            }
            .frame(minWidth: 380)
        }
        .navigationTitle(student.fullName)
        .navigationSubtitle(course?.name ?? student.schoolClass?.name ?? "")
        .toolbar {
            Button { exporting = true } label: { Label("Exportera CSV", systemImage: "square.and.arrow.up") }
        }
        .fileExporter(isPresented: $exporting,
                      document: CSVDocument(text: Timeline.csv(students: [student], course: course)),
                      contentType: .commaSeparatedText, defaultFilename: student.fullName) { _ in }
    }

    private func save() {
        context.insert(StudentNote(date: date, moment: moment, comment: comment, grade: grade, student: student, course: course))
        moment = ""; comment = ""; grade = .none
    }
}
