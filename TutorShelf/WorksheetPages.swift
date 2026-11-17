import SwiftUI

struct WorksheetCoverPage: View {
    let pack: WorksheetPack
    let theme: WorksheetTheme
    let grade: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                Text(grade)
                    .font(theme.font(12, .bold))
                    .textCase(.uppercase)
                    .tracking(1.2)
                    .foregroundStyle(theme.accent)
                Text(pack.title)
                    .font(theme.font(40, .heavy))
                Text(pack.subtitle)
                    .font(theme.font(18, .semibold))
                HStack(spacing: 8) {
                    Text("Name:").font(theme.font(14, .bold))
                    Rectangle().frame(height: 1)
                }
                .padding(.top, 16)
            }
            .foregroundStyle(theme.headerText)
            .padding(44)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.headerBackground)

            VStack(alignment: .leading, spacing: 12) {
                Text("Today's plan (\(pack.minutes) minutes)")
                    .font(theme.font(18, .bold))

                ForEach(Array(pack.parts.enumerated()), id: \.offset) { index, part in
                    HStack(spacing: 14) {
                        Text("\(index + 1)")
                            .font(theme.font(15, .bold))
                            .foregroundStyle(.white)
                            .frame(width: 34, height: 34)
                            .background(theme.color(at: index), in: Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(theme.partLabel) \(index + 1): \(part.title)")
                                .font(theme.font(14, .bold))
                            Text("\(part.minutes) min · \(part.subtitle)")
                                .font(theme.font(11))
                                .foregroundStyle(theme.muted)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.boxRadius)
                            .stroke(theme.color(at: index), lineWidth: 1.5)
                    )
                }

                if let buildingOn = pack.buildingOn {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Building on last time")
                            .font(theme.font(11, .bold))
                            .textCase(.uppercase)
                        Text(buildingOn)
                            .font(theme.font(12))
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(theme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: theme.boxRadius))
                    .padding(.top, 8)
                }
            }
            .padding(44)

            Spacer(minLength: 0)
        }
        .foregroundStyle(theme.ink)
        .frame(width: 612, height: 792, alignment: .top)
        .background(theme.pageBackground)
    }
}

struct WorksheetPartPage: View {
    let part: WorksheetPart
    let number: Int
    let totalParts: Int
    let theme: WorksheetTheme
    let packTitle: String
    let grade: String
    let partLabel: String
    let timed: Bool
    let reward: String

    let letters = ["A", "B", "C", "D", "E", "F"]

    var color: Color { theme.color(at: number - 1) }

    func sectionColor(_ index: Int) -> Color {
        theme.color(at: number - 1 + index)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            VStack(alignment: .leading, spacing: 12) {
                if theme.headerKind != "plain" {
                    nameDate
                }

                if let example = part.example {
                    QuickLessonBox(text: example, color: color, theme: theme)
                        .padding(.top, 8)
                }

                ForEach(Array(part.sections.enumerated()), id: \.offset) { sectionIndex, section in
                    sectionHeader(sectionIndex, section.heading)
                    ForEach(Array(section.blocks.enumerated()), id: \.offset) { blockIndex, block in
                        WorksheetBlockView(block: block, number: blockIndex + 1,
                                           color: sectionColor(sectionIndex), theme: theme)
                    }
                }

                Spacer(minLength: 0)

                if reward != "none" {
                    selfCheck
                }
                footer
            }
            .padding(.horizontal, 40)
            .padding(.top, 18)
            .padding(.bottom, 28)
        }
        .foregroundStyle(theme.ink)
        .frame(width: 612, height: 792, alignment: .top)
        .background(theme.pageBackground)
    }

    @ViewBuilder
    var header: some View {
        switch theme.headerKind {
        case "band":
            gameHeader
        case "soft":
            cozyHeader
        default:
            plainHeader
        }
    }

    var gameHeader: some View {
        ZStack(alignment: .leading) {
            color
            Circle()
                .fill(Color.white.opacity(0.14))
                .frame(width: 150, height: 150)
                .offset(x: 500, y: -48)
            Circle()
                .fill(Color.white.opacity(0.14))
                .frame(width: 64, height: 64)
                .offset(x: 410, y: 42)
            
            HStack(spacing: 16) {
                VStack(spacing: -2) {
                    Text(partLabel.uppercased()).font(theme.font(8, .bold))
                    Text("\(number)").font(theme.font(26, .heavy))
                }
                .foregroundStyle(color)
                .frame(width: 60, height: 60)
                .background(Color.white, in: Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(part.title).font(theme.font(24, .bold))
                    Text(part.subtitle).font(theme.font(12, .medium))
                }
                .foregroundStyle(.white)
            }
            .padding(.horizontal, 36)
            
            if timed {
                Text("\(part.minutes) MIN")
                    .font(theme.font(9, .bold))
                    .foregroundStyle(color)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 5)
                    .background(Color.white, in: Capsule())
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(.top, 14)
                    .padding(.trailing, 28)
            }
        }
        .frame(height: 108)
        .clipped()
    }

    var cozyHeader: some View {
        ZStack(alignment: .leading) {
            color.opacity(0.14)
            Circle()
                .fill(Color.white.opacity(0.7))
                .frame(width: 14, height: 14)
                .offset(x: 250, y: -34)
            Circle()
                .fill(Color.white.opacity(0.7))
                .frame(width: 22, height: 22)
                .offset(x: 330, y: 30)

            VStack(alignment: .leading, spacing: 6) {
                Text("\(partLabel) \(number)  ·  \(part.minutes) min")
                    .font(theme.font(9, .bold))
                    .textCase(.uppercase)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(color, in: Capsule())
                Text(part.title).font(theme.font(26, .bold))
                Text(part.subtitle)
                    .font(theme.font(12))
                    .foregroundStyle(theme.muted)
            }
            .padding(.horizontal, 40)

            Circle()
                .fill(color.opacity(0.16))
                .frame(width: 96, height: 96)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 36)
        }
        .frame(height: 120)
        .clipped()
    }

    var plainHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("\(grade) · \(packTitle)")
                Spacer()
                Text("Part \(number) of \(totalParts) · \(part.minutes) min")
            }
            .font(theme.font(9))
            .foregroundStyle(theme.muted)

            Text(part.title)
                .font(theme.font(22, .semibold))
                .padding(.top, 4)
            Text(part.subtitle)
                .font(theme.font(11))
                .foregroundStyle(theme.muted)
            Rectangle()
                .fill(theme.accent)
                .frame(height: 2)
                .padding(.top, 8)
        }
        .padding(.horizontal, 40)
        .padding(.top, 36)
    }

    var nameDate: some View {
        HStack(spacing: 8) {
            Text("Name:").font(theme.font(12, .bold))
            Rectangle().fill(theme.ink).frame(height: 1)
            Text("Date:").font(theme.font(12, .bold)).padding(.leading, 16)
            Rectangle().fill(theme.ink).frame(width: 150, height: 1)
        }
    }

    @ViewBuilder
    func sectionHeader(_ index: Int, _ heading: String) -> some View {
        if theme.headerKind == "plain" {
            Text("\(index + 1). \(heading)")
                .font(theme.font(12, .semibold))
                .padding(.top, 6)
        } else {
            HStack(spacing: 8) {
                Text("PART \(letters[min(index, letters.count - 1)])")
                    .font(theme.font(11, .heavy))
                Text(heading)
                    .font(theme.font(11, .bold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(sectionColor(index), in: Capsule())
            .padding(.top, 4)
        }
    }

    var selfCheck: some View {
        HStack(spacing: 10) {
            if reward == "stars" {
                Text("My score: ______")
                if timed {
                    Spacer()
                    Text("Time: ______")
                }
                Spacer()
                Text("Colour your stars:")
                ForEach(0..<3, id: \.self) { _ in
                    Image(systemName: "star").foregroundStyle(color)
                }
            } else {
                Text("How did I do?")
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "heart").foregroundStyle(color)
                }
                Spacer()
                Text("One thing I learned: __________")
            }
        }
        .font(theme.font(12, .semibold))
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .overlay(
            RoundedRectangle(cornerRadius: theme.boxRadius)
                .stroke(color, style: StrokeStyle(lineWidth: 1.2, dash: [5, 4]))
        )
    }

    var footer: some View {
        HStack {
            Text(packTitle).font(theme.font(9, .bold))
            Spacer()
            Text("\(grade)  ·  \(part.minutes) min").font(theme.font(9))
            Spacer()
            Text("Page \(number + 1)").font(theme.font(9))
        }
        .foregroundStyle(theme.muted)
        .padding(.top, 8)
        .overlay(alignment: .top) {
            Rectangle().fill(theme.muted.opacity(0.3)).frame(height: 0.5)
        }
    }
}

struct QuickLessonBox: View {
    let text: String
    let color: Color
    let theme: WorksheetTheme

    var body: some View {
        Text(text)
            .font(theme.font(12, .medium))
            .lineSpacing(3)
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: theme.boxRadius))
            .overlay(
                RoundedRectangle(cornerRadius: theme.boxRadius)
                    .stroke(color, lineWidth: 1.5)
            )
            .overlay(alignment: .topLeading) {
                Text(theme.headerKind == "plain" ? "KEY IDEA" : "QUICK LESSON")
                    .font(theme.font(8, .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(color, in: Capsule())
                    .offset(x: 18, y: -9)
            }
    }
}

struct WorksheetBlockView: View {
    let block: WorksheetBlock
    let number: Int
    let color: Color
    let theme: WorksheetTheme

    var body: some View {
        switch block.kind {
        case "shortAnswer":
            HStack(spacing: 12) {
                numberBadge
                Text(block.text).font(theme.font(16, .bold))
                answerBox(width: 110)
                Spacer()
            }
        case "problem":
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 12) {
                    numberBadge
                    Text(block.text).font(theme.font(13))
                }
                HStack(alignment: .bottom, spacing: 12) {
                    RoundedRectangle(cornerRadius: theme.boxRadius)
                        .stroke(theme.muted.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                        .frame(height: CGFloat(block.lines ?? 3) * 22)
                        .overlay(alignment: .topLeading) {
                            Text("work").font(theme.font(9)).foregroundStyle(theme.muted).padding(6)
                        }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Answer:").font(theme.font(12, .bold))
                        answerBox(width: 110)
                    }
                }
            }
        case "written":
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top, spacing: 12) {
                    numberBadge
                    Text(block.text).font(theme.font(13))
                }
                ForEach(0..<(block.lines ?? 2), id: \.self) { _ in
                    Rectangle()
                        .fill(theme.muted.opacity(0.4))
                        .frame(height: 1)
                        .padding(.top, 20)
                }
            }
        case "passage":
            Text(block.text)
                .font(theme.font(12))
                .lineSpacing(3)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(RoundedRectangle(cornerRadius: theme.boxRadius).stroke(color, lineWidth: 1))
        case "choice":
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    numberBadge
                    Text(block.text).font(theme.font(13))
                }
                HStack(spacing: 18) {
                    ForEach(block.options ?? [], id: \.self) { option in
                        HStack(spacing: 6) {
                            Circle().stroke(color, lineWidth: 1.5).frame(width: 14, height: 14)
                            Text(option).font(theme.font(13))
                        }
                    }
                }
                .padding(.leading, 36)
            }
        case "formula":
            Text(block.text)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(theme.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: theme.boxRadius))
        case "tip":
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "lightbulb")
                Text(block.text).font(theme.font(12))
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(
                RoundedRectangle(cornerRadius: theme.boxRadius)
                    .stroke(color, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
            )
        default:
            EmptyView()
        }
    }

    var numberBadge: some View {
        Text("\(number)")
            .font(theme.font(12, .bold))
            .foregroundStyle(.white)
            .frame(width: 24, height: 24)
            .background(color, in: Circle())
    }

    func answerBox(width: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: theme.boxRadius)
            .stroke(color, lineWidth: 1.5)
            .frame(width: width, height: 36)
    }
}

struct WorksheetAnswerKeyPage: View {
    let pack: WorksheetPack
    let theme: WorksheetTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Answer key")
                .font(theme.font(24, .heavy))
            Text("For the tutor")
                .font(theme.font(12))
                .foregroundStyle(theme.muted)
            ForEach(Array(pack.answerKey.enumerated()), id: \.offset) { index, answer in
                HStack(alignment: .top) {
                    Text("\(index + 1).")
                        .font(theme.font(12, .bold))
                        .frame(width: 28, alignment: .leading)
                    Text(answer)
                        .font(theme.font(12))
                }
            }
            Spacer(minLength: 0)
        }
        .foregroundStyle(theme.ink)
        .padding(40)
        .frame(width: 612, height: 792, alignment: .top)
        .background(Color.white)
    }
}

struct WorksheetCertificatePage: View {
    let pack: WorksheetPack
    let title: String
    let theme: WorksheetTheme
    let tutorName: String

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "trophy")
                .font(.system(size: 56))
                .foregroundStyle(theme.accent)
            Text("Certificate of achievement")
                .font(theme.font(12, .bold))
                .textCase(.uppercase)
                .tracking(2)
                .foregroundStyle(theme.muted)
            Text(title)
                .font(theme.font(34, .heavy))
                .multilineTextAlignment(.center)
                .foregroundStyle(theme.color(at: 0))
                .padding(.horizontal, 40)
            Text("This is proudly awarded to")
                .font(theme.font(13))
                .foregroundStyle(theme.muted)
                .padding(.top, 8)
            Rectangle()
                .fill(theme.ink)
                .frame(width: 320, height: 1.5)
                .padding(.top, 34)
            Text("for completing \(pack.title)")
                .font(theme.font(14, .medium))
            HStack(spacing: 10) {
                ForEach(0..<5, id: \.self) { index in
                    Image(systemName: "star")
                        .font(.system(size: 22))
                        .foregroundStyle(theme.color(at: index))
                }
            }
            .padding(.top, 6)
            Spacer()
            HStack(alignment: .bottom, spacing: 60) {
                VStack(spacing: 4) {
                    Text(tutorName).font(theme.font(13, .semibold))
                    Rectangle().fill(theme.ink).frame(width: 180, height: 1)
                    Text("Tutor").font(theme.font(10)).foregroundStyle(theme.muted)
                }
                VStack(spacing: 4) {
                    Text(" ").font(theme.font(13))
                    Rectangle().fill(theme.ink).frame(width: 180, height: 1)
                    Text("Date").font(theme.font(10)).foregroundStyle(theme.muted)
                }
            }
            .padding(.bottom, 70)
        }
        .frame(maxWidth: .infinity)
        .foregroundStyle(theme.ink)
        .frame(width: 612, height: 792)
        .background(theme.pageBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(theme.color(at: 0), lineWidth: 6)
                .padding(24)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(theme.accent, lineWidth: 1.5)
                .padding(38)
        )
    }
}
