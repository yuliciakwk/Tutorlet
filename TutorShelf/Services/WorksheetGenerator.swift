import Foundation

// STEP: PLAN — the outline the tutor checks before any pages are written.
struct PackPlan: Codable {
    var title: String
    var subtitle: String?
    var theme: String?
    var defaultTheme: Bool?
    var partLabel: String?
    var timed: Bool?
    var reward: String?
    var certificate: String?
    var palette: [String: String]?
    var buildingOn: String?
    var parts: [GeneratedPart]
}

struct GeneratedPart: Codable {
    var title: String
    var minutes: Int?
    var summary: String?
}

// STEP: FRONT and STEP: PART n replies.
struct FrontPages: Codable {
    var cover: String
    var certificate: String?
}

struct PartPages: Codable {
    var pages: [String]
    var answers: [String]?
}

// The finished pack, saved with the worksheet so it can be rebuilt or shown later.
struct GeneratedPack: Codable {
    var plan: PackPlan
    var pages: [String]
    var answers: [[String]]      // one list per part
}

enum GeneratorError: LocalizedError {
    case missingFile(String)
    case unreadableReply(String)

    var errorDescription: String? {
        switch self {
        case .missingFile(let name): "\(name) isn't in the app. Check it's ticked for the TutorShelf target."
        case .unreadableReply(let step): "The AI's reply for the \(step) wasn't in the expected format. Try again."
        }
    }
}

@MainActor
enum WorksheetGenerator {

    // MARK: - Step 1: the plan

    static func plan(student: Student, lesson: Lesson,
                     previous: PackPlan? = nil, changes: String = "") async throws -> PackPlan {
        var prompt = "STEP: PLAN\n\n" + (try request(student: student, lesson: lesson))
        if let previous, !changes.isEmpty {
            prompt += "\n\nPREVIOUS PLAN:\n\(json(previous))\n\nTUTOR'S CHANGES: \(changes)"
        }
        let reply = try await ClaudeClient.ask(system: try resource("system-prompt", "txt"),
                                               prompt: prompt, maxTokens: 3000, timeout: 120)
        return try decode(PackPlan.self, from: reply, step: "plan")
    }

    // MARK: - Step 2: the pages, written in parallel, then checked and printed

    static func write(plan: PackPlan, student: Student, lesson: Lesson,
                      progress: @escaping (String) -> Void) async throws -> (pack: GeneratedPack, pdf: Data) {
        let style = student.worksheetStyle.lowercased()
        let system = try resource("system-prompt", "txt")
        let context = try request(student: student, lesson: lesson)
            + "\n\nAPPROVED PLAN:\n\(json(plan))"

        // Request 0 is the cover and certificate; 1…N are the parts.
        let total = plan.parts.count + 1
        var replies: [Int: String] = [:]
        progress("Writing the pages… 0 of \(total) done")

        try await withThrowingTaskGroup(of: (Int, String).self) { group in
            group.addTask {
                (0, try await ClaudeClient.ask(system: system, prompt: "STEP: FRONT\n\n" + context,
                                               maxTokens: 16000, timeout: 240))
            }
            for number in 1...plan.parts.count {
                group.addTask {
                    (number, try await ClaudeClient.ask(system: system, prompt: "STEP: PART \(number)\n\n" + context,
                                                        maxTokens: 16000, timeout: 240))
                }
            }
            for try await (index, reply) in group {
                replies[index] = reply
                progress("Writing the pages… \(replies.count) of \(total) done")
            }
        }

        // If a reply can't be read, ask for that one piece again before giving up.
        func read<T: Decodable>(_ type: T.Type, index: Int, step: String, prompt: String) async throws -> T {
            if let value = try? decode(T.self, from: replies[index] ?? "", step: step) { return value }
            progress("Rewriting \(step)…")
            let again = try await ClaudeClient.ask(system: system, prompt: prompt, maxTokens: 16000, timeout: 240)
            return try decode(T.self, from: again, step: step)
        }

        let front = try await read(FrontPages.self, index: 0, step: "cover",
                                   prompt: "STEP: FRONT\n\n" + context)
        var partPages: [PartPages] = []
        for number in 1...plan.parts.count {
            partPages.append(try await read(PartPages.self, index: number, step: "part \(number)",
                                            prompt: "STEP: PART \(number)\n\n" + context))
        }

        var pages = [front.cover] + partPages.flatMap(\.pages)
        if let certificate = front.certificate, !certificate.isEmpty { pages.append(certificate) }
        var pack = GeneratedPack(plan: plan, pages: pages, answers: partPages.map { $0.answers ?? [] })

        // Lay out, fix pages that run long (up to twice), then print.
        progress("Checking every page fits…")
        let renderer = WorksheetRenderer()
        try await renderer.load(html: WorksheetHTML.build(pack: pack, style: style))
        for _ in 1...2 {
            let answerKeyPage = pack.pages.count          // the app's own page, never sent back
            let tooTall = try await renderer.overflowingPages().filter { $0 < answerKeyPage }
            if tooTall.isEmpty { break }
            progress("Tidying \(tooTall.count) page\(tooTall.count == 1 ? "" : "s") that ran long…")
            pack = try await shorten(pages: tooTall, in: pack, style: style)
            try await renderer.load(html: WorksheetHTML.build(pack: pack, style: style))
        }

        progress("Making the PDF…")
        let pdf = try await renderer.makePDF(pageCount: pack.pages.count + 1)   // + answer key
        return (pack, pdf)
    }

    // Sends each page that was too tall back on its own, all at the same time, and swaps in
    // the shorter versions. If a fix fails, the original page is kept rather than losing the pack.
    static func shorten(pages: [Int], in pack: GeneratedPack, style: String) async throws -> GeneratedPack {
        let system = try resource("system-prompt", "txt")
        let classList = try classes(for: style)

        var replies: [Int: String] = [:]
        await withTaskGroup(of: (Int, String?).self) { group in
            for index in pages {
                let page = pack.pages[index]
                let prompt = """
                STYLE: \(style)
                CLASSES:
                \(classList)

                This page is taller than 792px, so it won't fit on paper. Rewrite it so it fits: \
                keep the same questions where you can and shorten boxes, lines or passages, or drop \
                the last question if you must. Keep the same answers.

                \(page)

                Reply with only this JSON: {"pages": ["<section class=\\"page\\">…</section>"]}
                """
                group.addTask {
                    (index, try? await ClaudeClient.ask(system: system, prompt: prompt,
                                                        maxTokens: 6000, timeout: 180))
                }
            }
            for await (index, reply) in group {
                if let reply { replies[index] = reply }
            }
        }

        var updated = pack
        for (index, reply) in replies {
            if let fixed = try? decode(PartPages.self, from: reply, step: "page fix").pages.first,
               fixed.contains("class=\"page") {
                updated.pages[index] = fixed
            }
        }
        return updated
    }

    // MARK: - The request (never includes the student's name)

    static func request(student: Student, lesson: Lesson) throws -> String {
        let style = student.worksheetStyle.lowercased()
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

        // Lessons planned before this one: when a pack is made ahead, these will have been taught first.
        let plannedBefore = student.lessons
            .filter { $0.isPlanned && $0.date < lesson.date }
            .sorted { $0.date < $1.date }
            .map(\.topic)

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
        Planned before this lesson (will be taught first, no notes yet): \(plannedBefore.isEmpty ? "none" : plannedBefore.joined(separator: ", "))

        RECENT LESSON NOTES (newest first)
        \(notes.isEmpty ? "No lessons yet." : notes.joined(separator: "\n"))
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

    static func json<T: Encodable>(_ value: T) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
        return (try? String(data: encoder.encode(value), encoding: .utf8)) ?? "{}"
    }

    // Claude sometimes wraps JSON in ```json fences or adds a sentence. Keep only the {...} part.
    static func decode<T: Decodable>(_ type: T.Type, from reply: String, step: String) throws -> T {
        guard let start = reply.firstIndex(of: "{"),
              let end = reply.lastIndex(of: "}") else { throw GeneratorError.unreadableReply(step) }
        do {
            return try JSONDecoder().decode(T.self, from: Data(reply[start...end].utf8))
        } catch {
            throw GeneratorError.unreadableReply(step)
        }
    }
}
