import Foundation
import SwiftUI
import UniformTypeIdentifiers

/// En rad i elevens ackumulerade lista (närvaro eller anteckning).
struct TimelineItem: Identifiable {
    let id = UUID()
    var date: Date
    var courseName: String
    var attendance: String
    var moment: String
    var comment: String
    var grade: String
    var note: StudentNote?
}

enum Timeline {
    static func items(for student: Student, course: Course?) -> [TimelineItem] {
        var items: [TimelineItem] = []
        for r in student.attendance ?? [] {
            guard let lesson = r.lesson, course == nil || lesson.course?.persistentModelID == course?.persistentModelID else { continue }
            items.append(TimelineItem(date: lesson.date, courseName: lesson.course?.name ?? "", attendance: r.summary,
                                      moment: "", comment: "", grade: "", note: nil))
        }
        for n in student.notes ?? [] {
            guard course == nil || n.course?.persistentModelID == course?.persistentModelID else { continue }
            items.append(TimelineItem(date: n.date, courseName: n.course?.name ?? "", attendance: "",
                                      moment: n.moment, comment: n.comment, grade: n.grade.rawValue, note: n))
        }
        return items.sorted { $0.date < $1.date }
    }

    static func csv(students: [Student], course: Course?) -> String {
        func q(_ s: String) -> String { "\"" + s.replacingOccurrences(of: "\"", with: "\"\"") + "\"" }
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        var out = "Elev;Klass;Kurs;Datum;Närvaro;Moment;Kommentar;Betyg\n"
        for s in students {
            for i in items(for: s, course: course) {
                out += [s.fullName, s.schoolClass?.name ?? "", i.courseName, df.string(from: i.date),
                        i.attendance, i.moment, i.comment, i.grade].map(q).joined(separator: ";") + "\n"
            }
        }
        return out
    }
}

struct CSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    var text = ""
    init(text: String) { self.text = text }
    init(configuration: ReadConfiguration) throws {
        text = String(decoding: configuration.file.regularFileContents ?? Data(), as: UTF8.self)
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        // BOM så att Excel läser å/ä/ö korrekt
        FileWrapper(regularFileWithContents: Data("\u{FEFF}".utf8) + Data(text.utf8))
    }
}
