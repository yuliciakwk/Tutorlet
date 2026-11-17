import Foundation

struct WorksheetPack: Codable {
    var title: String
    var subtitle: String
    var minutes: Int
    var buildingOn: String?
    var parts: [WorksheetPart]
    var answerKey: [String]
}

struct WorksheetPart: Codable {
    var title: String
    var subtitle: String
    var minutes: Int
    var example: String?
    var sections: [WorksheetSection]
}

struct WorksheetSection: Codable {
    var heading: String
    var blocks: [WorksheetBlock]
}

struct WorksheetBlock: Codable {
    // kind is one of: shortAnswer, problem, written, passage, choice, formula, tip
    var kind: String
    var text: String
    var options: [String]?
    var lines: Int?
}

extension WorksheetPack {
    static let sample = WorksheetPack(
        title: "Fraction Pizza",
        subtitle: "Halves, quarters and fifths",
        minutes: 45,
        buildingOn: "Last week we shared groups fairly. Today those groups become fractions.",
        parts: [
            WorksheetPart(
                title: "Power-Up",
                subtitle: "Warm up with what you know",
                minutes: 8,
                example: "Half means 2 equal parts: 1/2 of 8 is 4.",
                sections: [
                    WorksheetSection(heading: "Quick facts", blocks: [
                        WorksheetBlock(kind: "shortAnswer", text: "1/2 of 10 ="),
                        WorksheetBlock(kind: "shortAnswer", text: "1/4 of 12 ="),
                        WorksheetBlock(kind: "choice", text: "Which is bigger?", options: ["1/2", "1/4"])
                    ])
                ]
            ),
            WorksheetPart(
                title: "Pizza Party",
                subtitle: "Share it fairly",
                minutes: 12,
                example: nil,
                sections: [
                    WorksheetSection(heading: "Story problems", blocks: [
                        WorksheetBlock(kind: "problem", text: "A pizza has 8 slices. You eat 1/4 of it. How many slices is that?", lines: 3),
                        WorksheetBlock(kind: "written", text: "Explain how you know.", lines: 2),
                        WorksheetBlock(kind: "tip", text: "Draw the pizza and shade the slices.")
                    ])
                ]
            )
        ],
        answerKey: ["5", "3", "1/2", "2 slices"]
    )
}
