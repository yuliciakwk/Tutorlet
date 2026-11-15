import SwiftUI
import SwiftData

struct EditLessonView: View {
    @Bindable var lesson: Lesson

    var body: some View {
        Form {
            DatePicker("Date", selection: $lesson.date, displayedComponents: .date)
            TextField("What you covered", text: $lesson.topic)

            Picker("It was", selection: $lesson.rating) {
                Text("Easy").tag("Easy")
                Text("Okay").tag("Okay")
                Text("Struggled").tag("Struggled")
            }
            .pickerStyle(.segmented)

            TextField("Your note", text: $lesson.note, axis: .vertical)
            Toggle("Share with parents", isOn: $lesson.shareWithParents)
        }
        .navigationTitle("Edit lesson")
        .navigationBarTitleDisplayMode(.inline)
    }
}
