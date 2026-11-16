import SwiftUI

enum Theme {
    static let background = Color(hex: 0xF4F3F8)
    static let ink = Color(hex: 0x1E1B2E)
    static let secondaryText = Color(hex: 0x4F4A63)
    static let card = Color.white

    static let studentColors: [String: Color] = [
        "peach": Color(hex: 0xFFE1D2),
        "lavender": Color(hex: 0xE5DDFB),
        "mint": Color(hex: 0xD5F0E3),
        "sky": Color(hex: 0xD6E8FB)
    ]
    static let colorOrder = ["peach", "lavender", "mint", "sky"]

    static func colorName(for student: Student) -> String {
        if studentColors[student.colorName] != nil {
            return student.colorName
        }
        let total = student.name.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return colorOrder[total % colorOrder.count]
    }

    static func color(for student: Student) -> Color {
        studentColors[colorName(for: student)] ?? card
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

struct CardStyle: ViewModifier {
    var color: Color

    func body(content: Content) -> some View {
        content
            .padding(20)
            .background(color, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

extension View {
    func card(_ color: Color = Theme.card) -> some View {
        modifier(CardStyle(color: color))
    }
}

extension Font {
    static func rounded(_ style: Font.TextStyle, _ weight: Font.Weight = .regular) -> Font {
        .system(style, design: .rounded, weight: weight)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.rounded(.body, .bold))
            .foregroundStyle(.white)
            .padding(.vertical, 14)
            .background(Theme.ink, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.rounded(.body, .bold))
            .foregroundStyle(Theme.ink)
            .padding(.vertical, 14)
            .background(Theme.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}
