import SwiftUI

struct ReportView: View {
    let student: Student
    @State private var month = Date()
    @State private var draft = ""

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Button {
                    changeMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Previous month")

                Spacer()
                Text(month.formatted(.dateTime.month(.wide).year()))
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

            TextEditor(text: $draft)
                .font(.rounded(.body))
                .scrollContentBackground(.hidden)

                .padding(14)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))

            ShareLink(item: draft) {
                Text("Share report").frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(20)
        .background(Theme.background)
        .foregroundStyle(Theme.ink)
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
                lesson.shareWithParents && !lesson.isPlanned &&
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
