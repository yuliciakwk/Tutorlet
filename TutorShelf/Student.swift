import SwiftData

@Model
class Student {
    var name: String
    var grade: String
    var subjects: String
    var strengths: String
    var focusAreas: String
    var interests: String
    var learningStyle: String
    var notes: String
    var format: String = "In person"
    var lessonMinutes: Int = 60
    
    @Relationship(deleteRule: .cascade, inverse: \Lesson.student)
    var lessons: [Lesson] = []
    @Relationship(deleteRule: .cascade, inverse: \Worksheet.student)
    var worksheets: [Worksheet] = []
    @Relationship(deleteRule: .cascade, inverse: \Track.student)
    var tracks: [Track] = []

    init(name: String, grade: String = "", subjects: String = "",
         strengths: String = "", focusAreas: String = "",
         interests: String = "", learningStyle: String = "", notes: String = ""){
        self.name = name
        self.grade = grade
        self.subjects = subjects
        self.strengths = strengths
        self.focusAreas = focusAreas
        self.interests = interests
        self.learningStyle = learningStyle
        self.notes = notes
    }
}
