import Foundation
import SwiftData

@Model
class Topic {
    var title: String = ""
    var order: Int = 0
    var status: String = "Not started"
    var track: Track?

    init(title: String, order: Int) {
        self.title = title
        self.order = order
    }
}
