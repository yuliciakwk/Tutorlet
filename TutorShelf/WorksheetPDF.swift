import SwiftUI

@MainActor
enum WorksheetPDF {
    static func make(pack: WorksheetPack, style: String, grade: String) -> URL {
        let theme = WorksheetTheme.forStyle(style)

        var pages: [AnyView] = [AnyView(WorksheetCoverPage(pack: pack, theme: theme, grade: grade))]
        for (index, part) in pack.parts.enumerated() {
            pages.append(AnyView(WorksheetPartPage(part: part, number: index + 1, theme: theme, footer: pack.title)))
        }
        pages.append(AnyView(WorksheetAnswerKeyPage(pack: pack, theme: theme)))

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(pack.title).pdf")
        var box = CGRect(x: 0, y: 0, width: 612, height: 792)
        guard let pdf = CGContext(url as CFURL, mediaBox: &box, nil) else { return url }

        for page in pages {
            let renderer = ImageRenderer(content: page)
            renderer.proposedSize = ProposedViewSize(width: 612, height: 792)
            renderer.render { _, draw in
                pdf.beginPDFPage(nil)
                draw(pdf)
                pdf.endPDFPage()
            }
        }
        pdf.closePDF()
        return url
    }
}
