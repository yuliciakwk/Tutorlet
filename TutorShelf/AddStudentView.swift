import SwiftUI
import SwiftData

struct AddStudentView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var grade = ""
    @State private var subjects = ""
    @State private var strengths = ""
    @State private var focusAreas = ""
    @State private var interests = ""
    @State private var learningStyle = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Basics") {
                    TextField("Name", text: $name)
                    TextField("Grade", text: $grade)
                    TextField("Subjects", text: $subjects)
                }
                Section("About them") {
                    TextField("Strengths", text: $strengths, axis: .vertical)
                    TextField("Focus areas", text: $focusAreas, axis: .vertical)
                    TextField("Interests", text: $interests, axis: .vertical)
                    TextField("Learning style", text: $learningStyle, axis: .vertical)
                }
                Section("Notes") {
                    TextField("Anything else", text: $notes, axis: .vertical)
                }
            }
            .navigationTitle("New student")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let student = Student(
                            name: name, grade: grade, subjects: subjects,
                            strengths: strengths, focusAreas: focusAreas,
                            interests: interests, learningStyle: learningStyle,
                            notes: notes
                        )
                        context.insert(student)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
