import SwiftUI
import SwiftData

struct TodayView: View {
    @Query(filter: #Predicate<Lesson> { $0.isPlanned }, sort: \Lesson.date)
    private var planned: [Lesson]

    var catchUp: [Lesson] {
        planned.filter { $0.date < Calendar.current.startOfDay(for: Date()) }
    }
    var today: [Lesson] {
        planned.filter { Calendar.current.isDateInToday($0.date) }
    }
    var upcoming: [Lesson] {
        planned.filter { $0.date > Date() && !Calendar.current.isDateInToday($0.date) }
    }

    var body: some View {
        NavigationStack {
            List {
                if planned.isEmpty {
                    ContentUnavailableView("Nothing planned",
                        systemImage: "calendar",
                        description: Text("Plan a lesson from a student's profile."))
                }
                if !catchUp.isEmpty {
                    Section("Needs a note") { rows(catchUp) }
                }
                if !today.isEmpty {
                    Section("Today") { rows(today) }
                }
                if !upcoming.isEmpty {
                    Section("Upcoming") { rows(upcoming) }
                }
            }
            .navigationTitle("Today")
        }
    }

    func rows(_ lessons: [Lesson]) -> some View {
        ForEach(lessons) { lesson in
            NavigationLink {
                EditLessonView(lesson: lesson)
            } label: {
                VStack(alignment: .leading) {
                    Text(lesson.student?.name ?? "Student").font(.headline)
                    Text(lesson.topic)
                    Text(lesson.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
