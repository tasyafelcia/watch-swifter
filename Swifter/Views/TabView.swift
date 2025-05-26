// Swifter/Views/TabView.swift
import SwiftUI

struct ContentView: View {

    @Environment(\.modelContext) private var modelContext
    private var goalManager: GoalManager {
        GoalManager(modelContext: modelContext)
    }
    private var preferencesManager: PreferencesManager {
        PreferencesManager(modelContext: modelContext)
    }

    @AppStorage("isNewUser") private var isNewUser: Bool = false

    var body: some View {
        Group {
            if(isNewUser) {
                OnboardStart()
            } else {
                TabView {
                    // Tab Upcoming Session
                    NavigationStack { // PENTING: Bungkus dengan NavigationStack
                        UpcomingSession()
                    }
                    .tabItem {
                        Label("Sessions", systemImage: "figure.run")
                    }

                    // Tab Kalender
                    NavigationStack { // Konsisten untuk semua tab
                        CalendarView()
                    }
                    .tabItem {
                        Label("Calendar", systemImage: "calendar")
                    }
                    
                    // Tab Analytics (Summary Page)
                    NavigationStack { // Konsisten untuk semua tab
                        AnalyticsView() // Pastikan AnalyticsView sudah ada
                    }
                    .tabItem {
                        Label("Summary", systemImage: "chart.bar.xaxis") // Ikon untuk ringkasan/analitik
                    }
                }
                // Anda bisa menambahkan .accentColor di sini untuk TabView jika ingin
                // .accentColor(Color.green) // Misalnya
                .onAppear {
                    if preferencesManager.fetchPreferences() == nil || goalManager.fetchGoals()?.isEmpty ?? true {
                        isNewUser = true
                    } else {
                        isNewUser = false
                    }
                    print("Is new user: \(isNewUser)")
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(EventStoreManager()) // Jika ContentView atau turunannya butuh ini
        // .modelContainer(for: [PreferencesModel.self, GoalModel.self, SessionModel.self], inMemory: true) // Untuk data preview
}
