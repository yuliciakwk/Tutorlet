import SwiftUI
import PDFKit

// Plan → tutor checks it → pages are written → preview → save to the lesson.
struct GenerateWorksheetView: View {
    let lesson: Lesson
    @Environment(\.dismiss) private var dismiss

    enum Stage { case planning, plan, writing, preview, failed }

    @State private var stage: Stage = .planning
    @State private var plan: PackPlan?
    @State private var changes = ""
    @State private var status = ""
    @State private var errorMessage = ""
    @State private var retry: (() async -> Void)?
    @State private var pack: GeneratedPack?
    @State private var pdf: Data?

    let styles = ["Classic", "Cozy", "Game"]

    var body: some View {
        NavigationStack {
            Group {
                switch stage {
                case .planning: waiting("Planning the lesson…", hint: "About 15 seconds")
                case .plan: planCard
                case .writing: waiting(status, hint: "Usually about a minute. Each part is written at the same time.")
                case .preview: previewScreen
                case .failed: failedScreen
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Theme.background)
            .foregroundStyle(Theme.ink)
            .navigationTitle(lesson.topic)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .task {
            if plan == nil { await makePlan() }
        }
    }

    // MARK: - Screens

    func waiting(_ message: String, hint: String) -> some View {
        VStack(spacing: 14) {
            ProgressView().controlSize(.large)
            Text(message).font(.rounded(.headline, .bold))
            Text(hint)
                .font(.rounded(.subheadline, .medium))
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 120)
        .padding(.horizontal, 30)
    }

    var planCard: some View {
        ScrollView {
            if let plan, let student = lesson.student {
                VStack(alignment: .leading, spacing: 18) {
                    // Title and style
                    VStack(alignment: .leading, spacing: 10) {
                        Text("The plan").font(.rounded(.caption, .bold)).foregroundStyle(Theme.secondaryText)
                        Text(plan.title).font(.rounded(.title, .heavy))
                        if let subtitle = plan.subtitle {
                            Text(subtitle).font(.rounded(.subheadline, .medium)).foregroundStyle(Theme.secondaryText)
                        }
                        Picker("Style", selection: Binding(
                            get: { student.worksheetStyle },
                            set: { newStyle in
                                student.worksheetStyle = newStyle
                                Task { await makePlan() }      // a new style needs a new plan
                            })) {
                            ForEach(styles, id: \.self) { Text($0) }
                        }
                        .pickerStyle(.segmented)
                        .padding(.top, 4)

                        if plan.defaultTheme == true {
                            Label("Using a general theme. Add interests in Edit profile for a tailored one.",
                                  systemImage: "sparkles")
                                .font(.rounded(.footnote, .medium))
                                .foregroundStyle(Theme.secondaryText)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .card()

                    // Parts
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(plan.parts.enumerated()), id: \.offset) { index, part in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(index + 1)")
                                    .font(.rounded(.caption, .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 26, height: 26)
                                    .background(Theme.ink, in: Circle())
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack {
                                        Text("\(plan.partLabel ?? "Part") \(index + 1) · \(part.title)")
                                            .font(.rounded(.body, .bold))
                                        Spacer()
                                        if let minutes = part.minutes {
                                            Text("\(minutes) min")
                                                .font(.rounded(.caption, .bold))
                                                .foregroundStyle(Theme.secondaryText)
                                        }
                                    }
                                    if let summary = part.summary {
                                        Text(summary)
                                            .font(.rounded(.subheadline, .medium))
                                            .foregroundStyle(Theme.secondaryText)
                                    }
                                }
                            }
                            .padding(.vertical, 12)
                            if index < plan.parts.count - 1 { Divider().padding(.leading, 38) }
                        }
                        if let certificate = plan.certificate, !certificate.isEmpty {
                            Divider().padding(.leading, 38)
                            Label("Certificate: \(certificate)", systemImage: "rosette")
                                .font(.rounded(.subheadline, .bold))
                                .padding(.vertical, 12)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .card()

                    // Changes
                    VStack(alignment: .leading, spacing: 10) {
                        TextField("Ask for changes, like \"no timer\" or \"make part 3 about making change\"",
                                  text: $changes, axis: .vertical)
                            .font(.rounded(.body))
                            .padding(14)
                            .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                        if !changes.trimmingCharacters(in: .whitespaces).isEmpty {
                            Button {
                                Task { await makePlan(changing: plan) }
                            } label: {
                                Text("Update plan").frame(maxWidth: .infinity)
                            }
                            .buttonStyle(SecondaryButtonStyle())
                        }

                        Button {
                            Task { await writePages(plan) }
                        } label: {
                            Text("Looks good, write it").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                }
                .padding(20)
            }
        }
    }

    var previewScreen: some View {
        VStack(spacing: 12) {
            if let pdf {
                PDFPreview(data: pdf)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            HStack(spacing: 12) {
                Button {
                    stage = .plan
                } label: {
                    Text("Change plan").frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle())

                if let plan {
                    Button {
                        Task { await writePages(plan) }
                    } label: {
                        Text("Rewrite pages").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
            Button(action: save) {
                Text("Save to lesson").frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(20)
    }

    var failedScreen: some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle").font(.largeTitle)
            Text("That didn't work").font(.rounded(.title3, .bold))
            Text(errorMessage)
                .font(.rounded(.subheadline, .medium))
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.center)
            Button {
                Task { await retry?() }
            } label: {
                Text("Try again").padding(.horizontal, 20)
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(.top, 100)
        .padding(.horizontal, 30)
    }

    // MARK: - Actions

    func makePlan(changing previous: PackPlan? = nil) async {
        guard let student = lesson.student else { return }
        stage = .planning
        do {
            plan = try await WorksheetGenerator.plan(student: student, lesson: lesson,
                                                     previous: previous, changes: changes)
            changes = ""
            stage = .plan
        } catch {
            fail(error) { await makePlan(changing: previous) }
        }
    }

    func writePages(_ plan: PackPlan) async {
        guard let student = lesson.student else { return }
        stage = .writing
        status = "Writing the pages…"
        do {
            let result = try await WorksheetGenerator.write(plan: plan, student: student, lesson: lesson) { message in
                status = message
            }
            pack = result.pack
            pdf = result.pdf
            stage = .preview
        } catch {
            fail(error) { await writePages(plan) }
        }
    }

    func fail(_ error: Error, retry action: @escaping () async -> Void) {
        errorMessage = error.localizedDescription
        retry = action
        stage = .failed
    }

    func save() {
        guard let student = lesson.student, let pack, let pdf else { return }
        let worksheet = Worksheet(title: pack.plan.title, fileData: pdf)
        worksheet.content = try? JSONEncoder().encode(pack)
        student.worksheets.append(worksheet)
        worksheet.lesson = lesson
        dismiss()
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
