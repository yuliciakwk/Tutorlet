import SwiftUI
import SwiftData

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
    @Environment(\.modelContext) private var modelContext

    let statuses = ["Not started", "In progress", "Mastered", "Needs review"]

    var sortedTopics: [Topic] {
        track.topics.sorted { $0.order < $1.order }
    }
    
    var draftButtonTitle: String {
        if track.topics.isEmpty { return "Draft topics with AI" }
        let hasUnstarted = track.topics.contains { $0.status == "Not started" && $0.lessons.isEmpty }
        return hasUnstarted ? "Redraft unstarted topics" : "Draft next topics"
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
                        StepNumber(number: (sortedTopics.firstIndex { $0.id == topic.id } ?? 0) + 1,
                                   status: topic.status)
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
                    .contextMenu {
                        Button("Delete topic", role: .destructive) { delete(topic) }
                    }

                    if topic.id != sortedTopics.last?.id {
                        Divider().padding(.leading, 40)
                        
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
                    Text(draftButtonTitle)
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
        
        let kept = sortedTopics.filter { $0.status != "Not started" || !$0.lessons.isEmpty }
        let replaced = sortedTopics.filter { $0.status == "Not started" && $0.lessons.isEmpty }
        let keptList = kept.map { "\($0.title) (\($0.status))" }.joined(separator: ", ")
        let replacedList = replaced.map(\.title).joined(separator: ", ")
        let target = track.kind == "Curriculum" ? 12 : 8
        let remaining = max(6, target - kept.count)
        let count = "\(remaining)"

        let prompt = """
        Grade: \(student.grade)
        Subject: \(track.name) (\(track.kind))
        Goal: \(track.goal.isEmpty ? "none given" : track.goal)
        Student's strengths: \(student.strengths)
        Student's focus areas: \(student.focusAreas)
        Already started or mastered (keep these, continue after them): \(keptList.isEmpty ? "none" : keptList)
        Previous suggestions the tutor wants replaced (suggest different ones): \(replacedList.isEmpty ? "none" : replacedList)

        Write a roadmap of \(count) topics for \(track.name) only.
        - Every topic must belong to \(track.name). Strengths and focus areas may mention other subjects; ignore anything that isn't \(track.name).
        - For a curriculum, follow the BC curriculum for this grade and cover the rest of the school year.
        - For a goal, list the steps needed to reach the goal, and nothing beyond it.
        - Put them in teaching order: each topic builds on the ones before it, starting where the kept topics leave off.
        - Give extra attention to the focus areas that belong to \(track.name).
        - After every 3 or 4 new topics, add a checkpoint topic named "Review: …" that revisits what came before it.
        - If 3 or more of the kept topics come after the last "Review:" topic, start with a review of those kept topics before anything new.
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
            removeUnstartedTopics()
            for title in titles {
                track.topics.append(Topic(title: title, order: track.topics.count))
            }
        } catch {
            errorMessage = "Couldn't draft topics. Check your connection and API key."
            print(error)
        }
    }
    
    private func delete(_ topic: Topic) {
        track.topics.removeAll { $0 === topic }
        modelContext.delete(topic)
        renumber()
    }
    
    private func removeUnstartedTopics() {
        let unstarted = track.topics.filter { $0.status == "Not started" && $0.lessons.isEmpty }
        for topic in unstarted {
            track.topics.removeAll { $0 === topic }
            modelContext.delete(topic)
        }
        renumber()
    }

    private func renumber() {
        let sorted = track.topics.sorted { $0.order < $1.order }
        for (index, topic) in sorted.enumerated() {
            topic.order = index
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

struct StepNumber: View {
    let number: Int
    let status: String

    var body: some View {
        ZStack {
            Circle().fill(fill)
            if status == "Mastered" {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            } else {
                Text("\(number)")
                    .font(.rounded(.caption))
                    .bold()
                    .foregroundStyle(status == "Not started" ? Theme.secondaryText : .white)
            }
        }
        .frame(width: 28, height: 28)
    }

    var fill: Color {
        switch status {
        case "Mastered": Theme.ink
        case "In progress": Color(hex: 0x6C4AB6)
        case "Needs review": Color(hex: 0xE8A33D)
        default: Theme.sidebar
        }
    }
}
