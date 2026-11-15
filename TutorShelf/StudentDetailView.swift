import SwiftUI

struct StudentDetailView: View {
    let student: Student
    @State private var showingAddLesson = false

    var body: some View {
        List {
            Section {
                NavigationLink("Monthly report") {
                    ReportView(student: student)
                }
            }
            Section("Lessons") {
                ForEach(student.lessons.sorted { $0.date > $1.date }) { lesson in
                    NavigationLink {
                        EditLessonView(lesson: lesson)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(lesson.topic).font(.headline)
                                if !lesson.shareWithParents {
                                    Image(systemName: "lock")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(lesson.rating)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Text(lesson.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(lesson.note)
                        }
                    }
                }
            }
            Section("Basics") {
                LabeledContent("Grade", value: student.grade)
                LabeledContent("Subjects", value: student.subjects)
            }
            Section("Strengths") { Text(student.strengths) }
            Section("Focus areas") { Text(student.focusAreas) }
            Section("Interests") { Text(student.interests) }
            Section("Learning style") { Text(student.learningStyle) }
            Section("Notes") { Text(student.notes) }
        }
        .navigationTitle(student.name)
        .toolbar {
            Button("Add lesson", systemImage: "square.and.pencil") {
                showingAddLesson = true
            }
        }
        .sheet(isPresented: $showingAddLesson) {
            AddLessonView(student: student)
        }
    }
}
