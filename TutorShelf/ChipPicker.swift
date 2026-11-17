import SwiftUI

enum ProfileOptions {
    static let interests = ["Animals", "Space", "Sports", "Soccer", "Music", "Art", "Dinosaurs",
                            "Cooking", "Video games", "Ninjas", "Cute things", "Nature", "Cars", "Superheroes"]
    static let learningStyles = ["Competitive", "Likes timers", "Loves games", "Needs short tasks",
                                 "Visual learner", "Loves drawing", "Likes reading", "Gets anxious with tests",
                                 "Patient", "Easily distracted", "Likes clear steps"]
}

struct ChipPicker: View {
    let options: [String]
    @Binding var text: String

    var selected: [String] {
        text.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    func isOn(_ option: String) -> Bool {
        selected.contains { $0.lowercased() == option.lowercased() }
    }

    func toggle(_ option: String) {
        var items = selected
        if let index = items.firstIndex(where: { $0.lowercased() == option.lowercased() }) {
            items.remove(at: index)
        } else {
            items.append(option)
        }
        text = items.joined(separator: ", ")
    }

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(options, id: \.self) { option in
                Button {
                    toggle(option)
                } label: {
                    Text(option)
                        .font(.rounded(.subheadline, .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .foregroundStyle(isOn(option) ? Color.white : Theme.ink)
                        .background(isOn(option) ? Theme.ink : Theme.background, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var widest: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            widest = max(widest, x - spacing)
        }
        return CGSize(width: widest, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
