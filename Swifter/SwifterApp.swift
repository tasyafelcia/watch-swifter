//  SwifterApp.swift
//  Fixed version - properly accessing ModelContext

import SwiftUI
import SwiftData

@main
struct SwifterApp: App {
    
    @StateObject private var eventStoreManager = EventStoreManager()
    @StateObject private var watchConnectivity = WatchConnectivityManager.shared
    
    // Create the model container
    let modelContainer: ModelContainer = {
        do {
            return try ModelContainer(for: PreferencesModel.self, GoalModel.self, SessionModel.self)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(eventStoreManager)
                .environmentObject(watchConnectivity)
                .onAppear {
                    // Pass the model context to watch connectivity
                    watchConnectivity.setModelContext(modelContainer.mainContext)
                }
        }
        .modelContainer(modelContainer)
    }
}
