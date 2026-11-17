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
    let theme: WorksheetTheme
    let footer: String

    let letters = ["A", "B", "C", "D", "E", "F"]

    var color: Color { theme.color(at: number - 1) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(theme.partLabel) \(number)  |  \(part.minutes) min")
                .font(theme.font(11, .bold))
                .textCase(.uppercase)
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(color, in: Capsule())
            Text(part.title)
                .font(theme.font(28, .heavy))
            Text(part.subtitle)
                .font(theme.font(13))
                .foregroundStyle(theme.muted)
            Rectangle()
                .fill(color)
                .frame(height: 3)

            HStack(spacing: 8) {
                Text("Name:").font(theme.font(12, .bold))
                Rectangle().fill(theme.muted.opacity(0.5)).frame(height: 1)
                Text("Date:").font(theme.font(12, .bold))
                Rectangle().fill(theme.muted.opacity(0.5)).frame(width: 140, height: 1)
            }

            if let example = part.example {
                Text(example)
                    .font(theme.font(13, .semibold))
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(color.opacity(0.10), in: RoundedRectangle(cornerRadius: theme.boxRadius))
                    .overlay(RoundedRectangle(cornerRadius: theme.boxRadius).stroke(color, lineWidth: 1))
            }

            ForEach(Array(part.sections.enumerated()), id: \.offset) { sectionIndex, section in
                Text("Part \(letters[min(sectionIndex, letters.count - 1)])  \(section.heading)")
                    .font(theme.font(13, .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(color, in: Capsule())

                ForEach(Array(section.blocks.enumerated()), id: \.offset) { blockIndex, block in
                    WorksheetBlockView(block: block, number: blockIndex + 1, color: color, theme: theme)
                }
            }

            Spacer(minLength: 0)

            selfCheck

            Text("\(footer)  ·  Page \(number + 1)")
                .font(theme.font(9))
                .foregroundStyle(theme.muted)
        }
        .foregroundStyle(theme.ink)
        .padding(40)
        .frame(width: 612, height: 792, alignment: .top)
        .background(theme.pageBackground)
    }

    var selfCheck: some View {
        HStack(spacing: 10) {
            switch theme.selfCheck {
            case "stars":
                Text("Score: ______")
                Spacer()
                Text("Colour your stars:")
                ForEach(0..<3, id: \.self) { _ in
                    Image(systemName: "star").foregroundStyle(color)
                }
            case "hearts":
                Text("How did I do?")
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "heart").foregroundStyle(color)
                }
                Spacer()
                Text("One thing I learned: __________")
            default:
                Text("One thing to remember from this part: ______________________________")
            }
        }
        .font(theme.font(12, .semibold))
        .padding(12)
        .overlay(
            RoundedRectangle(cornerRadius: theme.boxRadius)
                .stroke(color, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
        )
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
