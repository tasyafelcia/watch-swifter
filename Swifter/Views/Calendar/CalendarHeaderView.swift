//
//  CalendarHeaderView.swift
//  Swifter
//
//  Created by Teuku Fazariz Basya on 05/04/25.
//

import SwiftUI

import SwiftUI

// MARK: - Calendar Header View
struct CalendarHeaderView: View {
    @Binding var currentMonth: Int
    @Binding var currentYear: Int
    @Binding var showMonthPicker: Bool
    @Binding var showYearPicker: Bool
    let monthName: (Int) -> String
    
    var body: some View {
        HStack {
            // Month and Year together
            HStack(spacing: 8) { // Group month and year
                // Month with picker
                Button(action: {
                    showMonthPicker = true
                }) {
                    Text("\(monthName(currentMonth))")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                .sheet(isPresented: $showMonthPicker) {
                    VStack(spacing: 20) {
                        Text("Select Month")
                            .font(.headline)
                            .padding(.top)
                        
                        Picker("Month", selection: $currentMonth) {
                            ForEach(1...12, id: \.self) { month in
                                Text(monthName(month))
                            }
                        }
                        .pickerStyle(.wheel)
                        
                        Button("Done") {
                            showMonthPicker = false
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                    .presentationDetents([.height(250)])
                }
                
                // Year with picker (now next to month)
                Button(action: {
                    showYearPicker = true
                }) {
                    Text(String(format: "%d", currentYear))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                .sheet(isPresented: $showYearPicker) {
                    VStack(spacing: 20) {
                        Text("Select Year")
                            .font(.headline)
                            .padding(.top)
                        
                        Picker("Year", selection: $currentYear) {
                            ForEach((currentYear-10)...(currentYear+10), id: \.self) { year in
                                Text(String(format: "%d", year))
                            }
                        }
                        .pickerStyle(.wheel)
                        
                        Button("Done") {
                            showYearPicker = false
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                    .presentationDetents([.height(250)])
                }
            }
            
            Spacer() // Pushes chevrons to the right
            
            // Month navigation chevrons
            HStack(spacing: 20) {
                Button(action: {
                    changeMonth(by: -1)
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                
                Button(action: {
                    changeMonth(by: 1)
                }) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(.horizontal)
        .padding(.top)
    }

    // Helper function to change month and year
    private func changeMonth(by amount: Int) {
        let newMonth = currentMonth + amount
        if newMonth > 12 {
            currentMonth = 1
            currentYear += 1
        } else if newMonth < 1 {
            currentMonth = 12
            currentYear -= 1
        } else {
            currentMonth = newMonth
        }
    }
}

// MARK: - Weekday Header View
struct WeekdayHeaderView: View {
    var body: some View {
        HStack(spacing: 0) {
            ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                Text(day)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .padding(.top, 20)
        .padding(.bottom, 10)
    }
}

// MARK: - Calendar Grid View
struct CalendarGridView: View {
    let currentYear: Int
    let currentMonth: Int
    @Binding var selectedDay: Int?
    let hasEventsOnDay: (Int) -> Bool
    let daysInMonth: () -> [Int]
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
            ForEach(daysInMonth(), id: \.self) { day in
                if day > 0 {
                    DayView(day: day, isSelected: day == selectedDay, hasEvents: hasEventsOnDay(day))
                        .onTapGesture {
                            selectedDay = day
                        }
                } else {
                    // Empty space for days not in current month
                    Text("")
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Date Display View
struct DateDisplayView: View {
    let weekdayName: (Int) -> String
    let dayOfWeek: (Int, Int, Int) -> Int
    let currentYear: Int
    let currentMonth: Int
    let selectedDay: Int
    let monthNameShort: (Int) -> String
    
    var body: some View {
        HStack {
            Text("\(weekdayName(dayOfWeek(currentYear, currentMonth, selectedDay))), \(selectedDay) \(monthNameShort(currentMonth)) \(String(format: "%d", currentYear))")
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
            
            Image(systemName: "pencil")
                .foregroundColor(.gray)
        }
        .padding()
        .padding(.top)
    }
}

// MARK: - Events Timeline View
struct EventsTimelineView: View {
    let viewModel: CalendarViewModel
    let currentYear: Int
    let currentMonth: Int
    let selectedDay: Int
    let formatHour: (Int) -> String
    let formatTime: (Date) -> String
    
    // Zoom state management
    @State private var hourHeight: CGFloat = 200.0
    @State private var lastScale: CGFloat = 1.0
    private let baselineHourHeight: CGFloat = 200.0
    private let maxHourHeight: CGFloat = 400.0
    
    // State for autoscrolling
    @State private var targetScrollAnchorId: String? = nil // ID of the anchor to scroll to
    @State private var didScrollForDay = false // Flag to prevent multiple scrolls for the same day
    
    // Define anchor spacing for scroll points
    private let anchorSpacing: CGFloat = 50 // Adjust spacing as needed
    
    let onEventTapped: (Event) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in // Add ScrollViewReader
                ScrollView {
                    // Fetch events for the current view state
                    let events = viewModel.fetchEventsForDay(year: currentYear, month: currentMonth, day: selectedDay)
                    
                    ZStack(alignment: .topLeading) {
                        // Invisible anchors for scrolling targets
                        VStack(spacing: 0) {
                            // Create anchors covering the full 24-hour height based on current hourHeight
                            ForEach(0..<Int(ceil(24 * hourHeight / anchorSpacing)), id: \.self) { index in
                                Color.clear
                                    .frame(height: anchorSpacing)
                                    .id("anchor_\(Int(CGFloat(index) * anchorSpacing))") // Unique ID based on Y position
                            }
                        }
                        .frame(height: 24 * hourHeight) // Ensure anchors cover the full scrollable height

                        // Base hour grid
                        HourGridView(formatHour: formatHour, hourHeight: hourHeight)
                        
                        // Events overlay
                        EventsOverlayView(
                            events: events,
                            formatTime: formatTime,
                            hourHeight: hourHeight,
                            onEventTapped: onEventTapped
                        )
                    }
                    .frame(height: 24 * hourHeight)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hourHeight)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                let delta = value / lastScale
                                lastScale = value
                                
                                // Calculate new height, respecting min/max bounds
                                let newHeight = hourHeight * delta
                                hourHeight = min(max(newHeight, baselineHourHeight), maxHourHeight)
                            }
                            .onEnded { _ in
                                // Reset the last scale when gesture ends
                                lastScale = 1.0
                            }
                    )
                }
                .onChange(of: targetScrollAnchorId) { oldId, newId in // Scroll when anchor ID changes
                    if let anchorId = newId {
                        // Use DispatchQueue to ensure scrolling happens after the view update
                        DispatchQueue.main.async {
                           withAnimation {
                                // Scroll to the anchor point slightly above the event
                                proxy.scrollTo(anchorId, anchor: .top)
                           }
                        }
                    }
                }
                .onAppear { // Scroll on initial appearance
                    findAndSetScrollTarget(events: viewModel.fetchEventsForDay(year: currentYear, month: currentMonth, day: selectedDay))
                }
                .onChange(of: selectedDay) { // Reset and scroll when day changes
                    didScrollForDay = false // Reset flag for the new day
                    findAndSetScrollTarget(events: viewModel.fetchEventsForDay(year: currentYear, month: currentMonth, day: selectedDay))
                }
                 .onChange(of: hourHeight) { // Re-calculate scroll target if zoom changes
                     // Recalculate target based on new hourHeight if a target was previously set
                     if targetScrollAnchorId != nil {
                         findAndSetScrollTarget(events: viewModel.fetchEventsForDay(year: currentYear, month: currentMonth, day: selectedDay), forceRecalculate: true)
                     }
                 }
            }
        }
    }
    
    // Find the first jogging-related event and set the scroll target anchor ID
    private func findAndSetScrollTarget(events: [Event], forceRecalculate: Bool = false) {
        // Only scroll automatically once per day selection unless forced by zoom
        guard !didScrollForDay || forceRecalculate else { return }

        if let joggingEvent = findFirstJoggingEvent(events: events) {
            let targetY = calculateScrollTargetPosition(for: joggingEvent.startDate)
            // Find the nearest anchor ID at or just above the target position
            let anchorY = floor(targetY / anchorSpacing) * anchorSpacing
            let newAnchorId = "anchor_\(Int(anchorY))"
            
            // Only update if the anchor ID changes or if forced
            if newAnchorId != targetScrollAnchorId || forceRecalculate {
                 targetScrollAnchorId = newAnchorId
            }

            if !forceRecalculate {
                 didScrollForDay = true // Mark as scrolled for this day
            }
        } else {
             targetScrollAnchorId = nil // No target event found, clear the target
        }
    }
    
    // Find the first chronologically occurring jogging-related event
    private func findFirstJoggingEvent(events: [Event]) -> Event? {
        // Sort events by start time to ensure "first" is chronological
        let sortedEvents = events.sorted { $0.startDate < $1.startDate }
        
        return sortedEvents.first { event in
            let title = event.title.lowercased()
            // Check for variations of jogging keywords
            return title.contains("pre-jogging") ||
                   title.contains("jogging") ||
                   title.contains("post-jogging") ||
                   title.contains("prejog") ||
                   title.contains("jog") ||
                   title.contains("postjog")
        }
    }
    
    // Calculate the target Y position for scrolling (positioning the event slightly below the top edge)
    private func calculateScrollTargetPosition(for date: Date) -> CGFloat {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        
        // Calculate exact Y position of the event's top edge within the scroll content
        let eventTopY = CGFloat(hour) * hourHeight + (CGFloat(minute) / 60.0) * hourHeight
        
        // Calculate target scroll position (e.g., 50 points above the event top to give context)
        // Ensure the target position doesn't go below 0
        let targetY = max(0, eventTopY - 50)
        
        return targetY
    }
}

// MARK: - Hour Grid View
struct HourGridView: View {
    let formatHour: (Int) -> String
    let hourHeight: CGFloat // Receive hourHeight

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(0..<24) { hour in
                VStack(alignment: .leading, spacing: 0) { // Use VStack to structure content within the hour slot
                    HStack {
                        Text(formatHour(hour))
                            .font(.caption)
                            .foregroundColor(.gray)
                            .frame(width: 70, alignment: .leading)
                            .padding(.top, 4) // Add slight padding from the top for the label
                        Spacer()
                    }
                    Spacer() // Pushes the Divider to the bottom of the VStack
                    Divider() // Divider is now at the bottom boundary of the hour slot
                }
                .frame(height: hourHeight) // Ensure each slot maintains the correct height
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Events Overlay View
struct EventsOverlayView: View {
    let events: [Event]
    let formatTime: (Date) -> String
    let hourHeight: CGFloat // Receive hourHeight
    let onEventTapped: (Event) -> Void // Add this new parameter
    
    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width - 70 // Subtract hour label width
            
            // First sort events by start time to ensure consistent display
            let sortedEvents = events.sorted(by: { $0.startDate < $1.startDate })
            
            // Group events by normalized start time (hour and minute only)
            let groupedEvents = Dictionary(grouping: sortedEvents) { event in
                let calendar = Calendar.current
                let components = calendar.dateComponents([.hour, .minute], from: event.startDate)
                return calendar.date(from: components) ?? event.startDate
            }
            
            // Render each group of events that share the same start time
            ForEach(Array(groupedEvents.keys).sorted(), id: \.self) { startTime in
                if let eventsAtTime = groupedEvents[startTime] {
                    let eventCount = eventsAtTime.count
                    
                    // Events with same start time are arranged horizontally
                    // Align items to the top edge
                    HStack(alignment: .top, spacing: 4) {
                        ForEach(eventsAtTime, id: \.id) { event in
                            EventBlockView(
                                event: event,
                                formatTime: formatTime,
                                width: eventCount > 1 ? (availableWidth / CGFloat(eventCount)) - 4 : availableWidth,
                                hourHeight: hourHeight,
                                onTap: {
                                    onEventTapped(event)
                                }
                            )
                        }
                    }
                    .frame(width: availableWidth, alignment: .topLeading) // Align frame content
                    // Use offset to position from the top-left corner
                    .offset(x: 70, y: calculateTopYPosition(for: startTime))
                }
            }
        }
    }
    
    // Calculate the TOP Y position based on start time
    private func calculateTopYPosition(for date: Date) -> CGFloat {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        
        // Calculate position: each hour block is hourHeight points high
        // Position is the number of hours * hourHeight + the minute fraction of an hour
        let exactYPosition = CGFloat(hour) * hourHeight + (CGFloat(minute) / 60.0) * hourHeight
        
        // No adjustment needed here if HourGridView lines are precise
        return exactYPosition 
    }
}

// MARK: - Event Block View
struct EventBlockView: View {
    let event: Event
    let formatTime: (Date) -> String
    let width: CGFloat
    let hourHeight: CGFloat
    let onTap: () -> Void
    
    // Define a threshold height to switch layout
    private let minimumHeightForVStackLayout: CGFloat = 40.0

    var body: some View {
        let calculatedHeight = calculateHeight()
        
        Group {
            if calculatedHeight >= minimumHeightForVStackLayout {
                // Use VStack for taller blocks
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text("\(formatTime(event.startDate)) - \(formatTime(event.endDate))")
                        .font(.caption)
                        .foregroundColor(.primary.opacity(0.7))
                }
            } else {
                // Use HStack for shorter blocks
                HStack(spacing: 4) {
                    Text(event.title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("\(formatTime(event.startDate))")
                        .font(.caption)
                        .foregroundColor(.primary.opacity(0.7))
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .frame(width: width, height: calculatedHeight, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(event.color.opacity(0.3))
        )
        .clipped()
        .onTapGesture {
            onTap()
        }
    }
    
    // Calculate accurate height based on event duration
    private func calculateHeight() -> CGFloat {
        let calendar = Calendar.current
        
        let startHour = calendar.component(.hour, from: event.startDate)
        let startMinute = calendar.component(.minute, from: event.startDate)
        let endHour = calendar.component(.hour, from: event.endDate)
        let endMinute = calendar.component(.minute, from: event.endDate)
        
        // Calculate total duration in minutes
        var durationInMinutes: CGFloat = 0
        
        if endHour < startHour || (endHour == startHour && endMinute <= startMinute) {
            // Event crosses midnight
            let minutesToMidnight = CGFloat((24 - startHour) * 60 - startMinute)
            let minutesAfterMidnight = CGFloat(endHour * 60 + endMinute)
            durationInMinutes = minutesToMidnight + minutesAfterMidnight
        } else {
            // Same day event
            let startTotalMinutes = CGFloat(startHour * 60 + startMinute)
            let endTotalMinutes = CGFloat(endHour * 60 + endMinute)
            durationInMinutes = endTotalMinutes - startTotalMinutes
        }
        
        // Convert minutes to height - hourHeight represents 60 minutes
        let calculatedHeight = durationInMinutes / 60.0 * hourHeight
        return max(30.0, calculatedHeight) // Keep a minimum height for visibility
    }
}

// MARK: - Calendar Access View
struct CalendarAccessView: View {
    let checkAccess: () -> Void
    
    var body: some View {
        VStack {
            Text("Calendar Access Required")
                .font(.headline)
                .padding(.bottom, 4)
            
            Text("Please grant calendar access in Settings to view your events")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
            
            Button("Request Access") {
                checkAccess()
            }
            .padding(.top, 12)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Bottom Tab Bar View
struct BottomTabBarView: View {
    var body: some View {
        HStack {
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "figure.run")
                    .font(.system(size: 24))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "calendar")
                    .font(.system(size: 24))
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
    }
}

#Preview {
    CalendarHeaderView(
        currentMonth: .constant(4),  // April
        currentYear: .constant(2025), // Current year
        showMonthPicker: .constant(false),
        showYearPicker: .constant(false),
        monthName: { month in
            let dateFormatter = DateFormatter()
            dateFormatter.calendar = Calendar(identifier: .gregorian)
            return dateFormatter.monthSymbols[month - 1]
        }
    )
}
