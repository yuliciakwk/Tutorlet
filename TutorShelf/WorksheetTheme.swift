import SwiftUI

struct WorksheetTheme {
    var headerBackground: Color
    var headerText: Color
    var accent: Color
    var partColors: [Color]
    var pageBackground: Color
    var ink: Color
    var muted: Color
    var partLabel: String
    var fontDesign: Font.Design
    var boxRadius: CGFloat
    var selfCheck: String
    var headerKind: String

    func color(at index: Int) -> Color {
        partColors[index % partColors.count]
    }

    func font(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        if fontDesign == .default {
            return .system(size: size, weight: weight, design: .serif)
        }
        let name: String
        switch weight {
        case .heavy, .black: name = "Poppins-ExtraBold"
        case .bold: name = "Poppins-Bold"
        case .semibold: name = "Poppins-SemiBold"
        case .medium: name = "Poppins-Medium"
        default: name = "Poppins-Regular"
        }
        return .custom(name, size: size)
    }

    static func forStyle(_ style: String) -> WorksheetTheme {
        switch style {
        case "Game": return game
        case "Cozy": return cozy
        default: return classic
        }
    }

    static let game = WorksheetTheme(
        headerBackground: Color(hex: 0x1E2A44),
        headerText: .white,
        accent: Color(hex: 0xF2B705),
        partColors: [Color(hex: 0xD97706), Color(hex: 0x16A34A), Color(hex: 0x2563EB), Color(hex: 0xDC2626), Color(hex: 0x7C3AED)],
        pageBackground: Color(hex: 0xFFFAF2),
        ink: Color(hex: 0x1E2A44),
        muted: Color(hex: 0x6B7280),
        partLabel: "Level",
        fontDesign: .rounded,
        boxRadius: 12,
        selfCheck: "stars",
        headerKind: "band"
    )

    static let cozy = WorksheetTheme(
        headerBackground: Color(hex: 0xE3EEFB),
        headerText: Color(hex: 0x2E2A3B),
        accent: Color(hex: 0x4A8FD0),
        partColors: [Color(hex: 0xD9668A), Color(hex: 0x8B78C9), Color(hex: 0x3FA37E), Color(hex: 0xD69A2D), Color(hex: 0x4A8FD0)],
        pageBackground: Color(hex: 0xFFF8F2),
        ink: Color(hex: 0x2E2A3B),
        muted: Color(hex: 0x77707F),
        partLabel: "Chapter",
        fontDesign: .rounded,
        boxRadius: 16,
        selfCheck: "hearts",
        headerKind: "soft"
    )

    static let classic = WorksheetTheme(
        headerBackground: Color(hex: 0xEEEBFA),
        headerText: Color(hex: 0x2E2A3B),
        accent: Color(hex: 0x6B5BB5),
        partColors: [Color(hex: 0x6B5BB5)],
        pageBackground: .white,
        ink: Color(hex: 0x2E2A3B),
        muted: Color(hex: 0x6B6B78),
        partLabel: "Part",
        fontDesign: .default,
        boxRadius: 8,
        selfCheck: "none",
        headerKind: "plain"
    )
}
