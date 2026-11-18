import Foundation

// The JSON Claude sends back (see system-prompt.txt, "Output").
struct GeneratedPack: Codable {
    var title: String
    var subtitle: String?
    var theme: String?
    var defaultTheme: Bool?
    var partLabel: String?
    var timed: Bool?
    var reward: String?
    var certificate: String?
    var palette: [String: String]?
    var parts: [GeneratedPart]?
    var pages: [String]
    var answerKey: [String]?
}

struct GeneratedPart: Codable {
    var title: String
    var minutes: Int?
    var summary: String?
}

enum GeneratorError: LocalizedError {
    case missingFile(String)
    case unreadableReply

    var errorDescription: String? {
        switch self {
        case .missingFile(let name): "\(name) isn't in the app. Check it's ticked for the TutorShelf target."
        case .unreadableReply: "The AI's reply wasn't in the expected format. Try Redo."
        }
    }
}

@MainActor
enum WorksheetGenerator {

    // MARK: - The whole job: write, check, fix, turn into a PDF

    static func makePDF(student: Student, lesson: Lesson,
                        progress: (String) -> Void) async throws -> (pack: GeneratedPack, pdf: Data) {
        let style = student.worksheetStyle.lowercased()     // "game", "cozy" or "classic"

        progress("Writing the worksheets…")
        var pack = try await generate(student: student, lesson: lesson, style: style)

        progress("Laying out the pages…")
        let renderer = WorksheetRenderer()
        try await renderer.load(html: WorksheetHTML.build(pack: pack, style: style))

        // Up to two rounds of fixing pages that run off the bottom.
        for _ in 1...2 {
            let tooTall = try await renderer.overflowingPages()
            if tooTall.isEmpty { break }
            progress("Tidying \(tooTall.count) page\(tooTall.count == 1 ? "" : "s") that ran long…")
            pack = try await shorten(pages: tooTall, in: pack, style: style)
            try await renderer.load(html: WorksheetHTML.build(pack: pack, style: style))
        }

        progress("Making the PDF…")
        let pdf = try await renderer.makePDF(pageCount: pack.pages.count)
        return (pack, pdf)
    }

    // MARK: - Ask Claude

    static func generate(student: Student, lesson: Lesson, style: String) async throws -> GeneratedPack {
        let system = try resource("system-prompt", "txt")
        let prompt = try request(student: student, lesson: lesson, style: style)
        let reply = try await ClaudeClient.ask(system: system, prompt: prompt,
                                               maxTokens: 20000, timeout: 300)
        return try decode(GeneratedPack.self, from: reply)
    }

    // Sends only the pages that were too tall, and swaps in the shorter versions.
    static func shorten(pages: [Int], in pack: GeneratedPack, style: String) async throws -> GeneratedPack {
        struct Fix: Decodable { let pages: [String] }

        let system = try resource("system-prompt", "txt")
        let numbered = pages.map { "PAGE \($0 + 1):\n\(pack.pages[$0])" }.joined(separator: "\n\n")
        let prompt = """
        STYLE: \(style)
        CLASSES:
        \(try classes(for: style))

        These pages are taller than 792px, so they won't fit on paper. Rewrite each one so it fits: \
        keep the same questions where you can and shorten boxes, lines or passages, or drop the \
        last question if you must. Keep the answers in the answer key correct.

        \(numbered)

        Reply with only this JSON: {"pages": ["<section class=\\"page\\">…</section>", …]} \
        with one page for each page above, in the same order.
        """
        let reply = try await ClaudeClient.ask(system: system, prompt: prompt,
                                               maxTokens: 12000, timeout: 300)
        let fix = try decode(Fix.self, from: reply)

        var updated = pack
        for (index, page) in zip(pages, fix.pages) {
            updated.pages[index] = page
        }
        return updated
    }

    // MARK: - The request (never includes the student's name)

    static func request(student: Student, lesson: Lesson, style: String) throws -> String {
        let topic = lesson.roadmapTopic
        let track = topic?.track ?? student.tracks.first
        let sortedTopics = (track?.topics ?? []).sorted { $0.order < $1.order }

        let subject: String
        if let track {
            subject = track.kind == "Goal" ? "\(track.name) (Goal: \(track.goal))" : "\(track.name) (Curriculum)"
        } else {
            subject = student.subjects
        }

        let needsReview = sortedTopics.filter { $0.status == "Needs review" }.map(\.title)
        let after = sortedTopics.first {
            $0.order > (topic?.order ?? -1) && $0.status != "Mastered" && $0 !== topic
        }

        let notes = student.lessons
            .filter { !$0.isPlanned }
            .sorted { $0.date > $1.date }
            .prefix(4)
            .map { "\($0.date.formatted(date: .abbreviated, time: .omitted)) · \($0.topic) · \($0.rating) · \($0.note)" }

        let text = """
        STYLE: \(style)
        CLASSES:
        \(try classes(for: style))

        STUDENT (no name is shared)
        Grade: \(student.grade)    Level: \(student.level)
        Subject: \(subject)
        Strengths: \(student.strengths)
        Focus areas: \(student.focusAreas)
        Interests: \(student.interests)
        Learning style: \(student.learningStyle)
        Notes: \(student.notes)

        LESSON
        Lesson length: \(student.lessonMinutes) minutes    Format: Print
        Roadmap topic: \(topic?.title ?? lesson.topic)
        Focus for this lesson: \(lesson.focus.isEmpty ? "none given" : lesson.focus)
        Needs review: \(needsReview.isEmpty ? "none" : needsReview.joined(separator: ", "))
        Next on the roadmap after this: \(after?.title ?? "none")

        RECENT LESSON NOTES (newest first)
        \(notes.isEmpty ? "No lessons yet." : notes.joined(separator: "\n"))

        Write the pack.
        """
        return scrub(text, name: student.name)
    }

    // Replaces the student's name (full or first) if a tutor typed it into a note.
    static func scrub(_ text: String, name: String) -> String {
        var result = text
        let full = name.trimmingCharacters(in: .whitespaces)
        guard !full.isEmpty else { return result }
        for part in [full] + full.split(separator: " ").map(String.init) where part.count > 1 {
            result = result.replacingOccurrences(of: part, with: "the student", options: .caseInsensitive)
        }
        return result
    }

    // MARK: - Helpers

    static func resource(_ name: String, _ ext: String) throws -> String {
        guard let url = Bundle.main.url(forResource: name, withExtension: ext),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            throw GeneratorError.missingFile("\(name).\(ext)")
        }
        return text
    }

    static func classes(for style: String) throws -> String {
        let data = Data(try resource("style-guides", "json").utf8)
        let guides = try JSONDecoder().decode([String: String].self, from: data)
        return guides[style] ?? guides["classic"] ?? ""
    }

    // Claude sometimes wraps JSON in ```json fences or adds a sentence. Keep only the {...} part.
    static func decode<T: Decodable>(_ type: T.Type, from reply: String) throws -> T {
        guard let start = reply.firstIndex(of: "{"),
              let end = reply.lastIndex(of: "}") else { throw GeneratorError.unreadableReply }
        let json = Data(reply[start...end].utf8)
        do {
            return try JSONDecoder().decode(T.self, from: json)
        } catch {
            throw GeneratorError.unreadableReply
        }
    }
}
