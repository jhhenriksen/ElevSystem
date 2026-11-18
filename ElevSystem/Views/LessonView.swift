import SwiftUI
import SwiftData

struct LessonView: View {
    let lesson: Lesson
    let course: Course
    @Environment(\.modelContext) private var context

    var body: some View {
        List {
            ForEach(course.schoolClass?.sortedStudents ?? []) { s in
                AttendanceRow(lesson: lesson, student: s, course: course)
            }
        }
        .navigationTitle(lesson.date.formatted(.dateTime.weekday(.wide).day().month(.wide)))
        .navigationSubtitle(course.name)
        .toolbar {
            Button("Alla OK") {
                for s in course.schoolClass?.students ?? [] where lesson.record(for: s) == nil {
                    context.insert(AttendanceRecord(status: .ok, lesson: lesson, student: s))
                }
            }
        }
    }
}

struct AttendanceRow: View {
    let lesson: Lesson
    let student: Student
    let course: Course
    @Environment(\.modelContext) private var context

    var body: some View {
        let record = lesson.record(for: student)
        HStack(spacing: 8) {
            NavigationLink { StudentDetailView(student: student, course: course) } label: {
                Text("\(student.lastName), \(student.firstName)")
            }
            Spacer()
            if let record, record.status == .late {
                TextField("min", value: Binding(get: { record.lateMinutes }, set: { record.lateMinutes = max(0, $0) }), format: .number)
                    .frame(width: 50).multilineTextAlignment(.trailing)
                Text("min").foregroundStyle(.secondary)
            }
            ForEach(AttendanceStatus.allCases) { status in
                Button(status.label) { set(status, record) }
                    .buttonStyle(.bordered)
                    .tint(record?.status == status ? color(status) : nil)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(record?.status == status ? color(status) : .clear, lineWidth: 2))
            }
            Button { if let record { context.delete(record) } } label: { Image(systemName: "xmark.circle") }
                .buttonStyle(.borderless).disabled(record == nil).help("Rensa registrering")
        }
    }

    private func set(_ status: AttendanceStatus, _ record: AttendanceRecord?) {
        if let record {
            record.status = status
            if status != .late { record.lateMinutes = 0 }
        } else {
            context.insert(AttendanceRecord(status: status, lesson: lesson, student: student))
        }
    }

    private func color(_ s: AttendanceStatus) -> Color {
        switch s { case .ok: .green; case .late: .orange; case .absent: .red }
    }
}
