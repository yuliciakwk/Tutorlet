import SwiftUI

struct PlanLessonView: View {
    @Environment(\.dismiss) private var dismiss
    let student: Student

    @State private var date = Date()
    @State private var topic = ""
    @State private var selectedIndex = -1

    var roadmapTopics: [Topic] {
        student.tracks.flatMap { track in
            track.topics.sorted { a, b in a.order < b.order }
        }
    }

    var selectedTopic: Topic? {
        roadmapTopics.indices.contains(selectedIndex) ? roadmapTopics[selectedIndex] : nil
    }

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("When", selection: $date)

                if !roadmapTopics.isEmpty {
                    Picker("Roadmap topic", selection: $selectedIndex) {
                        Text("None").tag(-1)
                        ForEach(Array(roadmapTopics.enumerated()), id: \.offset) { index, item in
                            Text(item.title).tag(index)
                        }
                    }
                    .onChange(of: selectedIndex) {
                        if let selectedTopic { topic = selectedTopic.title }
                    }
                }

                TextField("What you'll cover", text: $topic)
            }
            .navigationTitle("Plan a lesson")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let lesson = Lesson(date: date, topic: topic)
                        lesson.isPlanned = true
                        lesson.rating = ""
                        student.lessons.append(lesson)
                        lesson.roadmapTopic = selectedTopic
                        dismiss()
                    }
                    .disabled(topic.isEmpty)
                }
            }
            .onAppear {
                if let next = student.tracks.compactMap({ $0.nextTopic }).first,
                   let index = roadmapTopics.firstIndex(where: { $0 === next }) {
                    selectedIndex = index
                    topic = next.title
                }
            }
        }
    }
}
