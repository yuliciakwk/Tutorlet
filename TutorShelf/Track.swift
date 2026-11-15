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

    init(name: String, kind: String = "Curriculum", goal: String = "") {
        self.name = name
        self.kind = kind
        self.goal = goal
    }
}
