import SwiftUI
import SwiftData

struct CourseEditorView: View {
    let course: Course?
    var onSaved: (Course) -> Void = { _ in }

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \SchoolClass.name) private var classes: [SchoolClass]

    @State private var name = ""
    @State private var schoolClass: SchoolClass?
    @State private var dates: Set<Date> = []

    // Snabbgenerator för återkommande lektioner
    @State private var rangeStart = Date()
    @State private var rangeEnd = Calendar.current.date(byAdding: .month, value: 4, to: Date()) ?? Date()
    @State private var weekdays: Set<Int> = []

    private var cal: Calendar { Calendar.current }
    private let weekdayNames = [(2, "Mån"), (3, "Tis"), (4, "Ons"), (5, "Tors"), (6, "Fre")]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(course == nil ? "Ny kurs" : "Redigera kurs").font(.title2.bold())
            Form {
                TextField("Kursnamn", text: $name)
                Picker("Klass", selection: $schoolClass) {
                    Text("Ingen").tag(SchoolClass?.none)
                    ForEach(classes) { Text($0.name).tag(Optional($0)) }
                }
            }
            HStack(alignment: .top, spacing: 24) {
                VStack(alignment: .leading) {
                    Text("Välj lektionsdatum").font(.headline)
                    MultiDateCalendar(selection: $dates)
                        .frame(width: 320)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Lägg till återkommande").font(.headline)
                    DatePicker("Från", selection: $rangeStart, displayedComponents: .date)
                    DatePicker("Till", selection: $rangeEnd, displayedComponents: .date)
                    HStack {
                        ForEach(weekdayNames, id: \.0) { wd, label in
                            Toggle(label, isOn: Binding(get: { weekdays.contains(wd) },
                                                        set: { if $0 { weekdays.insert(wd) } else { weekdays.remove(wd) } }))
                                .toggleStyle(.button)
                        }
                    }
                    Button("Lägg till datum i intervallet") { addRecurring() }
                        .disabled(weekdays.isEmpty)
                    Divider()
                    Text("\(dates.count) lektioner valda").foregroundStyle(.secondary)
                    Button("Rensa alla datum") { dates = [] }.disabled(dates.isEmpty)
                }
            }
            HStack {
                Spacer()
                Button("Avbryt", role: .cancel) { dismiss() }
                Button("Spara") { save(); dismiss() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding()
        .frame(minWidth: 720)
        .onAppear(perform: load)
    }

    private func load() {
        guard let course else { return }
        name = course.name
        schoolClass = course.schoolClass
        dates = Set(course.sortedLessons.map { cal.startOfDay(for: $0.date) })
    }

    private func addRecurring() {
        var d = cal.startOfDay(for: rangeStart)
        let end = cal.startOfDay(for: rangeEnd)
        while d <= end {
            if weekdays.contains(cal.component(.weekday, from: d)) {
                dates.insert(d)
            }
            d = cal.date(byAdding: .day, value: 1, to: d)!
        }
    }

    private func save() {
        let target = course ?? Course(name: name)
        if course == nil { context.insert(target) }
        target.name = name
        target.schoolClass = schoolClass

        let wanted = dates
        var have = Set<Date>()
        for lesson in target.lessons ?? [] {
            let day = cal.startOfDay(for: lesson.date)
            if wanted.contains(day) && !have.contains(day) { have.insert(day) }
            else { context.delete(lesson) }
        }
        for day in wanted.subtracting(have) { context.insert(Lesson(date: day, course: target)) }
        onSaved(target)
    }
}
