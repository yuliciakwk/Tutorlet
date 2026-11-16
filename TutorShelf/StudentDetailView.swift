import SwiftUI
import QuickLook
import UniformTypeIdentifiers

struct StudentDetailView: View {
    let student: Student
    @State private var showingAddLesson = false
    @State private var showingPlanLesson = false
    @State private var showingImporter = false
    @State private var previewURL: URL?
    @State private var showingAddTrack = false

    var body: some View {
        List {
            Section {
                NavigationLink("Monthly report") {
                    ReportView(student: student)
                }
            }
            Section("Subjects") {
                ForEach(student.tracks) { track in
                    NavigationLink {
                        TrackView(track: track)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(track.name).font(.headline)
                            if let next = track.nextTopic {
                                Text("\(track.kind) · Next: \(next.title)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text(track.kind)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                Button("Add subject", systemImage: "plus") {
                    showingAddTrack = true
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
                                Text(lesson.isPlanned ? "Planned" : lesson.rating)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Text(lesson.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(lesson.note)
                            if !lesson.worksheets.isEmpty {
                                Label("\(lesson.worksheets.count)", systemImage: "paperclip")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            Section("Worksheets") {
                ForEach(student.worksheets.sorted { $0.addedOn > $1.addedOn }) { worksheet in
                    Button {
                        open(worksheet)
                    } label: {
                        Label(worksheet.title, systemImage: "doc")
                    }
                }
                Button("Add worksheet", systemImage: "plus") {
                    showingImporter = true
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
            Button("Plan lesson", systemImage: "calendar.badge.plus") {
                showingPlanLesson = true
            }
            Button("Add lesson", systemImage: "square.and.pencil") {
                showingAddLesson = true
            }
        }
        .sheet(isPresented: $showingPlanLesson) {
            PlanLessonView(student: student)
        }
        .sheet(isPresented: $showingAddLesson) {
            AddLessonView(student: student)
        }
        .sheet(isPresented: $showingAddTrack) {
            AddTrackView(student: student)
        }
        .fileImporter(isPresented: $showingImporter,
                      allowedContentTypes: [.pdf, .image]) { result in
            if case .success(let url) = result {
                importFile(url)
            }
        }
        .quickLookPreview($previewURL)
    }

    func importFile(_ url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        guard let data = try? Data(contentsOf: url) else { return }
        let worksheet = Worksheet(title: url.lastPathComponent, fileData: data)
        student.worksheets.append(worksheet)
    }

    func open(_ worksheet: Worksheet) {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(worksheet.title)
        try? worksheet.fileData.write(to: url)
        previewURL = url
    }
}
