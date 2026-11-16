import Foundation

enum ClaudeError: Error {
    case badResponse(String)
}

struct ClaudeClient {
    static func ask(system: String, prompt: String, maxTokens: Int = 1500) async throws -> String {
        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(Secrets.anthropicKey)", forHTTPHeaderField: "Authorization")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")

        let body: [String: Any] = [
            "model": "claude-sonnet-5-5",
            "max_tokens": maxTokens,
            "system": system,
            "messages": [["role": "user", "content": prompt]]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw ClaudeError.badResponse(String(data: data, encoding: .utf8) ?? "Unknown error")
        }

        struct Reply: Decodable {
            struct Block: Decodable {
                let type: String
                let text: String?
            }
            let content: [Block]
        }
        let reply = try JSONDecoder().decode(Reply.self, from: data)
        return reply.content.compactMap { $0.text }.joined()
    }
}
