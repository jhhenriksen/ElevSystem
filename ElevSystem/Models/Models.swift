import Foundation
import SwiftData

// Alla attribut har standardvärden och alla relationer är valfria – krav för CloudKit-synk.

@Model
final class SchoolClass {
    var name: String = ""
    @Relationship(deleteRule: .cascade, inverse: \Student.schoolClass)
    var students: [Student]? = []
    @Relationship(deleteRule: .nullify, inverse: \Course.schoolClass)
    var courses: [Course]? = []

    init(name: String) { self.name = name }

    var sortedStudents: [Student] {
        (students ?? []).sorted { $0.sortKey < $1.sortKey }
    }
}

@Model
final class Student {
    var firstName: String = ""
    var lastName: String = ""
    var schoolClass: SchoolClass?
    @Relationship(deleteRule: .cascade, inverse: \AttendanceRecord.student)
    var attendance: [AttendanceRecord]? = []
    @Relationship(deleteRule: .cascade, inverse: \StudentNote.student)
    var notes: [StudentNote]? = []

    init(firstName: String, lastName: String, schoolClass: SchoolClass? = nil) {
        self.firstName = firstName
        self.lastName = lastName
        self.schoolClass = schoolClass
    }

    var fullName: String { "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces) }
    var sortKey: String { "\(lastName) \(firstName)".lowercased() }
}

@Model
final class Course {
    var name: String = ""
    var schoolClass: SchoolClass?
    @Relationship(deleteRule: .cascade, inverse: \Lesson.course)
    var lessons: [Lesson]? = []
    @Relationship(deleteRule: .cascade, inverse: \StudentNote.course)
    var notes: [StudentNote]? = []

    init(name: String, schoolClass: SchoolClass? = nil) {
        self.name = name
        self.schoolClass = schoolClass
    }

    var sortedLessons: [Lesson] {
        (lessons ?? []).sorted { $0.date < $1.date }
    }
}

@Model
final class Lesson {
    var date: Date = Date()
    var course: Course?
    @Relationship(deleteRule: .cascade, inverse: \AttendanceRecord.lesson)
    var attendance: [AttendanceRecord]? = []

    init(date: Date, course: Course? = nil) {
        self.date = date
        self.course = course
    }

    func record(for student: Student) -> AttendanceRecord? {
        (attendance ?? []).first { $0.student?.persistentModelID == student.persistentModelID }
    }
}

enum AttendanceStatus: String, CaseIterable, Identifiable {
    case ok, late, absent
    var id: String { rawValue }
    var label: String {
        switch self {
        case .ok: "OK"
        case .late: "Sen"
        case .absent: "Ogiltig frånvaro"
        }
    }
}

@Model
final class AttendanceRecord {
    var statusRaw: String = AttendanceStatus.ok.rawValue
    var lateMinutes: Int = 0
    var lesson: Lesson?
    var student: Student?

    init(status: AttendanceStatus, lateMinutes: Int = 0, lesson: Lesson?, student: Student?) {
        self.statusRaw = status.rawValue
        self.lateMinutes = lateMinutes
        self.lesson = lesson
        self.student = student
    }

    var status: AttendanceStatus {
        get { AttendanceStatus(rawValue: statusRaw) ?? .ok }
        set { statusRaw = newValue.rawValue }
    }

    var summary: String {
        switch status {
        case .ok: "OK"
        case .late: "Sen \(lateMinutes) min"
        case .absent: "Ogiltig frånvaro"
        }
    }
}

enum Grade: String, CaseIterable, Identifiable {
    case none = "-", e = "E", d = "D", c = "C", b = "B", a = "A"
    var id: String { rawValue }
}

@Model
final class StudentNote {
    var date: Date = Date()
    var moment: String = ""
    var comment: String = ""
    var gradeRaw: String = Grade.none.rawValue
    var student: Student?
    var course: Course?

    init(date: Date, moment: String, comment: String, grade: Grade, student: Student?, course: Course?) {
        self.date = date
        self.moment = moment
        self.comment = comment
        self.gradeRaw = grade.rawValue
        self.student = student
        self.course = course
    }

    var grade: Grade {
        get { Grade(rawValue: gradeRaw) ?? .none }
        set { gradeRaw = newValue.rawValue }
    }
}
