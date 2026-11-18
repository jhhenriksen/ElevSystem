import SwiftUI
import SwiftData

struct CourseDetailView: View {
    @Bindable var course: Course
    @Environment(\.modelContext) private var context
    @State private var tab = 0
    @State private var showEditor = false
    @State private var exporting = false

    private static let dateFormat: Date.FormatStyle = .dateTime.weekday(.wide).day().month(.wide).year()

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $tab) {
                Text("Lektioner").tag(0)
                Text("Elever").tag(1)
            }
            .pickerStyle(.segmented).labelsHidden().frame(width: 260).padding(8)

            if tab == 0 { lessonList } else { studentList }
        }
        .navigationTitle(course.name)
        .navigationSubtitle(course.schoolClass?.name ?? "Ingen klass")
        .toolbar {
            ToolbarItemGroup {
                Button { exporting = true } label: { Label("Exportera CSV", systemImage: "square.and.arrow.up") }
                Button { showEditor = true } label: { Label("Redigera kurs", systemImage: "pencil") }
            }
        }
        .sheet(isPresented: $showEditor) { CourseEditorView(course: course) }
        .fileExporter(isPresented: $exporting,
                      document: CSVDocument(text: Timeline.csv(students: course.schoolClass?.sortedStudents ?? [], course: course)),
                      contentType: .commaSeparatedText, defaultFilename: "\(course.name) – sammanställning") { _ in }
    }

    private var lessonList: some View {
        List {
            if course.sortedLessons.isEmpty {
                ContentUnavailableView("Inga lektioner", systemImage: "calendar",
                                       description: Text("Redigera kursen och välj datum."))
            }
            ForEach(course.sortedLessons) { lesson in
                NavigationLink { LessonView(lesson: lesson, course: course) } label: {
                    HStack {
                        Text(lesson.date.formatted(Self.dateFormat))
                        Spacer()
                        let n = lesson.attendance?.count ?? 0
                        let total = course.schoolClass?.students?.count ?? 0
                        Text(n == 0 ? "Ej tagen" : "\(n)/\(total) registrerade")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var studentList: some View {
        List {
            if let students = course.schoolClass?.sortedStudents, !students.isEmpty {
                ForEach(students) { s in
                    NavigationLink { StudentDetailView(student: s, course: course) } label: {
                        HStack {
                            Text("\(s.lastName), \(s.firstName)")
                            Spacer()
                            if let g = latestGrade(s) { Text(g).font(.headline).foregroundStyle(.secondary) }
                        }
                    }
                }
            } else {
                ContentUnavailableView("Inga elever", systemImage: "person.3",
                                       description: Text("Knyt en klass med elever till kursen."))
            }
        }
    }

    private func latestGrade(_ s: Student) -> String? {
        (s.notes ?? []).filter { $0.course?.persistentModelID == course.persistentModelID && $0.grade != .none }
            .max { $0.date < $1.date }?.grade.rawValue
    }
}
