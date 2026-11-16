import SwiftUI

struct EditStudentView: View {
    @Bindable var student: Student

    var body: some View {
        Form {
            Section("Basics") {
                TextField("Name", text: $student.name)
                TextField("Grade", text: $student.grade)
                TextField("Subjects", text: $student.subjects)
            }

            Section("Card colour") {
                HStack(spacing: 14) {
                    ForEach(Theme.colorOrder, id: \.self) { name in
                        Button {
                            student.colorName = name
                        } label: {
                            Circle()
                                .fill(Theme.studentColors[name] ?? Theme.card)
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Circle().stroke(Theme.ink,
                                                    lineWidth: Theme.colorName(for: student) == name ? 3 : 0)
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(name.capitalized)
                    }
                }
                .padding(.vertical, 6)
            }

            Section("Lessons") {
                Picker("Format", selection: $student.format) {
                    Text("In person").tag("In person")
                    Text("Online").tag("Online")
                }
                .pickerStyle(.segmented)

                Stepper("Length: \(student.lessonMinutes) min",
                        value: $student.lessonMinutes, in: 30...120, step: 15)
            }

            Section("About them") {
                TextField("Strengths", text: $student.strengths, axis: .vertical)
                TextField("Focus areas", text: $student.focusAreas, axis: .vertical)
                TextField("Interests", text: $student.interests, axis: .vertical)
                TextField("Learning style", text: $student.learningStyle, axis: .vertical)
            }

            Section("Notes") {
                TextField("Anything else", text: $student.notes, axis: .vertical)
            }
        }
        .font(.rounded(.body))
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("Edit profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}
