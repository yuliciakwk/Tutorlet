import SwiftUI

struct TutorDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("tutorName") private var tutorName = ""
    @AppStorage("tutorEmail") private var tutorEmail = ""
    @AppStorage("tutorPhone") private var tutorPhone = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Your name", text: $tutorName)
                        .textContentType(.name)
                    TextField("Email", text: $tutorEmail)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    TextField("Phone", text: $tutorPhone)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                } footer: {
                    Text("Shown at the bottom of every report.")
                }
            }
            .font(.rounded(.body))
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Your details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Done") { dismiss() }
            }
        }
    }
}
