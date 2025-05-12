//
//  ContentView.swift
//  Swifter
//
//  Created by Adeline Charlotte Augustinne on 24/03/25.
//

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
        
        Group{
            if(isNewUser) {
                OnboardStart()
            } else {
                TabView {
                    NavigationStack{
                        UpcomingSession()
                    }.tabItem {
                        Label("Upcoming", systemImage: "house")
                    }
                    CalendarView()
                        .tabItem {
                            Label("Calendar", systemImage: "calendar")
                        }
                }
            }
        }.onAppear {
                if let userJogDuration = preferencesManager.fetchPreferences()?.jogDuration,
                   let userGoals = goalManager.fetchGoals() {
                    isNewUser = false
                    print(userJogDuration)
                    print(userGoals)
                } else {
                    isNewUser = true
                }
            print(isNewUser)
        }
    }
}

#Preview {
    ContentView()
}
