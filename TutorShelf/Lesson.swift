import Foundation
import SwiftData

@Model
class Lesson {
    var date: Date = Date()
    var topic: String = ""
    var rating: String = "Okay"
    var note: String = ""
    var shareWithParents: Bool = true
    var student: Student?
    
    @Relationship(deleteRule: .nullify, inverse: \Worksheet.lesson)
    var worksheets: [Worksheet] = []

    init(date: Date = Date(), topic: String = "", rating: String = "Okay",
         note: String = "", shareWithParents: Bool = true) {
        self.date = date
        self.topic = topic
        self.rating = rating
        self.note = note
        self.shareWithParents = shareWithParents
    }
}
