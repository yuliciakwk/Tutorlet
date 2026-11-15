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

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Date", selection: $date, displayedComponents: .date)
                TextField("What you covered", text: $topic)

                Picker("It was", selection: $rating) {
                    Text("Easy").tag("Easy")
                    Text("Okay").tag("Okay")
                    Text("Struggled").tag("Struggled")
                }
                .pickerStyle(.segmented)

                TextField("Your note", text: $note, axis: .vertical)
                Toggle("Share with parents", isOn: $shareWithParents)
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
                        dismiss()
                    }
                    .disabled(topic.isEmpty)
                }
            }
        }
    }
}
