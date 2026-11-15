import SwiftUI

struct ReportView: View {
    let student: Student
    @State private var month = Date()
    @State private var draft = ""

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button("Previous", systemImage: "chevron.left") { changeMonth(by: -1) }
                    .labelStyle(.iconOnly)
                Spacer()
                Text(month.formatted(.dateTime.month(.wide).year()))
                    .font(.headline)
                Spacer()
                Button("Next", systemImage: "chevron.right") { changeMonth(by: 1) }
                    .labelStyle(.iconOnly)
            }

            TextEditor(text: $draft)
                .padding(8)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.quaternary))

            ShareLink("Share report", item: draft)
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .navigationTitle("Monthly report")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { buildDraft() }
    }

    func changeMonth(by amount: Int) {
        month = Calendar.current.date(byAdding: .month, value: amount, to: month) ?? month
        buildDraft()
    }

    func buildDraft() {
        let lessons = student.lessons
            .filter { lesson in
                lesson.shareWithParents &&
                Calendar.current.isDate(lesson.date, equalTo: month, toGranularity: .month)
            }
            .sorted { $0.date < $1.date }

        var text = "\(student.name): \(month.formatted(.dateTime.month(.wide).year())) report\n\n"

        if lessons.isEmpty {
            text += "No shared lesson notes this month.\n\n"
        }
        for lesson in lessons {
            let day = lesson.date.formatted(date: .abbreviated, time: .omitted)
            text += "\(day): \(lesson.topic)\n\(lesson.note)\n\n"
        }

        text += "Overall:\n"
        draft = text
    }
}
