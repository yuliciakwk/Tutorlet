import SwiftUI

struct SubjectsView: View {
    let student: Student
    @State private var showingAddTrack = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(student.tracks) { track in
                    NavigationLink {
                        TrackView(track: track)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(track.name).font(.rounded(.headline, .heavy))
                            if let next = track.nextTopic {
                                Text("\(track.kind) · Next: \(next.title)")
                                    .font(.rounded(.subheadline, .medium))
                                    .foregroundStyle(Theme.secondaryText)
                            } else {
                                Text(track.kind)
                                    .font(.rounded(.subheadline, .medium))
                                    .foregroundStyle(Theme.secondaryText)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .card()
                    }
                    .buttonStyle(.plain)
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
