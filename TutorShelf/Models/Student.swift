import SwiftData
import Foundation

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
    var colorName: String = ""
    var lessonWeekday: Int = 0
    var lessonTime: Date = Date()
    var reportOverviews: [String: String] = [:]
    var level: String = "Intermediate"
    var worksheetStyle: String = "Classic"
    
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

extension Student {
    var nextRegularLesson: Date? {
        guard lessonWeekday > 0 else { return nil }

        let time = Calendar.current.dateComponents([.hour, .minute], from: lessonTime)
        var match = DateComponents()
        match.weekday = lessonWeekday
        match.hour = time.hour
        match.minute = time.minute

        let lastPlanned = lessons.filter { $0.isPlanned }.map { $0.date }.max()
        let start = max(Date(), lastPlanned ?? Date())

        return Calendar.current.nextDate(after: start, matching: match, matchingPolicy: .nextTime)
    }
    static func level(forGrade grade: String) -> String {
        let digits = grade.filter { $0.isNumber }
        guard let number = Int(digits) else { return "Primary" }   // "K" or blank
        switch number {
        case ...3: return "Primary"
        case 4...7: return "Intermediate"
        default: return "Secondary"
        }
    }
}
