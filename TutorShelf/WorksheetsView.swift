import SwiftUI
import QuickLook
import UniformTypeIdentifiers

struct WorksheetsView: View {
    let student: Student
    @State private var showingImporter = false
    @State private var previewURL: URL?

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(student.worksheets.sorted { $0.addedOn > $1.addedOn }) { worksheet in
                    Button {
                        previewURL = worksheet.temporaryURL()
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "doc").font(.title3)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(worksheet.title)
                                    .font(.rounded(.body, .bold))
                                    .lineLimit(1)
                                Text(worksheet.lesson?.topic ?? "Not used in a lesson yet")
                                    .font(.rounded(.caption, .medium))
                                    .foregroundStyle(Theme.secondaryText)
                            }
                            Spacer()
                        }
                        .card()
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    showingImporter = true
                } label: {
                    Text("Add worksheet").frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
                
                Button {
                    previewURL = WorksheetPDF.make(pack: .sample, style: student.worksheetStyle, grade: student.grade)
                } label: {
                    Text("Preview sample worksheet").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
            }
            .padding(20)
        }
        .background(Theme.background)
        .foregroundStyle(Theme.ink)
        .navigationTitle("Worksheets")
        .fileImporter(isPresented: $showingImporter,
                      allowedContentTypes: [.pdf, .image]) { result in
            if case .success(let url) = result, let worksheet = Worksheet.load(from: url) {
                student.worksheets.append(worksheet)
            }
        }
        .quickLookPreview($previewURL)
    }
}
