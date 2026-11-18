import SwiftUI
import SwiftData

struct EditLessonView: View {
    @Bindable var lesson: Lesson
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var confirmingDelete = false
    
    // A planned lesson can be marked taught once it has both a rating and a note.
    var readyToMark: Bool {
        lesson.isPlanned
        && !lesson.rating.isEmpty
        && !lesson.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        Form {
            DatePicker("Date", selection: $lesson.date, displayedComponents: .date)
            TextField("What you covered", text: $lesson.topic)
            TextField("Focus for this lesson", text: $lesson.focus, axis: .vertical)
            
            Picker("It was", selection: $lesson.rating) {
                Text("Easy").tag("Easy")
                Text("Okay").tag("Okay")
                Text("Struggled").tag("Struggled")
            }
            .pickerStyle(.segmented)
            
            TextField("Your note", text: $lesson.note, axis: .vertical)
            Toggle("Share with parents", isOn: $lesson.shareWithParents)
            
            if lesson.isPlanned && !readyToMark {
                Text("Add a rating and a note to mark this lesson as taught.")
                    .font(.rounded(.footnote))
                    .foregroundStyle(.secondary)
            }
            
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
            
            Section {
                Button("Delete lesson", role: .destructive) {
                    confirmingDelete = true
                }
            }
        }
        .font(.rounded(.body))
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("Edit lesson")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(readyToMark ? "Mark taught" : "Done") {
                    if readyToMark { markTaught() }
                    dismiss()
                }
            }
        }
        .alert("Delete this lesson?", isPresented: $confirmingDelete) {
            Button("Delete", role: .destructive) {
                dismiss()
                modelContext.delete(lesson)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Its note will be deleted too. Worksheets stay in the library.")
        }
    }
    
    // Moves the lesson to Past lessons and updates its roadmap topic from the rating.
    func markTaught() {
        lesson.isPlanned = false
        if let item = lesson.roadmapTopic {
            if lesson.rating == "Easy" {
                item.status = "Mastered"
            } else if lesson.rating == "Okay" {
                // Don't undo mastery: an "Okay" review of a mastered topic leaves it Mastered.
                if item.status != "Mastered" {
                    item.status = "In progress"
                }
            } else {
                item.status = "Needs review"
            }
        }
    }
}
