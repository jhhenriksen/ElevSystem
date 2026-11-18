import SwiftUI
import SwiftData

@main
struct ElevSystemApp: App {
    let container: ModelContainer = {
        let schema = Schema([SchoolClass.self, Student.self, Course.self, Lesson.self,
                             AttendanceRecord.self, StudentNote.self])
        do {
            // iCloud (CloudKit) – kräver signering med utvecklarkonto och iCloud-capability.
            return try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, cloudKitDatabase: .automatic))
        } catch {
            print("CloudKit-container misslyckades (\(error)), använder lokal lagring.")
            return try! ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, cloudKitDatabase: .none))
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
