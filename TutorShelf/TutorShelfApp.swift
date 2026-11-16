import SwiftUI
import SwiftData

@main
struct TutorShelfApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                TodayView()
                    .tabItem { Label("Today", systemImage: "calendar") }
                ContentView()
                    .tabItem { Label("Students", systemImage: "person.2") }
            }
            .preferredColorScheme(.light)
        }
        .modelContainer(for: Student.self)
    }
}
