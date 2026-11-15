import SwiftUI

struct TrackView: View {
    let track: Track
    @State private var newTopic = ""

    let statuses = ["Not started", "In progress", "Mastered", "Needs review"]

    var body: some View {
        List {
            if track.kind == "Goal" && !track.goal.isEmpty {
                Section("Goal") { Text(track.goal) }
            }

            Section("Roadmap") {
                ForEach(track.topics.sorted { $0.order < $1.order }) { topic in
                    HStack {
                        Text(topic.title)
                        Spacer()
                        Menu(topic.status) {
                            ForEach(statuses, id: \.self) { status in
                                Button(status) { topic.status = status }
                            }
                        }
                        .font(.caption)
                    }
                }

                HStack {
                    TextField("Add a topic", text: $newTopic)
                    Button("Add") {
                        track.topics.append(Topic(title: newTopic, order: track.topics.count))
                        newTopic = ""
                    }
                    .disabled(newTopic.isEmpty)
                }
            }
        }
        .navigationTitle(track.name)
    }
}
