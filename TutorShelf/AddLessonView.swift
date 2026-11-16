import SwiftUI
import SwiftData

struct AddLessonView: View {
    @Environment(\.dismiss) private var dismiss
    let student: Student

    @State private var date = Date()
    @State private var topic = ""
    @State private var rating = "Okay"
    @State private var note = ""
    @State private var shareWithParents = true
    @State private var selectedWorksheets: [Worksheet] = []
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
                DatePicker("Date", selection: $date, displayedComponents: .date)
                if !roadmapTopics.isEmpty {
                    Picker("Roadmap topic", selection: $selectedIndex) {
                        Text("None").tag(-1)
                        ForEach(Array(roadmapTopics.enumerated()), id: \.offset) { index, item in
                            Text(item.title).tag(index)
                        }
                    }
                    .onChange(of: selectedIndex) {
                        if let selectedTopic {
                            topic = selectedTopic.title
                        }
                    }
                }
                TextField("What you covered", text: $topic)

                Picker("It was", selection: $rating) {
                    Text("Easy").tag("Easy")
                    Text("Okay").tag("Okay")
                    Text("Struggled").tag("Struggled")
                }
                .pickerStyle(.segmented)

                TextField("Your note", text: $note, axis: .vertical)
                Toggle("Share with parents", isOn: $shareWithParents)
                if !student.worksheets.isEmpty {
                    Section("Worksheets used") {
                        ForEach(student.worksheets
                            .filter { $0.lesson == nil }
                            .sorted { $0.addedOn > $1.addedOn }
                            .prefix(5)) { worksheet in
                            Button {
                                if let index = selectedWorksheets.firstIndex(where: { $0 === worksheet }) {
                                    selectedWorksheets.remove(at: index)
                                } else {
                                    selectedWorksheets.append(worksheet)
                                }
                            } label: {
                                HStack {
                                    Text(worksheet.title)
                                    Spacer()
                                    if selectedWorksheets.contains(where: { $0 === worksheet }) {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("How did it go?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let lesson = Lesson(date: date, topic: topic, rating: rating,
                                            note: note, shareWithParents: shareWithParents)
                        student.lessons.append(lesson)
                        for worksheet in selectedWorksheets {
                            worksheet.lesson = lesson
                        }
                        if let selectedTopic {
                            lesson.roadmapTopic = selectedTopic
                            if rating == "Easy" {
                                selectedTopic.status = "Mastered"
                            } else if rating == "Okay" {
                                selectedTopic.status = "In progress"
                            } else {
                                selectedTopic.status = "Needs review"
                            }
                        }
                        dismiss()
                    }
                    .disabled(topic.isEmpty)
                }
            }
        }
    }
}
