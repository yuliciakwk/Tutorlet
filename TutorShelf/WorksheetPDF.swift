import SwiftUI

@MainActor
enum WorksheetPDF {
    static func make(pack: WorksheetPack, style: String, grade: String) -> URL {
        let theme = WorksheetTheme.forStyle(style)
        let partLabel = pack.partLabel ?? theme.partLabel
        let timed = pack.timed ?? false
        let reward = pack.reward ?? theme.selfCheck

        var pages: [AnyView] = [AnyView(WorksheetCoverPage(pack: pack, theme: theme, grade: grade))]
        for (index, part) in pack.parts.enumerated() {
            pages.append(AnyView(WorksheetPartPage(part: part, number: index + 1, totalParts: pack.parts.count,
                                                   theme: theme, packTitle: pack.title, grade: grade,
                                                   partLabel: partLabel, timed: timed, reward: reward)))
        }
        if let certificateTitle = pack.certificateTitle {
            let tutorName = UserDefaults.standard.string(forKey: "tutorName") ?? ""
            pages.append(AnyView(WorksheetCertificatePage(pack: pack, title: certificateTitle,
                                                          theme: theme, tutorName: tutorName)))
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
