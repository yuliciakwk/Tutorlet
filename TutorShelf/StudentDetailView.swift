import SwiftUI
import QuickLook
import UniformTypeIdentifiers

struct StudentDetailView: View {
    let student: Student
    @State private var showingAddLesson = false
    @State private var showingPlanLesson = false
    @State private var showingImporter = false
    @State private var previewURL: URL?

    var nextLesson: Lesson? {
        student.lessons
            .filter { $0.isPlanned }
            .sorted { $0.date < $1.date }
            .first
    }

    var pastLessons: [Lesson] {
        student.lessons
            .filter { !$0.isPlanned }
            .sorted { $0.date > $1.date }
    }

    var tailoredTo: String {
        [student.learningStyle, student.interests]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                nextLessonCard
                shortcuts
                pastLessonsSection
            }
            .padding(20)
        }
        .background(Theme.background)
        .foregroundStyle(Theme.ink)
        .navigationTitle(student.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            NavigationLink {
                EditStudentView(student: student)
            } label: {
                Label("Edit profile", systemImage: "pencil")
            }
            Button("Plan lesson", systemImage: "calendar.badge.plus") {
                showingPlanLesson = true
            }
        }
        .sheet(isPresented: $showingPlanLesson) {
            PlanLessonView(student: student)
        }
        .sheet(isPresented: $showingAddLesson) {
            AddLessonView(student: student)
        }
        .fileImporter(isPresented: $showingImporter,
                      allowedContentTypes: [.pdf, .image]) { result in
            if case .success(let url) = result, let worksheet = Worksheet.load(from: url) {
                student.worksheets.append(worksheet)
                worksheet.lesson = nextLesson
            }
        }
        .quickLookPreview($previewURL)
    }

    var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(student.name)
                .font(.rounded(.largeTitle, .heavy))
            Text("\(student.grade) · \(student.subjects) · \(student.format)")
                .font(.rounded(.subheadline, .medium))
                .foregroundStyle(Theme.secondaryText)
            if !tailoredTo.isEmpty {
                Text("Tailored to: \(tailoredTo)")
                    .font(.rounded(.footnote, .medium))
                    .foregroundStyle(Theme.secondaryText)
                    .padding(.top, 4)
            }
            if student.interests.isEmpty || student.learningStyle.isEmpty {
                NavigationLink {
                    EditStudentView(student: student)
                } label: {
                    Label("Add interests and learning style to personalise worksheets", systemImage: "sparkles")
                        .font(.rounded(.footnote, .bold))
                }
                .buttonStyle(.plain)
                .padding(.top, 6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(Theme.color(for: student))
    }

    var nextLessonCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let lesson = nextLesson {
                HStack {
                    Text("Next lesson")
                    Spacer()
                    Text(lesson.date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().hour().minute()))
                }
                .font(.rounded(.caption, .bold))
                .foregroundStyle(Theme.secondaryText)

                Text(lesson.topic)
                    .font(.rounded(.title2, .heavy))

                if let worksheet = lesson.worksheets.first {
                    Button {
                        previewURL = worksheet.temporaryURL()
                    } label: {
                        Text(student.format == "Online" ? "Open slides" : "Open worksheet")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                } else {
                    Button {
                        showingImporter = true
                    } label: {
                        Text("Attach worksheet").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }

                NavigationLink {
                    EditLessonView(lesson: lesson)
                } label: {
                    Text("Write note").frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle())
            } else {
                Text("No lesson planned")
                    .font(.rounded(.title3, .bold))
                Button {
                    showingPlanLesson = true
                } label: {
                    Text("Plan next lesson").frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    var shortcuts: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            NavigationLink {
                SubjectsView(student: student)
            } label: {
                shortcut("Roadmap", icon: "map")
            }
            NavigationLink {
                WorksheetsView(student: student)
            } label: {
                shortcut("Worksheets", icon: "doc.on.doc")
            }
            NavigationLink {
                ReportView(student: student)
            } label: {
                shortcut("Monthly report", icon: "envelope")
            }
            Button {
                showingAddLesson = true
            } label: {
                shortcut("Log a lesson", icon: "square.and.pencil")
            }
        }
        .buttonStyle(.plain)
    }

    func shortcut(_ title: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon).font(.title3)
            Text(title).font(.rounded(.headline, .bold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    var pastLessonsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Past lessons")
                .font(.rounded(.headline, .heavy))

            if pastLessons.isEmpty {
                Text("Notes you write after lessons will appear here.")
                    .font(.rounded(.subheadline, .medium))
                    .foregroundStyle(Theme.secondaryText)
            } else {
                VStack(spacing: 0) {
                    ForEach(pastLessons) { lesson in
                        NavigationLink {
                            EditLessonView(lesson: lesson)
                        } label: {
                            HStack(spacing: 12) {
                                Text(lesson.date.formatted(.dateTime.month(.abbreviated).day()))
                                    .font(.rounded(.caption, .bold))
                                    .foregroundStyle(Theme.secondaryText)
                                    .frame(width: 52, alignment: .leading)
                                Text(lesson.topic)
                                    .font(.rounded(.body, .bold))
                                if !lesson.shareWithParents {
                                    Image(systemName: "lock").font(.caption)
                                }
                                Spacer()
                                if !lesson.worksheets.isEmpty {
                                    Label("\(lesson.worksheets.count)", systemImage: "paperclip")
                                        .font(.caption)
                                }
                                Text(lesson.rating)
                                    .font(.rounded(.caption, .medium))
                                    .foregroundStyle(Theme.secondaryText)
                            }
                            .padding(.vertical, 14)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if lesson.id != pastLessons.last?.id {
                            Divider()
                        }
                    }
                }
                .padding(.horizontal, 18)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
        }
    }
}
