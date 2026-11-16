import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Student.name) private var students: [Student]
    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(students) { student in
                        NavigationLink {
                            StudentDetailView(student: student)
                        } label: {
                            StudentCard(student: student)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button("Delete", systemImage: "trash", role: .destructive) {
                                context.delete(student)
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(Theme.background)
            .navigationTitle("Your students")
            .toolbar {
                Button("Add", systemImage: "plus") {
                    showingAdd = true
                }
                Button("Sample", systemImage: "wand.and.stars") {
                    let student = Student(name: "Sample Student", grade: "Grade 2",
                                          subjects: "English",
                                          strengths: "Math, quick thinker",
                                          focusAreas: "Reading stamina",
                                          interests: "Games, ninjas",
                                          learningStyle: "Competitive, short focus")
                    let track = Track(name: "English", kind: "Curriculum")
                    context.insert(student)
                    student.tracks.append(track)
                    let titles = ["Capital letters", "Sentence building", "Describing words", "Short stories"]
                    for (index, title) in titles.enumerated() {
                        track.topics.append(Topic(title: title, order: index))
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddStudentView()
            }
        }
    }
}

struct StudentCard: View {
    let student: Student

    var nextLesson: Lesson? {
        student.lessons
            .filter { $0.isPlanned }
            .sorted { $0.date < $1.date }
            .first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(student.name)
                        .font(.system(.title2, design: .rounded, weight: .heavy))
                    Text("\(student.grade) · \(student.format)")
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(Theme.secondaryText)
                }
                Spacer()
                if let nextLesson {
                    Text(nextLesson.date.formatted(.dateTime.weekday(.abbreviated).hour().minute()))
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.white, in: Capsule())
                }
            }

            HStack {
                if let nextLesson {
                    Text(nextLesson.topic)
                        .font(.system(.body, design: .rounded, weight: .bold))
                    Spacer()
                    Text(nextLesson.worksheets.isEmpty ? "No worksheet yet" : "Worksheet ready")
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(Theme.secondaryText)
                } else {
                    Text("No lesson planned")
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundStyle(Theme.secondaryText)
                    Spacer()
                }
            }
            .padding(14)
            .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .foregroundStyle(Theme.ink)
        .card(Theme.color(for: student))
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Student.self, inMemory: true)
}
