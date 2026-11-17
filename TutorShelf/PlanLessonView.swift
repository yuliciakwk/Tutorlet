import SwiftUI

struct PlanLessonView: View {
    @Environment(\.dismiss) private var dismiss
    let student: Student

    @State private var date = Date()
    @State private var chosen: Topic?
    @State private var customTopic = ""
    @State private var focus = ""

    var roadmapTopics: [Topic] {
        student.tracks.flatMap { track in
            track.topics.sorted { $0.order < $1.order }
        }
    }

    var suggested: Topic? {
        student.tracks.compactMap { $0.nextTopic }.first
    }

    var lastLesson: Lesson? {
        student.lessons
            .filter { !$0.isPlanned }
            .sorted { $0.date > $1.date }
            .first
    }

    var topicTitle: String {
        customTopic.isEmpty ? (chosen?.title ?? "") : customTopic
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if let suggested {
                        suggestionCard(suggested)
                    }
                    if let lastLesson {
                        lastLessonCard(lastLesson)
                    }
                    topicPicker
                    whenCard
                }
                .padding(20)
            }
            .background(Theme.background)
            .foregroundStyle(Theme.ink)
            .navigationTitle("Plan for \(student.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(topicTitle.isEmpty)
                }
            }
            .onAppear {
                chosen = suggested
                if let regular = student.nextRegularLesson {
                    date = regular
                }
            }
            .onChange(of: customTopic) {
                if !customTopic.isEmpty { chosen = nil }
            }
        }
    }

    func suggestionCard(_ topic: Topic) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Suggested next")
                .font(.rounded(.caption, .bold))
                .foregroundStyle(Theme.secondaryText)
            Text(topic.title)
                .font(.rounded(.title2, .heavy))
            Text(reason(for: topic))
                .font(.rounded(.subheadline, .medium))
                .foregroundStyle(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(Theme.color(for: student))
    }

    func reason(for topic: Topic) -> String {
        switch topic.status {
        case "Needs review":
            let taught = topic.lessons
                .filter { !$0.isPlanned }
                .sorted { $0.date > $1.date }
            if let last = taught.first {
                return "Needs review: \(last.rating.lowercased()) on \(last.date.formatted(.dateTime.month(.abbreviated).day()))"
            }
            return "Flagged for review"
        case "In progress":
            return "Still in progress from last time"
        default:
            return "Next on the roadmap"
        }
    }

    func lastLessonCard(_ lesson: Lesson) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Last lesson")
                Spacer()
                Text(lesson.date.formatted(.dateTime.month(.abbreviated).day()))
            }
            .font(.rounded(.caption, .bold))
            .foregroundStyle(Theme.secondaryText)

            Text("\(lesson.topic) · \(lesson.rating)")
                .font(.rounded(.headline, .bold))

            if !lesson.note.isEmpty {
                Text(lesson.note)
                    .font(.rounded(.subheadline))
                    .foregroundStyle(Theme.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    var topicPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Topic")
                .font(.rounded(.headline, .heavy))

            if !roadmapTopics.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(roadmapTopics) { topic in
                            Button {
                                chosen = topic
                                customTopic = ""
                            } label: {
                                HStack(spacing: 4) {
                                    if topic.status == "Needs review" {
                                        Image(systemName: "arrow.uturn.backward")
                                    }
                                    Text(topic.title)
                                }
                                .font(.rounded(.subheadline, .bold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .foregroundStyle(chosen === topic ? Color.white : Theme.ink)
                                .background(chosen === topic ? Theme.ink : Theme.card, in: Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            TextField("Or type your own topic", text: $customTopic)
                .font(.rounded(.body))
                .padding(14)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            TextField("Focus for this lesson (optional), like \"test on Friday, pages 112–130\"",
                      text: $focus, axis: .vertical)
                .font(.rounded(.body))
                .padding(14)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    var whenCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("When")
                .font(.rounded(.headline, .heavy))
            DatePicker("Date and time", selection: $date)
                .font(.rounded(.body))
            Text("\(student.lessonMinutes) min · \(student.format == "Online" ? "Slides" : "Printable worksheet")")
                .font(.rounded(.subheadline, .medium))
                .foregroundStyle(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    func save() {
        let lesson = Lesson(date: date, topic: topicTitle)
        lesson.isPlanned = true
        lesson.rating = ""
        lesson.focus = focus
        student.lessons.append(lesson)
        lesson.roadmapTopic = customTopic.isEmpty ? chosen : nil
        dismiss()
    }
}
