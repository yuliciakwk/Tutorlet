import SwiftUI

struct AddTrackView: View {
    @Environment(\.dismiss) private var dismiss
    let student: Student

    @State private var name = ""
    @State private var kind = "Curriculum"
    @State private var goal = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Subject, like Math or Phonics", text: $name)

                Picker("Type", selection: $kind) {
                    Text("Curriculum").tag("Curriculum")
                    Text("Goal").tag("Goal")
                }
                .pickerStyle(.segmented)

                if kind == "Goal" {
                    TextField("What are they working toward?", text: $goal, axis: .vertical)
                }
            }
            .font(.rounded(.body))
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("New subject")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        student.tracks.append(Track(name: name, kind: kind, goal: goal))
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
