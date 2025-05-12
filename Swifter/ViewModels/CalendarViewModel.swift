//
//  CalendarViewModel.swift
//  Swifter
//
//  Created by Teuku Fazariz Basya on 03/04/25.
//

import Foundation
import SwiftUI
import EventKit

class CalendarViewModel: ObservableObject {
    private let eventStoreManager = EventStoreManager()
    private var sessionManager: JoggingSessionManager?
    
    @Published var events: [Int: [Event]] = [:]
    @Published var hasCalendarAccess = false
    
    init(sessionManager: JoggingSessionManager? = nil) {
        self.sessionManager = sessionManager
        checkCalendarAccess()
    }
    
    func setSessionManager(_ sessionManager: JoggingSessionManager) {
        self.sessionManager = sessionManager
    }

    func checkCalendarAccess(completion: ((Bool) -> Void)? = nil) {
        eventStoreManager.requestAccess { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.hasCalendarAccess = true
                    completion?(true)
                case .failure:
                    self.hasCalendarAccess = false
                    completion?(false)
                }
            }
        }
    }
    
    func fetchEventsForMonth(year: Int, month: Int) {
        guard hasCalendarAccess else { return }
        
        // Create date range for the entire month
        var startComponents = DateComponents()
        startComponents.year = year
        startComponents.month = month
        startComponents.day = 1
        startComponents.hour = 0
        startComponents.minute = 0
        
        var endComponents = DateComponents()
        endComponents.year = year
        endComponents.month = month + 1
        endComponents.day = 0  // Last day of month
        endComponents.hour = 23
        endComponents.minute = 59
        
        let calendar = Calendar.current
        let startDate = calendar.date(from: startComponents)!
        let endDate = calendar.date(from: endComponents)!
        
        // Fetch calendar events
        let predicate = eventStoreManager.eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        let ekEvents = eventStoreManager.eventStore.events(matching: predicate)
        
        // Convert to our Event model and organize by day
        var newEvents = [Int: [Event]]()
        
        for ekEvent in ekEvents {
            //skip all-day events
            if ekEvent.isAllDay {
                continue
            }
            
            let day = calendar.component(.day, from: ekEvent.startDate)
            
            // Create color from calendar color
            let calendarColor = Color(UIColor(cgColor: ekEvent.calendar.cgColor))
            
            let event = Event(
                title: ekEvent.title ?? "Untitled Event",
                startDate: ekEvent.startDate, // Use Date object
                endDate: ekEvent.endDate,     // Use Date object
                color: calendarColor
            )
            
            if newEvents[day] != nil {
                newEvents[day]?.append(event)
            } else {
                newEvents[day] = [event]
            }
        }
        
        DispatchQueue.main.async {
            self.events = newEvents
        }
    }
    
    func fetchEventsForDay(year: Int, month: Int, day: Int) -> [Event] {
        return events[day] ?? []
    }
    
    func hasEventsOnDay(day: Int) -> Bool {
        guard let dayEvents = events[day], !dayEvents.isEmpty else {
            return false
        }

        // filter jogging events
        let joggingKeywords = ["Pre-jogging", "Jogging", "Post-jogging"]
        return dayEvents.contains { event in
            joggingKeywords.contains { keyword in
                event.title.contains(keyword)
            }
        }
    }

    // In CalendarViewModel class
    func findSessionFromEvent(_ event: Event) -> SessionModel? {
        guard let sessionManager = sessionManager else { return nil }
        
        // Find the session that matches the event's time and title
        let allSessions = sessionManager.fetchAllSessions()
        return allSessions.first { session in
            let sameDay = Calendar.current.isDate(session.startTime, inSameDayAs: event.startDate)
            let closeStart = abs(session.startTime.timeIntervalSince(event.startDate)) < 60
            let closeEnd = abs(session.endTime.timeIntervalSince(event.endDate)) < 60
            return sameDay && closeStart && closeEnd
        }
    }
}
