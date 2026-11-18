import Foundation
import UIKit
import WebKit
import PDFKit

// Builds one HTML document from the AI's pages, the style's CSS, fonts and mascots.
enum WorksheetHTML {
    static let pageWidth: CGFloat = 612
    static let pageHeight: CGFloat = 792

    @MainActor
    static func build(pack: GeneratedPack, style: String) throws -> String {
        let css = try WorksheetGenerator.resource(style, "css")
        let mascotData = Data(try WorksheetGenerator.resource("mascots", "json").utf8)
        let mascots = (try? JSONDecoder().decode([String: String].self, from: mascotData)) ?? [:]

        // Remove inline styles the rules don't allow (font sizes, colours, margins…),
        // so the AI can't override the design system.
        var pages = pack.pages.joined(separator: "\n")
            .replacing(/\s+style="([^"]*)"/) { match in
                allowedStyle(String(match.1)) ? String(match.0) : ""
            }

        // Swap each mascot placeholder for its drawing.
        for (name, svg) in mascots {
            pages = pages.replacingOccurrences(
                of: "<div class=\"mascot-slot\" data-mascot=\"\(name)\"></div>",
                with: "<div class=\"mascot-slot\">\(svg)</div>")
        }

        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=612">
        <style>
        \(fonts)
        \(css)
        /* Screen-only spacing off, so page N starts exactly at N x 792. */
        html, body { margin: 0 !important; padding: 0 !important; background: #fff !important; -webkit-text-size-adjust: 100%; }
        .page { margin: 0 !important; box-shadow: none !important; }
        </style>
        </head>
        <body class="theme-\(style)" style="\(palette(pack.plan.palette))">
        \(symbols)
        \(pages)
        \(answerKey(pack: pack, style: style))
        </body>
        </html>
        """
    }

    // The app writes the answer key page itself, from each part's answers.
    static func answerKey(pack: GeneratedPack, style: String) -> String {
        let label = pack.plan.partLabel ?? "Part"
        let sections = zip(pack.plan.parts, pack.answers).enumerated().map { index, item in
            let (part, answers) = item
            let items = answers.map { "<li>\(escape($0))</li>" }.joined()
            return "<h4>\(escape(label)) \(index + 1) · \(escape(part.title))</h4><ol>\(items)</ol>"
        }.joined()

        let heading = style == "classic"
            ? "<h1 class=\"title\">Answer key</h1><p class=\"sub\">For the tutor · \(escape(pack.plan.title))</p><div class=\"rule\"></div>"
            : "<h2>Answer key</h2><p class=\"for\">For the tutor · \(escape(pack.plan.title))</p>"
        return "<section class=\"page c1\"><div class=\"akey\">\(heading)\(sections)</div></section>"
    }

    static func escape(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    // Inline styles may only position or size things: left, right, top, bottom, width, height, flex.
    static func allowedStyle(_ style: String) -> Bool {
        let allowed: Set<String> = ["left", "right", "top", "bottom", "width", "height", "flex"]
        let properties = style.split(separator: ";").compactMap { declaration in
            declaration.split(separator: ":").first?.trimmingCharacters(in: .whitespaces).lowercased()
        }.filter { !$0.isEmpty }
        return properties.allSatisfy { allowed.contains($0) }
    }

    // Only the allowed colour slots, and only real hex colours.
    static func palette(_ palette: [String: String]?) -> String {
        let allowed: Set<String> = ["--band", "--accent", "--c1", "--c2", "--c3", "--c4", "--c5"]
        let hex = /^#([0-9A-Fa-f]{3}|[0-9A-Fa-f]{6})$/
        return (palette ?? [:])
            .filter { allowed.contains($0.key) && $0.value.wholeMatch(of: hex) != nil }
            .map { "\($0.key):\($0.value)" }
            .sorted()
            .joined(separator: ";")
    }

    // Poppins from the app bundle (the files you added earlier).
    static let fonts = [("Regular", 400), ("Medium", 500), ("SemiBold", 600), ("Bold", 700), ("ExtraBold", 800)]
        .map { "@font-face { font-family: 'Poppins'; font-weight: \($0.1); src: url('Poppins-\($0.0).ttf'); }" }
        .joined(separator: "\n")

    static let symbols = """
    <svg width="0" height="0" style="position:absolute" aria-hidden="true">
    <symbol id="star" viewBox="0 0 24 24"><path d="M12 2.8l2.75 5.9 6.45.75-4.8 4.4 1.3 6.35L12 17l-5.7 3.2 1.3-6.35-4.8-4.4 6.45-.75z" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/></symbol>
    <symbol id="heart" viewBox="0 0 24 24"><path d="M12 20.5s-7.5-4.6-9.2-9.3C1.6 7.8 3.8 4.5 7.2 4.5c2 0 3.6 1.1 4.8 2.8 1.2-1.7 2.8-2.8 4.8-2.8 3.4 0 5.6 3.3 4.4 6.7-1.7 4.7-9.2 9.3-9.2 9.3z" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/></symbol>
    </svg>
    """
}

// Loads the HTML in a hidden web view, checks page heights, and prints each page to PDF.
@MainActor
final class WorksheetRenderer: NSObject, WKNavigationDelegate {
    private let webView: WKWebView
    private var loading: CheckedContinuation<Void, Error>?

    override init() {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = false   // the AI's HTML can't run scripts
        webView = WKWebView(frame: CGRect(x: 0, y: 0, width: WorksheetHTML.pageWidth, height: WorksheetHTML.pageHeight),
                            configuration: config)
        super.init()
        webView.navigationDelegate = self
    }

    func load(html: String) async throws {
        attachOffscreen()
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            loading = continuation
            webView.loadHTMLString(html, baseURL: Bundle.main.resourceURL)
        }
        // Wait until Poppins has loaded, or the page heights would be wrong.
        _ = try await webView.callAsyncJavaScript("await document.fonts.ready; return true;",
                                                  contentWorld: .page)
    }

    // Page numbers (starting at 0) whose content goes past the bottom of the page.
    func overflowingPages() async throws -> [Int] {
        let script = """
        return [...document.querySelectorAll('section.page')].map((page, i) => {
          const top = page.getBoundingClientRect().top;
          let lowest = 0;
          page.querySelectorAll('*').forEach(el => {
            const box = el.getBoundingClientRect();
            if (box.height) lowest = Math.max(lowest, box.bottom - top);
          });
          return lowest > 796 ? i : -1;
        }).filter(i => i >= 0);
        """
        let result = try await webView.callAsyncJavaScript(script, contentWorld: .page)
        return (result as? [Any])?.compactMap { ($0 as? NSNumber)?.intValue } ?? []
    }

    func makePDF(pageCount: Int) async throws -> Data {
        // Make the web view as tall as every page, so each one is fully drawn.
        webView.frame.size.height = WorksheetHTML.pageHeight * CGFloat(max(pageCount, 1))

        let merged = PDFDocument()
        var keepAlive: [PDFDocument] = []   // pages go blank if their original document is freed too early

        for index in 0..<pageCount {
            let config = WKPDFConfiguration()
            config.rect = CGRect(x: 0, y: WorksheetHTML.pageHeight * CGFloat(index),
                                 width: WorksheetHTML.pageWidth, height: WorksheetHTML.pageHeight)
            let data = try await webView.pdf(configuration: config)
            if let single = PDFDocument(data: data), let page = single.page(at: 0) {
                keepAlive.append(single)
                merged.insert(page, at: merged.pageCount)
            }
        }

        let output = merged.dataRepresentation() ?? Data()
        keepAlive.removeAll()
        webView.removeFromSuperview()
        return output
    }

    // A web view that isn't in a window may not draw, so park it off-screen in the app's window.
    private func attachOffscreen() {
        guard webView.superview == nil else { return }
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }
        webView.frame.origin = CGPoint(x: -10_000, y: 0)
        window?.addSubview(webView)
    }

    // MARK: WKNavigationDelegate

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loading?.resume()
        loading = nil
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        loading?.resume(throwing: error)
        loading = nil
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        loading?.resume(throwing: error)
        loading = nil
    }
}
