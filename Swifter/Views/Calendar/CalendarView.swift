//
// CalendarView.swift
// Swifter
//
// Created by Teuku Fazariz Basya on 03/04/25.
//

import SwiftUI
import EventKit

struct Event: Identifiable {
    var id = UUID()
    var title: String
    var startDate: Date // Changed from time: String
    var endDate: Date   // Added endDate
    var color: Color = .blue
}

struct CalendarView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    // ViewModel to manage calendar data
    @StateObject private var viewModel = CalendarViewModel()
    
    // Initialize with the current date information
    @State private var selectedDate = Date()
    @State private var selectedDay: Int? = Calendar.current.component(.day, from: Date()) // Current day
    @State private var currentMonth = Calendar.current.component(.month, from: Date())
    @State private var currentYear = Calendar.current.component(.year, from: Date())
    @State private var showMonthPicker = false
    @State private var showYearPicker = false
    
    // New state variables for edit modal
    @State private var showEditSessionModal = false
    @State private var selectedEvent: Event? = nil
    @StateObject private var eventStoreManager = EventStoreManager()

    @Environment(\.modelContext) private var modelContext
    private var sessionManager: JoggingSessionManager {
        JoggingSessionManager(modelContext: modelContext)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Month and year header
            CalendarHeaderView(
                currentMonth: $currentMonth,
                currentYear: $currentYear,
                showMonthPicker: $showMonthPicker,
                showYearPicker: $showYearPicker,
                monthName: monthName
            )
            
            // Weekday headers
            WeekdayHeaderView()
            
            // Calendar days
            CalendarGridView(
                currentYear: currentYear,
                currentMonth: currentMonth,
                selectedDay: $selectedDay,
                hasEventsOnDay: viewModel.hasEventsOnDay,
                daysInMonth: daysInMonth
            )
            
            // Date display and edit button
            DateDisplayView(
                weekdayName: weekdayName,
                dayOfWeek: dayOfWeek,
                currentYear: currentYear,
                currentMonth: currentMonth,
                selectedDay: selectedDay ?? 1,
                monthNameShort: monthNameShort
            )
            
            // Time slots display
            if viewModel.hasCalendarAccess {
                EventsTimelineView(
                    viewModel: viewModel,
                    currentYear: currentYear,
                    currentMonth: currentMonth,
                    selectedDay: selectedDay ?? 1,
                    formatHour: formatHour,
                    formatTime: formatTime,
                    onEventTapped: { event in
                        selectedEvent = event
                        showEditSessionModal = true
                    }
                )
            } else {
                CalendarAccessView(checkAccess: {
                    viewModel.checkCalendarAccess { _ in }
                })
            }
            
            Spacer()
            
        }
        .background(Color(uiColor: .systemBackground))
        .foregroundColor(.primary)
        .gesture(createSwipeGesture())
        .onAppear{
            viewModel.setSessionManager(sessionManager)
            onAppearHandler()
        }
        .onChange(of: currentMonth, perform: onMonthChangeHandler)
        .onChange(of: currentYear, perform: onYearChangeHandler)
        .sheet(isPresented: $showEditSessionModal, onDismiss: {
            // Refresh the calendar data after editing
            viewModel.fetchEventsForMonth(year: currentYear, month: currentMonth)
            }) {
                if let event = selectedEvent, 
                let session = viewModel.findSessionFromEvent(event) {
                    EditSessionModal(selectedEvent: session)
                        .environmentObject(eventStoreManager)
                        .environmentObject(sessionManager)
                } else {
                    EditSessionModal()
                        .environmentObject(eventStoreManager)
                        .environmentObject(sessionManager)
                    }
            }
        
    }
    
    // MARK: - Event Handlers
    
    private func onAppearHandler() {
        viewModel.checkCalendarAccess { success in
            if success {
                viewModel.fetchEventsForMonth(year: currentYear, month: currentMonth)
            }
        }
    }
    
    private func onMonthChangeHandler(_ newMonth: Int) {
        viewModel.fetchEventsForMonth(year: currentYear, month: newMonth)
    }
    
    private func onYearChangeHandler(_ newYear: Int) {
        viewModel.fetchEventsForMonth(year: newYear, month: currentMonth)
    }
    
    private func createSwipeGesture() -> some Gesture {
        DragGesture()
            .onEnded { gesture in
                if gesture.translation.width > 100 {
                    // Swipe right - go to previous month
                    if currentMonth > 1 {
                        currentMonth -= 1
                    } else {
                        currentMonth = 12
                        currentYear -= 1
                    }
                } else if gesture.translation.width < -100 {
                    // Swipe left - go to next month
                    if currentMonth < 12 {
                        currentMonth += 1
                    } else {
                        currentMonth = 1
                        currentYear += 1
                    }
                }
            }
    }
    
    // Helper methods (keep existing implementation)
    private func daysInMonth() -> [Int] {
        var days = [Int]()
        
        // Get the first day of the month
        let firstDay = firstDayOfMonth(year: currentYear, month: currentMonth)
        
        // Add empty spaces for days of the previous month
        for _ in 0..<firstDay {
            days.append(0)
        }
        
        // Add days of the current month
        let numDays = numberOfDaysInMonth(year: currentYear, month: currentMonth)
        for day in 1...numDays {
            days.append(day)
        }
        
        return days
    }
    
    // Keep all other helper methods unchanged
    private func firstDayOfMonth(year: Int, month: Int) -> Int {
        // existing implementation
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        
        let date = Calendar.current.date(from: components)!
        return Calendar.current.component(.weekday, from: date) - 1
    }
    
    private func numberOfDaysInMonth(year: Int, month: Int) -> Int {
        // existing implementation
        var components = DateComponents()
        components.year = year
        components.month = month
        
        let date = Calendar.current.date(from: components)!
        return Calendar.current.range(of: .day, in: .month, for: date)!.count
    }
    
    private func dayOfWeek(year: Int, month: Int, day: Int) -> Int {
        // existing implementation
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        
        let date = Calendar.current.date(from: components)!
        return Calendar.current.component(.weekday, from: date)
    }
    
    private func monthName(for month: Int) -> String {
        // existing implementation
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        return dateFormatter.monthSymbols[month - 1]
    }
    
    private func monthNameShort(for month: Int) -> String {
        // existing implementation
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        return dateFormatter.shortMonthSymbols[month - 1]
    }
    
    private func weekdayName(for weekday: Int) -> String {
        // existing implementation
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        return dateFormatter.weekdaySymbols[weekday - 1]
    }
    
    private func formatHour(_ hour: Int) -> String {
        // existing implementation
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: Locale.current)
        
        let uses12HourFormat = formatter.dateFormat?.contains("a") ?? false
        
        if uses12HourFormat {
            if hour == 0 { return "12 AM" }
            if hour < 12 { return "\(hour) AM" }
            if hour == 12 { return "12 PM" }
            return "\(hour-12) PM"
        } else {
            return String(format: "%02d:00", hour)
        }
    }
    
    private func formatHourSimple(_ hour: Int) -> String {
        // existing implementation
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: Locale.current)
        
        let uses12HourFormat = formatter.dateFormat?.contains("a") ?? false
        
        if uses12HourFormat {
            if hour == 0 { return "12 AM" }
            if hour < 12 { return "\(hour) AM" }
            if hour == 12 { return "12 PM" }
            return "\(hour-12) PM"
        } else {
            return "\(hour):00"
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        // existing implementation
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

struct DayView: View {
    let day: Int
    let isSelected: Bool
    let hasEvents: Bool
    
    var body: some View {
        ZStack {
            // Background for all days (empty or visible)
            Rectangle()
                .fill(Color.clear)
                .frame(height: 40)
            
            // Selection indicator
            if isSelected {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.primary.opacity(0.2)) // Adapts to dark/light mode
                    .frame(height: 40)
            }
            
            // Day number
            Text("\(day)")
                .fontWeight(isSelected ? .bold : .regular)
                .foregroundColor(.primary) // Adapts to dark/light mode
            
            // Event indicator dot
            if hasEvents && !isSelected {
                Circle()
                    .fill(Color.accentColor) // Uses system accent color
                    .frame(width: 6, height: 6)
                    .offset(y: 14)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// Preview
struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
            .preferredColorScheme(.light)
    }
}

