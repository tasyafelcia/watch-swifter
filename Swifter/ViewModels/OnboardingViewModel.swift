//
//  OnboardingViewModel.swift
//  Swifter
//
//  Created by Adeline Charlotte Augustinne on 06/04/25.
//

import Foundation

final class OnboardingViewModel: ObservableObject {
    
    @Published var currentGoal: GoalModel
    @Published var preferences: PreferencesModel
    
    /// init with dummy data
    init() {
        self.currentGoal = GoalModel(targetFrequency: 3, startDate: Date(), endDate: Date()+3600*48+30*60)
        self.preferences = PreferencesModel(timeOnFeet: 25)
    }
    
    func fetchData(goalManager: GoalManager, preferencesManager: PreferencesManager){
        if let currGoal = goalManager.fetchGoals()?.first {
            currentGoal = currGoal
        }
        
        if let preferences = preferencesManager.fetchPreferences() {
            self.preferences = preferences
        }
    }
    
    func scheduleFirstJog(sessionManager: JoggingSessionManager, storeManager: EventStoreManager){
        let timeOnFeet = preferences.jogDuration
        let preJog = preferences.preJogDuration
        let postJog = preferences.postJogDuration
        
        let duration: Int
        if (preJog > 0 && postJog > 0){
            duration = timeOnFeet + preJog + postJog
//            print("prejog and postjog")
            if let availDate = storeManager.findDayOfWeek(currDate: Date(), duration: TimeInterval(duration*60), preferences: preferences, goal: currentGoal){
                /// create prejog event
                sessionManager.createNewSession(
                    storeManager: storeManager,
                    start: availDate[0],
                    end: availDate[0]+TimeInterval(preJog*60),
                    sessionType: SessionType.prejog)
                /// create jog event
                sessionManager.createNewSession(
                    storeManager: storeManager,
                    start: availDate[0]+TimeInterval(preJog*60),
                    end: availDate[0]+TimeInterval(preJog*60)+TimeInterval(timeOnFeet*60),
                    sessionType: SessionType.jogging)
                /// create postjog event
                sessionManager.createNewSession(
                    storeManager: storeManager,
                    start: availDate[0]+TimeInterval(preJog*60)+TimeInterval(timeOnFeet*60),
                    end: availDate[0]+TimeInterval(preJog*60)+TimeInterval(timeOnFeet*60)+TimeInterval(postJog*60),
                    sessionType: SessionType.postjog)
            }
        } else if (preJog > 0) {
            duration = timeOnFeet + preJog
//            print("prejog")
            if let availDate = storeManager.findDayOfWeek(currDate: Date(), duration: TimeInterval(duration*60), preferences: preferences, goal: currentGoal){
                /// create prejog event
                sessionManager.createNewSession(
                    storeManager: storeManager,
                    start: availDate[0],
                    end: availDate[0]+TimeInterval(preJog*60),
                    sessionType: SessionType.prejog)
                /// create jog event
                sessionManager.createNewSession(
                    storeManager: storeManager,
                    start: availDate[0]+TimeInterval(preJog*60),
                    end: availDate[0]+TimeInterval(preJog*60)+TimeInterval(timeOnFeet*60),
                    sessionType: SessionType.jogging)
            }
        } else if (postJog > 0){
            duration = timeOnFeet + postJog
//            print("postjog")
            if let availDate = storeManager.findDayOfWeek(currDate: Date(), duration: TimeInterval(duration*60), preferences: preferences, goal: currentGoal){
                /// create jog event
                sessionManager.createNewSession(
                    storeManager: storeManager,
                    start: availDate[0],
                    end: availDate[0]+TimeInterval(timeOnFeet*60),
                    sessionType: SessionType.jogging)
                /// create post jog event
                sessionManager.createNewSession(
                    storeManager: storeManager,
                    start: availDate[0]+TimeInterval(timeOnFeet*60),
                    end: availDate[0]+TimeInterval(timeOnFeet*60)+TimeInterval(postJog*60),
                    sessionType: SessionType.postjog)
            }
        } else {
            duration = timeOnFeet
            if let availDate = storeManager.findDayOfWeek(currDate: Date(), duration: TimeInterval(duration*60), preferences: preferences, goal: currentGoal){
                /// create jog event
                sessionManager.createNewSession(
                    storeManager: storeManager,
                    start: availDate[0],
                    end: availDate[0]+TimeInterval(timeOnFeet*60),
                    sessionType: SessionType.jogging)
            }
        }
    }
}
