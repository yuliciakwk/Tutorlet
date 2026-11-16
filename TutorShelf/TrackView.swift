import SwiftUI

struct TrackView: View {
    let track: Track
    @State private var newTopic = ""

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
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(track.kind) · \(masteredCount) of \(track.topics.count) mastered")
                        .font(.rounded(.subheadline, .medium))
                        .foregroundStyle(Theme.secondaryText)
                    if track.kind == "Goal" && !track.goal.isEmpty {
                        Text(track.goal)
                            .font(.rounded(.body, .medium))
                    }
                    ProgressView(value: progress)
                        .tint(Theme.ink)
                        .padding(.top, 6)
                }

                VStack(spacing: 10) {
                    ForEach(sortedTopics) { topic in
                        HStack {
                            Text(topic.title)
                                .font(.rounded(.body, .bold))
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
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                        .background(Theme.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(Theme.ink, lineWidth: track.nextTopic === topic ? 2 : 0)
                        )
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
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
            .padding(20)
        }
        .background(Theme.background)
        .foregroundStyle(Theme.ink)
        .navigationTitle(track.name)
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
