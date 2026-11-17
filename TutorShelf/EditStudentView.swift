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
                Picker("Regular day", selection: $student.lessonWeekday) {
                    Text("None").tag(0)
                    ForEach(1...7, id: \.self) { day in
                        Text(Calendar.current.weekdaySymbols[day - 1]).tag(day)
                    }
                }
                if student.lessonWeekday > 0 {
                    DatePicker("Time", selection: $student.lessonTime, displayedComponents: .hourAndMinute)
                }
            }
            
            Section("Worksheets") {
                Picker("Level", selection: $student.level) {
                    Text("Primary (K–3)").tag("Primary")
                    Text("Intermediate (4–7)").tag("Intermediate")
                    Text("Secondary (8–12)").tag("Secondary")
                }
                Picker("Style", selection: $student.worksheetStyle) {
                    Text("Classic").tag("Classic")
                    Text("Cozy").tag("Cozy")
                    Text("Game").tag("Game")
                }
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
