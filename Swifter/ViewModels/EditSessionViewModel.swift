//
//  EditSessionViewModel.swift
//  Swifter
//
//  Created by Adeline Charlotte Augustinne on 27/03/25.
//

import Foundation
import SwiftUI
import EventKit

final class EditSessionViewModel: ObservableObject {
    
    // injected event store manager
    var eventStoreManager: EventStoreManager
    
    // Selected session properties
    @Published var selectedSession: SessionModel?
    @Published var relatedSessions: [SessionModel] = []
    
    // New scheduled time for the session(s)
    @Published var newStartTime: Date = Date()
    
    // Current goal
    @Published var currentGoal: GoalModel?
    @Published var isOutsideGoalDate: Bool = false
    
    init(
        // set with initial values
        eventStoreManager: EventStoreManager
    ) {
        self.eventStoreManager = eventStoreManager
    }
    
    // Load session and related sessions (pre/post jog)
    func loadSession(session: SessionModel, sessionManager: JoggingSessionManager, goalManager: GoalManager) {
        self.selectedSession = session
        self.newStartTime = session.startTime
        
        // Find related sessions based on timing
        findRelatedSessions(session: session, sessionManager: sessionManager)
        
        // Load the current goal
        if let goals = goalManager.fetchGoals() {
            self.currentGoal = goals.sorted(by: { $0.startDate > $1.startDate }).first
        }
    }
    
    // Find sessions that are related (immediately before/after)
    private func findRelatedSessions(session: SessionModel, sessionManager: JoggingSessionManager) {
        // Existing implementation
        relatedSessions = []
        let allSessions = sessionManager.fetchAllSessions()
        
        for s in allSessions {
            if s.persistentModelID != session.persistentModelID {
                if abs(s.endTime.timeIntervalSince(session.startTime)) < 60 || 
                   abs(s.startTime.timeIntervalSince(session.endTime)) < 60 {
                    relatedSessions.append(s)
                }
            }
        }
        
        relatedSessions.sort { $0.startTime < $1.startTime }
    }
    
    // Check if the new date is outside of the goal's timeframe
    func checkDateConstraint() -> Bool {
        guard let goal = currentGoal,
              let mainSession = selectedSession else { 
            return false 
        }
        
        let timeDifference = newStartTime.timeIntervalSince(mainSession.startTime)
        let newEndDate = mainSession.endTime.addingTimeInterval(timeDifference)
        
        // Check if the new date range is outside the goal dates
        isOutsideGoalDate = newStartTime < goal.startDate || newEndDate > goal.endDate
        return isOutsideGoalDate
    }
    
    // Reschedule the selected session and its related sessions
    func rescheduleSession(sessionManager: JoggingSessionManager) -> Bool {
        guard let mainSession = selectedSession else { return false }
        
        // Find all sessions in chronological order
        var sessionsToUpdate = [mainSession] + relatedSessions
        sessionsToUpdate.sort { $0.startTime < $1.startTime }
        
        // Calculate the time difference between current and new start time
        let timeDifference = newStartTime.timeIntervalSince(sessionsToUpdate.first!.startTime)
        
        // Update each session
        for session in sessionsToUpdate {
            let newStart = session.startTime.addingTimeInterval(timeDifference)
            let newEnd = session.endTime.addingTimeInterval(timeDifference)
            
            // Print for debugging
            print("Updating session: \(session.sessionType.rawValue)")
            print("From: \(session.startTime) - \(session.endTime)")
            print("To: \(newStart) - \(newEnd)")
            print("Calendar EventID: \(session.calendarEventID)")
            
            // Update in calendar
            eventStoreManager.setEventTimes(
                id: session.calendarEventID,
                newStart: newStart,
                newEnd: newEnd
            )
            
            // Update model
            session.startTime = newStart
            session.endTime = newEnd
        }
        
        // Save changes
        sessionManager.saveContext()
        
        // Print success message
        print("Rescheduled \(sessionsToUpdate.count) sessions successfully")
        return true
    }
}