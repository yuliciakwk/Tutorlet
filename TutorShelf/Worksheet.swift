import Foundation
import SwiftData

@Model
class Worksheet {
    var title: String = ""
    var addedOn: Date = Date()
    @Attribute(.externalStorage) var fileData: Data = Data()
    var student: Student?
    var lesson: Lesson?
    var content: Data?

    init(title: String, fileData: Data) {
        self.title = title
        self.fileData = fileData
    }
}
