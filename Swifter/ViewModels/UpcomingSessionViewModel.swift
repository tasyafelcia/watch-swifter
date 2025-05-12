//
//  UpcomingSessionViewModel.swift
//  Swifter
//
//  Created by Adeline Charlotte Augustinne on 05/04/25.
//

import Foundation

final class UpcomingSessionViewModel: ObservableObject {
    
    @Published var currentGoal: GoalModel
    @Published var nextPreJog: SessionModel?
    @Published var nextJog: SessionModel
    @Published var nextPostJog: SessionModel?
    
    /// no need to use published wrapper here
    /// because computed property uses published variables
    /// so if the published variables' values change, so will the computed property's
    var nextStart: Date {
        if let preJog = nextPreJog {
            return min(preJog.startTime, nextJog.startTime)
        } else {
            return nextJog.startTime
        }
    }
    
    var nextEnd: Date {
        if let postJog = nextPostJog {
            return max(postJog.endTime, nextJog.endTime)
        } else {
            return nextJog.endTime
        }
    }
    
    /// dummy data
    var timeUntil = TimeInterval(60)
    var days = 4
    
    /// sheet modality variables
    @Published var preferencesModalShown: Bool = false
    @Published var goalModalShown: Bool = false
    
    /// alert variables
    @Published var alertIsShown: Bool = false
    @Published var goalIsCompleted: Bool = false
    @Published var sessionIsChanged: Bool = false
    
    /// init with dummy data
    init(){
        self.currentGoal = GoalModel(targetFrequency: 3, startDate: Date(), endDate: Date()+3600*48+30*60)
        
        self.nextJog = SessionModel(startTime: Date()+3600*48, endTime: Date()+3600*48+30*60, calendarEventID: "lorem ipsum", sessionType: .jogging)
        
        self.currentGoal.progress = 2
    }
    
    func fetchData(goalManager: GoalManager, sessionManager: JoggingSessionManager) {
        if let goals = goalManager.fetchGoals() {
            let sortedGoals = goals.sorted(by: { $0.startDate > $1.startDate })
            if let currGoal = sortedGoals.first {
                self.currentGoal = currGoal
                print("goal start date is \(self.currentGoal.startDate)")
            }
        }
        
        let sessions = sessionManager.fetchAllSessions()
            .filter { $0.status == isCompleted.incomplete}
            .sorted(by: { $0.startTime < $1.startTime })
        
        self.nextPreJog = sessions.first(where: { $0.sessionType == .prejog })
        self.nextJog = sessions.first(where: { $0.sessionType == .jogging }) ?? self.nextJog
        self.nextPostJog = sessions.first(where: { $0.sessionType == .postjog })
        
        self.timeUntil = nextStart.timeIntervalSinceNow
        self.days = Int(ceil(timeUntil / 86400))
    }
    
    // MARK: - Watch Connectivity
    func sendSessionsToWatch(sessionManager: JoggingSessionManager) {
        // Get all sessions for today and tomorrow
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let twoDaysLater = calendar.date(byAdding: .day, value: 2, to: today)!
        
        let allSessions = sessionManager.fetchAllSessions()
        
        let relevantSessions = allSessions.filter { session in
            session.startTime >= today && session.startTime < twoDaysLater
        }
        
        // Send to watch
        WatchConnectivityManager.shared.sendSessionsToWatch(relevantSessions)
    }
    
    /// session functions
    func rescheduleSessions(
        eventStoreManager: EventStoreManager,
        preferencesManager: PreferencesManager,
        sessionManager: JoggingSessionManager
    ) {
        guard let preferences = preferencesManager.fetchPreferences() else { return }
        
        let totalDuration = nextEnd.timeIntervalSince(nextStart)
        
        if let newTimes = eventStoreManager.findDayOfWeek(currDate: nextEnd, duration: totalDuration, preferences: preferences, goal: currentGoal) {
            
            let newStart = newTimes[0]
            var cursor = newStart
            
            /// reschedule prejog
            if let preJog = nextPreJog {
                let duration = preJog.endTime.timeIntervalSince(preJog.startTime)
                let newEnd = cursor + duration
                eventStoreManager.setEventTimes(id: preJog.calendarEventID, newStart: cursor, newEnd: newEnd)
                preJog.startTime = cursor
                preJog.endTime = newEnd
                cursor = newEnd
            }
            
            /// reschedule jog
            let jogDuration = nextJog.endTime.timeIntervalSince(nextJog.startTime)
            let jogEnd = cursor + jogDuration
            eventStoreManager.setEventTimes(id: nextJog.calendarEventID, newStart: cursor, newEnd: jogEnd)
            nextJog.startTime = cursor
            nextJog.endTime = jogEnd
            cursor = jogEnd
            
            /// reschedule postjog
            if let postJog = nextPostJog {
                let duration = postJog.endTime.timeIntervalSince(postJog.startTime)
                let newEnd = cursor + duration
                eventStoreManager.setEventTimes(id: postJog.calendarEventID, newStart: cursor, newEnd: newEnd)
                postJog.startTime = cursor
                postJog.endTime = newEnd
                cursor = newEnd
            }
            
            sessionManager.saveContext()
            
            // Send updated sessions to watch
            sendSessionsToWatch(sessionManager: sessionManager)
        }
    }
    
    func markSessionAsComplete(sessionManager: JoggingSessionManager, goalManager: GoalManager) -> Bool {
        currentGoal.progress += 1
        if let prejog = nextPreJog{
            prejog.status = isCompleted.completed
        }
        if let postjog = nextPostJog {
            postjog.status = isCompleted.completed
        }
        nextJog.status = isCompleted.completed
        
        sessionManager.saveContext()
        goalManager.saveContext()
        
        // Send updated sessions to watch
        sendSessionsToWatch(sessionManager: sessionManager)
        
        return checkIfGoalCompleted()
    }
    
    func wipeAllSessionsRelatedToGoal(sessionManager: JoggingSessionManager, eventStoreManager: EventStoreManager) {
        let goalStart = currentGoal.startDate
        let goalEnd = currentGoal.endDate
        
        let sessionsToDelete = sessionManager.fetchAllSessions().filter { session in
            session.startTime >= goalStart && session.startTime <= goalEnd
        }
        
        sessionsToDelete.forEach { session in
            sessionManager.deleteSession(session: session, eventStoreManager: eventStoreManager)
        }
        
        // Send updated sessions to watch after deletion
        sendSessionsToWatch(sessionManager: sessionManager)
    }
    
    func createNewSession(sessionManager: JoggingSessionManager, storeManager: EventStoreManager, preferencesManager: PreferencesManager){
        guard let preferences = preferencesManager.fetchPreferences() else {
            return
        }
        
        let timeOnFeet = preferences.jogDuration
        let preJog = preferences.preJogDuration
        let postJog = preferences.postJogDuration
        
        
        let calendar = Calendar.current
        let baseDate: Date

        if let latest = sessionManager.latestSession(for: currentGoal) {
            baseDate = latest.endTime
        } else {
            baseDate = currentGoal.startDate
        }
        print("base date: \(baseDate)")

        guard let nextDay = calendar.date(byAdding: .day, value: 1, to: baseDate),
              let startOfNextDay = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: nextDay) else {
            print("Failed to calculate start date for session scheduling")
            return
        }

        let duration: Int
        if (preJog > 0 && postJog > 0){
            duration = timeOnFeet + preJog + postJog
            //            print("prejog and postjog")
            if let availDate = storeManager.findDayOfWeek(currDate: startOfNextDay, duration: TimeInterval(duration*60), preferences: preferences, goal: currentGoal){
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
            if let availDate = storeManager.findDayOfWeek(currDate: startOfNextDay, duration: TimeInterval(duration*60), preferences: preferences, goal: currentGoal){
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
            if let availDate = storeManager.findDayOfWeek(currDate: startOfNextDay, duration: TimeInterval(duration*60), preferences: preferences, goal: currentGoal){
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
            if let availDate = storeManager.findDayOfWeek(currDate: startOfNextDay, duration: TimeInterval(duration*60), preferences: preferences, goal: currentGoal){
                /// create jog event
                sessionManager.createNewSession(
                    storeManager: storeManager,
                    start: availDate[0],
                    end: availDate[0]+TimeInterval(timeOnFeet*60),
                    sessionType: SessionType.jogging)
            }
        }
        
        // Send newly created sessions to watch
        sendSessionsToWatch(sessionManager: sessionManager)
    }
    
    /// goal functions
    func createNewGoal(goalManager: GoalManager){
        if let myGoal = goalManager.createNewGoal(
            targetFreq: currentGoal.targetFrequency,
            startingDate: currentGoal.endDate + 24*60*60,
            endingDate: currentGoal.endDate + 8*24*60*60){
            self.currentGoal = myGoal
        }
    }
    
    func markGoalAsComplete(goalManager: GoalManager) {
        self.currentGoal.status = GoalStatus.completed
        goalManager.saveContext()
    }
    
    func checkIfGoalCompleted() -> Bool{
        return currentGoal.progress >= currentGoal.targetFrequency
    }
}
