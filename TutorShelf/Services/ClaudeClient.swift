import Foundation

enum ClaudeError: LocalizedError {
    case badResponse(String)

    var errorDescription: String? {
        switch self {
        case .badResponse(let details): "Claude returned an error: \(details)"
        }
    }
}

enum ClaudeClient {
    // What we send to Claude
    private struct Message: Encodable {
        let role: String
        let content: String
    }

    private struct Body: Encodable {
        let model: String
        let max_tokens: Int
        let system: String
        let messages: [Message]
    }

    // What Claude sends back
    private struct Reply: Decodable {
        struct Block: Decodable {
            let type: String
            let text: String?
        }
        let content: [Block]
    }

    static func ask(system: String, prompt: String, maxTokens: Int = 1500, timeout: TimeInterval = 60) async throws -> String {
        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.timeoutInterval = timeout
        request.setValue("Bearer \(Secrets.anthropicKey)", forHTTPHeaderField: "Authorization")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")

        let body = Body(model: "claude-sonnet-5-5",
                        max_tokens: maxTokens,
                        system: system,
                        messages: [Message(role: "user", content: prompt)])
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw ClaudeError.badResponse(String(data: data, encoding: .utf8) ?? "Unknown error")
        }

        let reply = try JSONDecoder().decode(Reply.self, from: data)
        let text = reply.content.compactMap { $0.text }.joined()
        guard !text.isEmpty else { throw ClaudeError.badResponse("Empty reply") }
        return text
    }
}
