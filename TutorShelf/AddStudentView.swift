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
    @State private var format = "In person"
    @State private var lessonMinutes = 60
    @State private var lessonWeekday = 0
    @State private var lessonTime = Calendar.current.date(bySettingHour: 16, minute: 0, second: 0, of: Date()) ?? Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Basics") {
                    TextField("Name", text: $name)
                    TextField("Grade", text: $grade)
                    TextField("Subjects", text: $subjects)
                }
                Section("Lessons") {
                    Picker("Format", selection: $format) {
                        Text("In person").tag("In person")
                        Text("Online").tag("Online")
                    }
                    .pickerStyle(.segmented)

                    Stepper("Length: \(lessonMinutes) min", value: $lessonMinutes, in: 30...120, step: 15)
                    Picker("Regular day", selection: $lessonWeekday) {
                        Text("None").tag(0)
                        ForEach(1...7, id: \.self) { day in
                            Text(Calendar.current.weekdaySymbols[day - 1]).tag(day)
                        }
                    }
                    if lessonWeekday > 0 {
                        DatePicker("Time", selection: $lessonTime, displayedComponents: .hourAndMinute)
                    }
                }
                Section("About them") {
                    TextField("Strengths", text: $strengths, axis: .vertical)
                    TextField("Focus areas", text: $focusAreas, axis: .vertical)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Interests").font(.rounded(.subheadline, .bold))
                        ChipPicker(options: ProfileOptions.interests, text: $interests)
                        TextField("Anything else they love", text: $interests, axis: .vertical)
                    }
                    .padding(.vertical, 6)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Learning style").font(.rounded(.subheadline, .bold))
                        ChipPicker(options: ProfileOptions.learningStyles, text: $learningStyle)
                        TextField("Anything else about how they learn", text: $learningStyle, axis: .vertical)
                    }
                    .padding(.vertical, 6)
                }
                Section("Notes") {
                    TextField("Anything else", text: $notes, axis: .vertical)
                }
            }
            .font(.rounded(.body))
            .scrollContentBackground(.hidden)
            .background(Theme.background)
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
                        student.format = format
                        student.lessonMinutes = lessonMinutes
                        student.lessonWeekday = lessonWeekday
                        student.lessonTime = lessonTime
                        context.insert(student)
                        dismiss()
                        student.level = Student.level(forGrade: student.grade)
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
