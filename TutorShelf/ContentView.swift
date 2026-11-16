import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Query(sort: \Student.name) private var students: [Student]
    @State private var showingAdd = false
    @State private var selected: Student?

    var body: some View {
        if sizeClass == .compact {
            NavigationStack {
                studentList
            }
        } else {
            HStack(spacing: 0) {
                NavigationStack {
                    studentList
                }
                .frame(width: 340)

                NavigationStack {
                    if let selected {
                        StudentDetailView(student: selected)
                    } else {
                        ContentUnavailableView("Choose a student",
                            systemImage: "person.crop.circle",
                            description: Text("Pick a card to see their lessons and worksheets."))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)   // new
                            .background(Theme.background)
                    }
                }
                .id(selected.map { ObjectIdentifier($0) })
            }
        }
    }

    var studentList: some View {
        ScrollView {
            VStack(spacing: 14) {
                if students.isEmpty {
                    Text("Add your first student with the + button.")
                        .font(.rounded(.subheadline, .medium))
                        .foregroundStyle(Theme.secondaryText)
                        .padding(.top, 40)
                }
                ForEach(students) { student in
                    card(for: student)
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button("Delete", systemImage: "trash", role: .destructive) {
                                if selected === student { selected = nil }
                                context.delete(student)
                            }
                        }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(20)
        }
        .background(sizeClass == .compact ? Theme.background : Theme.sidebar)
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

    @ViewBuilder
    func card(for student: Student) -> some View {
        if sizeClass == .compact {
            NavigationLink {
                StudentDetailView(student: student)
            } label: {
                StudentCard(student: student)
            }
        } else {
            Button {
                selected = student
            } label: {
                StudentCard(student: student)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Theme.ink, lineWidth: selected === student ? 3 : 0)
                    )
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
                        .font(.rounded(.title2, .heavy))
                    Text("\(student.grade) · \(student.format)")
                        .font(.rounded(.subheadline, .medium))
                        .foregroundStyle(Theme.secondaryText)
                }
                Spacer()
                if let nextLesson {
                    Text(nextLesson.date.formatted(.dateTime.weekday(.abbreviated).hour().minute()))
                        .font(.rounded(.caption, .bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.white, in: Capsule())
                }
            }

            HStack {
                if let nextLesson {
                    Text(nextLesson.topic)
                        .font(.rounded(.body, .bold))
                    Spacer()
                    Text(nextLesson.worksheets.isEmpty ? "No worksheet yet" : "Worksheet ready")
                        .font(.rounded(.caption, .bold))
                        .foregroundStyle(Theme.secondaryText)
                } else {
                    Text("No lesson planned")
                        .font(.rounded(.body, .medium))
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
