//  SwifterApp.swift
//  Update your existing SwifterApp.swift

import SwiftUI

@main
struct SwifterApp: App {
    
    @StateObject private var eventStoreManager = EventStoreManager()
    @StateObject private var watchConnectivity = WatchConnectivityManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(eventStoreManager)
                .environmentObject(watchConnectivity)
        }
        .modelContainer(for: [PreferencesModel.self, GoalModel.self, SessionModel.self])
    }
}
