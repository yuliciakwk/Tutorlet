import SwiftUI
import QuickLook

struct ReportView: View {
    let student: Student
    @State private var month = Date()
    @State private var previewURL: URL?
    @State private var showingDetails = false

    @AppStorage("tutorName") private var tutorName = ""
    @AppStorage("tutorEmail") private var tutorEmail = ""
    @AppStorage("tutorPhone") private var tutorPhone = ""

    var monthTitle: String {
        month.formatted(.dateTime.month(.wide).year())
    }
    
    var monthKey: String {
        month.formatted(.iso8601.year().month())
    }

    var overview: Binding<String> {
        Binding(
            get: { student.reportOverviews[monthKey] ?? "" },
            set: { student.reportOverviews[monthKey] = $0 }
        )
    }

    var lessons: [Lesson] {
        student.lessons
            .filter { lesson in
                lesson.shareWithParents && !lesson.isPlanned &&
                Calendar.current.isDate(lesson.date, equalTo: month, toGranularity: .month)
            }
            .sorted { $0.date < $1.date }
    }

    var lookingAhead: [String] {
        student.tracks.flatMap { track in
            track.topics
                .filter { $0.status != "Mastered" }
                .sorted { $0.order < $1.order }
                .prefix(2)
                .map { "\(track.name): \($0.title)" }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Button {
                        changeMonth(by: -1)
                    } label: {
                        Image(systemName: "chevron.left")
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Previous month")
                    Spacer()
                    Text(monthTitle)
                        .font(.rounded(.headline, .heavy))
                    Spacer()
                    Button {
                        changeMonth(by: 1)
                    } label: {
                        Image(systemName: "chevron.right")
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Next month")
                }
                .padding(.horizontal, 8)
                .background(Theme.color(for: student), in: RoundedRectangle(cornerRadius: 22, style: .continuous))

                Text("Overview for parents")
                    .font(.rounded(.headline, .heavy))
                TextEditor(text: overview)
                    .font(.rounded(.body))
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 140)
                    .padding(10)
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                Text("\(lessons.count) shared lesson notes this month. To change a note, edit the lesson.")
                    .font(.rounded(.footnote, .medium))
                    .foregroundStyle(Theme.secondaryText)

                if tutorName.isEmpty {
                    Button {
                        showingDetails = true
                    } label: {
                        Text("Add your name and contact details").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }

                Button {
                    previewURL = renderPDF()
                } label: {
                    Text("Preview and share PDF").frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(20)
        }
        .background(Theme.background)
        .foregroundStyle(Theme.ink)
        .navigationTitle("Monthly report")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Your details", systemImage: "person.crop.circle") {
                showingDetails = true
            }
        }
        .sheet(isPresented: $showingDetails) {
            TutorDetailsView()
        }
        .quickLookPreview($previewURL)
    }

    func changeMonth(by amount: Int) {
        month = Calendar.current.date(byAdding: .month, value: amount, to: month) ?? month
    }

    func renderPDF() -> URL {
        let page = ReportPage(student: student, monthTitle: monthTitle, overview: overview.wrappedValue,
                              lessons: lessons, lookingAhead: lookingAhead,
                              tutorName: tutorName, tutorEmail: tutorEmail, tutorPhone: tutorPhone)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(student.name) \(monthTitle) report.pdf")

        let renderer = ImageRenderer(content: page)
        renderer.render { size, draw in
            var box = CGRect(origin: .zero, size: size)
            guard let pdf = CGContext(url as CFURL, mediaBox: &box, nil) else { return }
            pdf.beginPDFPage(nil)
            draw(pdf)
            pdf.endPDFPage()
            pdf.closePDF()
        }
        return url
    }
}
