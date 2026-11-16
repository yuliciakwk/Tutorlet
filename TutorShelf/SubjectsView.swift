import SwiftUI

struct SubjectsView: View {
    let student: Student
    @State private var showingAddTrack = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if student.tracks.isEmpty {
                    Text("Add a subject to build its roadmap.")
                        .font(.rounded(.subheadline, .medium))
                        .foregroundStyle(Theme.secondaryText)
                }
                ForEach(student.tracks) { track in
                    TrackCard(track: track)
                }
                Button {
                    showingAddTrack = true
                } label: {
                    Text("Add subject").frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(20)
        }
        .background(Theme.background)
        .foregroundStyle(Theme.ink)
        .navigationTitle("Roadmap")
        .sheet(isPresented: $showingAddTrack) {
            AddTrackView(student: student)
        }
    }
}

struct TrackCard: View {
    let track: Track
    @State private var newTopic = ""
    @State private var drafting = false
    @State private var errorMessage: String?

    let statuses = ["Not started", "In progress", "Mastered", "Needs review"]

    var sortedTopics: [Topic] {
        track.topics.sorted { $0.order < $1.order }
    }

    var masteredCount: Int {
        track.topics.filter { $0.status == "Mastered" }.count
    }

    var progress: Double {
        track.topics.isEmpty ? 0 : Double(masteredCount) / Double(track.topics.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(track.name)
                    .font(.rounded(.title3, .heavy))
                Text("\(track.kind) · \(masteredCount) of \(track.topics.count) mastered")
                    .font(.rounded(.subheadline, .medium))
                    .foregroundStyle(Theme.secondaryText)
                if track.kind == "Goal" && !track.goal.isEmpty {
                    Text(track.goal)
                        .font(.rounded(.subheadline, .medium))
                }
                ProgressView(value: progress)
                    .tint(Theme.ink)
                    .padding(.top, 6)
            }

            VStack(spacing: 0) {
                ForEach(sortedTopics) { topic in
                    HStack(spacing: 8) {
                        Text(topic.title)
                            .font(.rounded(.body, .bold))
                        if track.nextTopic === topic {
                            Text("Up next")
                                .font(.rounded(.caption, .bold))
                                .foregroundStyle(Theme.secondaryText)
                        }
                        Spacer()
                        Menu {
                            ForEach(statuses, id: \.self) { status in
                                Button(status) { topic.status = status }
                            }
                        } label: {
                            Text(topic.status)
                                .font(.rounded(.caption, .bold))
                                .foregroundStyle(Theme.ink)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(statusColor(topic.status), in: Capsule())
                        }
                    }
                    .padding(.vertical, 12)

                    if topic.id != sortedTopics.last?.id {
                        Divider()
                    }
                }
            }

            HStack {
                TextField("Add a topic", text: $newTopic)
                    .font(.rounded(.body))
                Button("Add") {
                    track.topics.append(Topic(title: newTopic, order: track.topics.count))
                    newTopic = ""
                }
                .font(.rounded(.body, .bold))
                .disabled(newTopic.isEmpty)
            }
            .padding(12)
            .background(Theme.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            Button {
                Task { await draftTopics() }
            } label: {
                HStack(spacing: 8) {
                    if drafting { ProgressView() }
                    Text(drafting ? "Drafting…" : "Draft topics with AI")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(drafting)

            if let errorMessage {
                Text(errorMessage)
                    .font(.rounded(.footnote, .medium))
                    .foregroundStyle(.red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }
    
    func draftTopics() async {
        guard let student = track.student else { return }
        drafting = true
        errorMessage = nil
        defer { drafting = false }

        let existing = sortedTopics.map { $0.title }.joined(separator: ", ")
        let prompt = """
        Grade: \(student.grade)
        Subject: \(track.name) (\(track.kind))
        Goal: \(track.goal.isEmpty ? "none given" : track.goal)
        Strengths: \(student.strengths)
        Focus areas: \(student.focusAreas)
        Topics already in the roadmap: \(existing.isEmpty ? "none" : existing)

        Suggest the next 6 topics for this roadmap, in teaching order.
        """

        do {
            let text = try await ClaudeClient.ask(
                system: "You are an experienced tutor planning lessons for one private student. Reply with only topic names, one per line, with no numbering, bullets or extra text. Keep each under 6 words.",
                prompt: prompt
            )
            let titles = text
                .split(separator: "\n")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            for title in titles {
                track.topics.append(Topic(title: title, order: track.topics.count))
            }
        } catch {
            errorMessage = "Couldn't draft topics. Check your connection and API key."
            print(error)
        }
    }
    
    func statusColor(_ status: String) -> Color {
        switch status {
        case "Mastered":
            return Theme.studentColors["mint"] ?? Theme.card
        case "In progress":
            return Theme.studentColors["lavender"] ?? Theme.card
        case "Needs review":
            return Color(hex: 0xFBEBCF)
        default:
            return Theme.background
        }
    }
}
