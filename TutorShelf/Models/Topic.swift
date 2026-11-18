import Foundation
import SwiftData

@Model
class Topic {
    var title: String = ""
    var order: Int = 0
    var status: String = "Not started"
    var track: Track?
    
    @Relationship(deleteRule: .nullify, inverse: \Lesson.roadmapTopic)
    var lessons: [Lesson] = []

    init(title: String, order: Int) {
        self.title = title
        self.order = order
    }
}
