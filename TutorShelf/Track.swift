import Foundation
import SwiftData

@Model
class Track {
    var name: String = ""
    var kind: String = "Curriculum"
    var goal: String = ""
    var student: Student?

    @Relationship(deleteRule: .cascade, inverse: \Topic.track)
    var topics: [Topic] = []
    var nextTopic: Topic? {
        let sorted = topics.sorted { a, b in a.order < b.order }
        return sorted.first { $0.status == "Needs review" }
            ?? sorted.first { $0.status == "In progress" }
            ?? sorted.first { $0.status == "Not started" }
    }

    init(name: String, kind: String = "Curriculum", goal: String = "") {
        self.name = name
        self.kind = kind
        self.goal = goal
    }
}
