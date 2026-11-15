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
            if let student = lesson.student {
                Section("Worksheets used") {
                    if student.worksheets.isEmpty {
                        Text("Add worksheets from the student's profile first.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(student.worksheets
                        .filter { $0.lesson == nil || $0.lesson === lesson }
                        .sorted { $0.addedOn > $1.addedOn }) { worksheet in
                        Button {
                            if worksheet.lesson === lesson {
                                worksheet.lesson = nil
                            } else {
                                worksheet.lesson = lesson
                            }
                        } label: {
                            HStack {
                                Text(worksheet.title)
                                Spacer()
                                if worksheet.lesson === lesson {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Edit lesson")
        .navigationBarTitleDisplayMode(.inline)
    }
}
