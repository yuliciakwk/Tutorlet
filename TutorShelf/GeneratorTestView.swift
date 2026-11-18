import SwiftUI
import PDFKit

// Temporary test screen for the generator. Step 3 replaces it with the real button.
struct GeneratorTestView: View {
    let student: Student

    @State private var status = ""
    @State private var working = false
    @State private var pdf: Data?
    @State private var pack: GeneratedPack?

    var nextLesson: Lesson? {
        student.lessons
            .filter { $0.isPlanned }
            .sorted { $0.date < $1.date }
            .first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let lesson = nextLesson {
                Text("Next lesson: \(lesson.topic)")
                    .font(.rounded(.headline))
                Text("Style: \(student.worksheetStyle) · Level: \(student.level)")
                    .font(.rounded(.subheadline))
                    .foregroundStyle(Theme.secondaryText)

                Button {
                    Task { await generate(for: lesson) }
                } label: {
                    Text(working ? "Working…" : (pdf == nil ? "Generate pack" : "Redo"))
                        .padding(.horizontal, 20)
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 4)
                .disabled(working)
            } else {
                Text("Plan a lesson for this student first.")
                    .font(.rounded(.body))
            }

            if !status.isEmpty {
                HStack(spacing: 8) {
                    if working { ProgressView() }
                    Text(status).font(.rounded(.subheadline))
                }
            }

            if let pack {
                Text("\(pack.title) · \(pack.pages.count) pages\(pack.defaultTheme == true ? " · default theme (add interests for a tailored one)" : "")")
                    .font(.rounded(.caption))
                    .foregroundStyle(Theme.secondaryText)
            }

            if let pdf {
                PDFPreview(data: pdf)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                Spacer()
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.background)
        .navigationTitle("Test AI pack")
    }

    private func generate(for lesson: Lesson) async {
        working = true
        defer { working = false }
        do {
            let result = try await WorksheetGenerator.makePDF(student: student, lesson: lesson) { message in
                status = message
            }
            pack = result.pack
            pdf = result.pdf
            status = "Done"
        } catch {
            status = "Didn't work: \(error.localizedDescription)"
        }
    }
}

// Shows a PDF inside SwiftUI using Apple's PDFKit viewer.
struct PDFPreview: UIViewRepresentable {
    let data: Data

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ view: PDFView, context: Context) {
        view.document = PDFDocument(data: data)
    }
}
