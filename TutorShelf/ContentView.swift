import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Student.name) private var students: [Student]
    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(students) { student in
                    NavigationLink {
                        StudentDetailView(student: student)
                    } label: {
                        HStack(spacing: 12) {
                            Text(String(student.name.prefix(1)))
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(width: 40, height: 40)
                                .background(.indigo, in: Circle())

                            VStack(alignment: .leading) {
                                Text(student.name).font(.headline)
                                Text(student.grade)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .onDelete { offsets in
                    for index in offsets {
                        context.delete(students[index])
                    }
                }
            }
            .navigationTitle("Students")
            .toolbar {
                            Button("Add", systemImage: "plus") {
                                showingAdd = true
                            }
                        }
                        .sheet(isPresented: $showingAdd) {
                            AddStudentView()
                        }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Student.self, inMemory: true)
}
