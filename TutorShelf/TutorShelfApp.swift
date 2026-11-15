//
//  TutorShelfApp.swift
//  TutorShelf
//
//  Created by yulicia kwok on 2026-11-15.
//

import SwiftUI
import SwiftData

@main
struct TutorShelfApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Student.self)
    }
}
