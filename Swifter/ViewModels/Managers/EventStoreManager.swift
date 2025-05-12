//
//  EventStoreManager.swift
//  Swifter
//
//  Created by Adeline Charlotte Augustinne on 26/03/25.
//

import Foundation
import EventKit

// error handling
enum CalendarErrors: Error {
    case accessNotGranted
    
    var errorDescription: String? {
        switch self {
            case .accessNotGranted:
                return "Calendar access is not granted!"
        }
    }
}

final class EventStoreManager: ObservableObject {
    let eventStore = EKEventStore()
    
    func checkCalendarAccess() throws{
        /// check if calendar access granted?
        guard EKEventStore.authorizationStatus(for: .event) == .authorized else {
            throw CalendarErrors.accessNotGranted
            return
        }
    }
    
    func requestAccess(completion: @escaping (Result<Void, Error>) -> Void) {
        eventStore.requestAccess(to: .event) { granted, error in
            if granted {
                completion(.success(()))
            } else {
                completion(.failure(error ?? CalendarErrors.accessNotGranted))
            }
        }
    }
    
    /// create a new event, return the event's ID to be used as value for the jogging session instance's property
    func createNewEvent(
        eventTitle: String,
        startTime: Date,
        endTime: Date
    ) -> String? {
        let event = EKEvent(eventStore: eventStore)
        event.title = eventTitle
        event.startDate = startTime
        event.endDate = endTime
        
        // fallback to the first writable calendar if default is nil
        if let defaultCalendar = eventStore.defaultCalendarForNewEvents {
            event.calendar = defaultCalendar
        } else if let fallbackCalendar = eventStore.calendars(for: .event).first(where: { $0.allowsContentModifications }) {
            event.calendar = fallbackCalendar
        }
        
        do {
            try eventStore.save(event, span: .thisEvent)
            print("new jogging event saved")
        } catch {
            print("error saving calendar event: \(error.localizedDescription)")
            return nil
        }
        
        return event.eventIdentifier
    }
    
    // find an event by id
    func findEventById(id: String) -> EKEvent? {
        if let event = eventStore.event(withIdentifier: id) {
            return event
        }
        return nil
    }
    
    
    // update an event's start & end times
    func setEventTimes(id: String, newStart: Date, newEnd: Date){
        if let event = findEventById(id: id){
            event.startDate = newStart
            event.endDate = newEnd
            
            do {
                   try eventStore.save(event, span: .thisEvent, commit: true)
                   print("calendar event updated")
               } catch {
                   print("error bro")
               }
        }
    }
    
    func deleteSessionById(id: String){
        if let event = findEventById(id: id){
            do {
                try eventStore.remove(event, span: .thisEvent, commit: true)
                print("calendar event deleted")
            } catch {
                print("error bro \(error.localizedDescription)")
            }
        }
    }
    
    /// algorithm functions
    func findAvailableSlot(
        currDate: Date,
        events: [EKEvent],
        start: Date,
        end: Date,
        duration: TimeInterval
    ) -> [Date]? {
        var possibleTimes: [(start: Date, end: Date)] = []
        var lastEndTime = start
        
        /// check if free time is available between 6AM (start of day) and before the FIRST event
        if let firstEvent = events.first, firstEvent.startDate.timeIntervalSince(start) >= duration {
            possibleTimes.append((start, firstEvent.startDate))
        }

        /// iterate through all events to check if time between events is enough for allotting a session
        for event in events {
            
            /// only update lastEndTime when an event truly extends beyond the previous one
            /// so we ignore events whose duration is still within another event
            if event.endDate > lastEndTime {
                if event.startDate.timeIntervalSince(lastEndTime) >= duration {
                    possibleTimes.append((lastEndTime, event.startDate))
                }
                
                /// if two events exist where event B starts before event A ends, then we consider the end time which is later only
                lastEndTime = max(lastEndTime, event.endDate)
            }
        }

        /// check if free time is available between after LAST event and 9PM (end of day)
        if end.timeIntervalSince(lastEndTime) >= duration {
            possibleTimes.append((lastEndTime, end))
        }
        
        let validSlots = possibleTimes.filter { $0.start > currDate }
        
        /// if no possible time then return check other day to the function caller
        guard !validSlots.isEmpty else {
            print("No free time available to schedule jog.")
            return nil
        }
        
        return [validSlots.first!.start, validSlots.first!.start + duration]
    }
    
    func findSlotInDay(currDate: Date, date: Date, duration: TimeInterval, preferences: PreferencesModel) -> [Date]?{
        let calendar = Calendar.current
        
        /// day constraints definition as:
        /// - start of day for running: 6AM
        /// - end of day for running: 9PM
        let startOfDay = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: date)!
        let endOfDay = calendar.date(bySettingHour: 21, minute: 0, second: 0, of: date)!

        /// retrieve all the events in the calendar local DB
        let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: nil)
        let events = eventStore.events(matching: predicate)
            .filter { !$0.isAllDay } /// --> ignore all-day events like Core Challenge or holiday
            .sorted { $0.startDate < $1.startDate } /// sort ascending by start time
        
        /// define time of day constraints as
        /// morning: 6AM - 11AM
        /// noon: 12PM - 2PM
        /// afternoon: 3PM - 6PM
        /// evening: 7PM - 9PM

        /// iterate through preferences first
        var start: Date
        var end: Date
        if (preferences.preferredTimesOfDay.contains(.morning)){
            start = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: date)!
            end = calendar.date(bySettingHour: 11, minute: 59, second: 59, of: date)!
            if let available = findAvailableSlot(currDate: currDate, events: events, start: start, end: end, duration: duration) {
                return available
            }
        } else if (preferences.preferredTimesOfDay.contains(.noon)){
            start = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date)!
            end = calendar.date(bySettingHour: 14, minute: 59, second: 59, of: date)!
            if let available = findAvailableSlot(currDate: currDate, events: events, start: start, end: end, duration: duration) {
                return available
            }
        } else if (preferences.preferredTimesOfDay.contains(.afternoon)){
            start = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: date)!
            end = calendar.date(bySettingHour: 18, minute: 59, second: 59, of: date)!
            if let available = findAvailableSlot(currDate: currDate, events: events, start: start, end: end, duration: duration) {
                return available
            }
        } else if (preferences.preferredTimesOfDay.contains(.evening)){
            start = calendar.date(bySettingHour: 19, minute: 0, second: 0, of: date)!
            end = calendar.date(bySettingHour: 21, minute: 0, second: 0, of: date)!
            if let available = findAvailableSlot(currDate: currDate, events: events, start: start, end: end, duration: duration) {
                return available
            }
        }
        
        /// iterate through the whole day if all preferred timeslots are unavailable
        if let available = findAvailableSlot(currDate: currDate, events: events, start: startOfDay, end: endOfDay, duration: duration) {
            return available
        }
        
        return nil
    }
    
    func findDayOfWeek(currDate: Date, duration: TimeInterval, preferences: PreferencesModel, goal: GoalModel) -> [Date]?{
        let calendar = Calendar.current

        /// iterate through preferred days
        for i in 0...7 {
            guard let tempDay = calendar.date(byAdding: .day, value: i, to: currDate) else { continue }

            if(tempDay<goal.startDate || tempDay>goal.endDate) { continue }
            
            let weekdayNumber = calendar.component(.weekday, from: tempDay)
            guard let weekdayEnum = DayOfWeek(rawValue: weekdayNumber) else { continue }

            if preferences.preferredDaysOfWeek?.contains(weekdayEnum) == true,
                let availableTime = findSlotInDay(currDate: currDate, date: tempDay, duration: duration, preferences: preferences) {
                return availableTime
            }
        }
        
        /// iterate through all days
        for i in 0...7 {
            guard let tempDay = calendar.date(byAdding: .day, value: i, to: currDate) else { continue }

            if(tempDay<goal.startDate || tempDay>goal.endDate) { continue }

            if let availableTime = findSlotInDay(currDate: currDate, date: tempDay, duration: duration, preferences: preferences) {
                return availableTime
            }
        }
        
        return nil
    }
}

