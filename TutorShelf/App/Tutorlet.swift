import SwiftUI
import SwiftData

@main
struct Tutorlet: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
        }
        .modelContainer(for: Student.self)
    }
}
