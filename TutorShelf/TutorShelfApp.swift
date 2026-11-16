import SwiftUI
import SwiftData

@main
struct TutorShelfApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
        }
        .modelContainer(for: Student.self)
    }
}
