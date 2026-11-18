import Foundation

extension Worksheet {
    static func load(from url: URL) -> Worksheet? {
        guard url.startAccessingSecurityScopedResource() else { return nil }
        defer { url.stopAccessingSecurityScopedResource() }
        guard let data = try? Data(contentsOf: url) else { return nil }
        return Worksheet(title: url.lastPathComponent, fileData: data)
    }

    func temporaryURL() -> URL {
        var url = FileManager.default.temporaryDirectory.appendingPathComponent(title)
        if url.pathExtension.isEmpty {
            url = url.appendingPathExtension("pdf")
        }
        try? fileData.write(to: url)
        return url
    }
}
