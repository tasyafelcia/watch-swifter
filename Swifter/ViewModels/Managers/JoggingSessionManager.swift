//
//  JoggingSessionManager.swift
//  Swifter
//
//  Created by Adeline Charlotte Augustinne on 31/03/25.
//

import SwiftData
import Foundation

class JoggingSessionManager: ObservableObject {
    // Use an underscore for the private property
    private let _modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self._modelContext = modelContext
    }

    // Access to the model context for other managers
    var modelContext: ModelContext {
        return _modelContext
    }
    
    /// fetch all sessions, sorted by date
    func fetchAllSessions() -> [SessionModel] {
        let descriptor = FetchDescriptor<SessionModel>(
            sortBy: [SortDescriptor(\.startTime, order: .forward)]
        )
        return (try? _modelContext.fetch(descriptor)) ?? []
    }
    
    // Update the rest of your methods to use _modelContext instead of modelContext
    
    /// fetch the next upcoming session
    func fetchLatestSession() -> SessionModel? {
        let currDate = Date()
        
        /// check if session is upcoming or not
        let predicate = #Predicate<SessionModel> { session in
            session.startTime >= currDate
        }

        let descriptor = FetchDescriptor<SessionModel>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.startTime, order: .forward)]
        )
        
        return try? _modelContext.fetch(descriptor).first
    }
    
    /// fetch session by ID
    func fetchSessionById(id: PersistentIdentifier) -> SessionModel? {
        let predicate = #Predicate<SessionModel> { session in
            session.persistentModelID == id
        }
        
        let descriptor = FetchDescriptor<SessionModel>(
            predicate: predicate
        )

        return try? _modelContext.fetch(descriptor).first
    }
    
    func latestSession(for goal: GoalModel) -> SessionModel? {
        let startDate = goal.startDate
        let endDate = goal.endDate
        
        let fetchRequest = FetchDescriptor<SessionModel>(
            predicate: #Predicate {
                $0.startTime >= startDate && $0.startTime <= endDate
            }
        )

        do {
            let sessions = try _modelContext.fetch(fetchRequest)
            return sessions.sorted { $0.endTime > $1.endTime }.first
        } catch {
            print("Error fetching sessions within goal period: \(error)")
            return nil
        }
    }
    
    func createNewSession(storeManager: EventStoreManager, start: Date, end: Date, sessionType: SessionType) -> PersistentIdentifier? {
        if let id = storeManager.createNewEvent(eventTitle: sessionType.rawValue, startTime: start, endTime: end) {
            let newSession = SessionModel(startTime: start, endTime: end, calendarEventID: id, sessionType: sessionType)
            _modelContext.insert(newSession)
            do {
                try _modelContext.save()
                return newSession.persistentModelID
            } catch {
                print("error bro")
            }
        }
        return nil
    }
    
    /// update a session's starting and ending times
    func updateSessionTimes(id: PersistentIdentifier, newStart: Date, newEnd: Date, eventStoreManager: EventStoreManager){
        if let mySession = fetchSessionById(id: id){
            mySession.startTime = newStart
            mySession.endTime = newEnd
            eventStoreManager.setEventTimes(
                id: mySession.calendarEventID,
                newStart: newStart,
                newEnd: newEnd)
            
            do {
                try _modelContext.save()
                print("Session times succesfully updated")
                print("Start: \(mySession.startTime)")
                print("End: \(mySession.endTime)")
            } catch {
                print("Error updating session times")
            }
        }
    }
    
    /// update a session's status
    func updateSessionStatus(id: PersistentIdentifier, newStatus: isCompleted){
        if let mySession = fetchSessionById(id: id){
            mySession.status = newStatus
            
            do {
                try _modelContext.save()
                print("Updated status to: \(mySession.status)")
            } catch {
                print("Error updating status")
            }
        }
    }
    
    func deleteSession(session: SessionModel, eventStoreManager: EventStoreManager){
        let calendarEventID = session.calendarEventID
        
        _modelContext.delete(session)
        do {
            try _modelContext.save()
            print("successfully deleted")
        } catch {
            print("error \(error.localizedDescription)")
        }
        
        eventStoreManager.deleteSessionById(id: calendarEventID)
    }
    
    /// so other viewmodels can save context after updating a session
    func saveContext() {
        do {
            try _modelContext.save()
            print("context saved")
        } catch {
            print("error bro: \(error.localizedDescription)")
        }
    }
}