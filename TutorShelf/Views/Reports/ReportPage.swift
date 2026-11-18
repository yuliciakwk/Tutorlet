import SwiftUI

struct ReportPage: View {
    let student: Student
    let monthTitle: String
    let overview: String
    let lessons: [Lesson]
    let lookingAhead: [String]
    let tutorName: String
    let tutorEmail: String
    let tutorPhone: String

    let accent = Color(hex: 0x1F3A5F)
    let ink = Color(hex: 0x1C1C1E)
    let muted = Color(hex: 0x6B6B70)

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Monthly progress report")
                    .font(.system(size: 11, weight: .semibold))
                    .textCase(.uppercase)
                    .tracking(1.5)
                    .foregroundStyle(accent)
                Text(student.name)
                    .font(.system(size: 30, weight: .semibold, design: .serif))
                Text("\(monthTitle) · \(student.grade) · \(student.subjects)")
                    .font(.system(size: 12))
                    .foregroundStyle(muted)
            }

            Rectangle()
                .fill(accent)
                .frame(height: 2)

            if !overview.isEmpty {
                section("Overview") {
                    Text(overview)
                        .font(.system(size: 12))
                        .lineSpacing(3)
                }
            }

            section("Lessons this month") {
                if lessons.isEmpty {
                    Text("No lesson notes this month.")
                        .font(.system(size: 12))
                        .foregroundStyle(muted)
                }
                ForEach(lessons) { lesson in
                    HStack(alignment: .top, spacing: 16) {
                        Text(lesson.date.formatted(.dateTime.month(.abbreviated).day()))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(muted)
                            .frame(width: 52, alignment: .leading)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(lesson.topic)
                                .font(.system(size: 12, weight: .semibold))
                            Text(lesson.note)
                                .font(.system(size: 12))
                                .lineSpacing(2)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }

            if !lookingAhead.isEmpty {
                section("Looking ahead") {
                    ForEach(lookingAhead, id: \.self) { item in
                        Text("•  \(item)")
                            .font(.system(size: 12))
                    }
                }
            }

            Rectangle()
                .fill(muted.opacity(0.3))
                .frame(height: 0.5)
                .padding(.top, 8)

            HStack {
                Text(tutorName)
                    .font(.system(size: 10, weight: .semibold))
                Spacer()
                Text([tutorEmail, tutorPhone].filter { !$0.isEmpty }.joined(separator: "  ·  "))
                    .font(.system(size: 10))
                    .foregroundStyle(muted)
            }
        }
        .foregroundStyle(ink)
        .padding(48)
        .frame(width: 612)
        .frame(minHeight: 792, alignment: .top)
        .background(Color.white)
    }

    func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .textCase(.uppercase)
                .tracking(1.2)
                .foregroundStyle(accent)
            content()
        }
    }
}
