//  SwifterComplications.swift
//  Corrected version - NO WatchSessionManager references

import WidgetKit
import SwiftUI

@main
struct SwifterComplicationsBundle: WidgetBundle {
    var body: some Widget {
        SwifterComplications()
    }
}

struct SwifterComplications: Widget {
    let kind: String = "SwifterComplications"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            SwifterComplicationsEntryView(entry: entry)
                .widgetURL(URL(string: "swifter://sessions"))
        }
        .configurationDisplayName("Swifter Sessions")
        .description("Shows your next jogging session")
        .supportedFamilies([.accessoryRectangular, .accessoryCircular, .accessoryInline])
    }
}

// MARK: - Timeline Entry Model
struct ComplicationEntry: TimelineEntry {
    let date: Date
    let session: SessionData?
}

// MARK: - Timeline Provider
struct Provider: TimelineProvider {
    typealias Entry = ComplicationEntry
    
    func placeholder(in context: Context) -> ComplicationEntry {
        ComplicationEntry(
            date: Date(),
            session: createPlaceholderSession()
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ComplicationEntry) -> ()) {
        let entry = ComplicationEntry(
            date: Date(),
            session: createPlaceholderSession()
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ComplicationEntry>) -> ()) {
        let currentDate = Date()
        var entries: [ComplicationEntry] = []
        
        // Create a simple timeline entry with placeholder data
        // Complications will be updated through the watch app when real data is available
        let entry = ComplicationEntry(
            date: currentDate,
            session: createMockUpcomingSession()
        )
        entries.append(entry)
        
        // Refresh every 15 minutes
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let timeline = Timeline(entries: entries, policy: .after(refreshDate))
        completion(timeline)
    }
    
    // Create placeholder session for complication
    private func createPlaceholderSession() -> SessionData {
        let calendar = Calendar.current
        let startTime = calendar.date(bySettingHour: 10, minute: 30, second: 0, of: Date()) ?? Date()
        let endTime = calendar.date(byAdding: .minute, value: 30, to: startTime)!
        
        return SessionData(
            id: "placeholder",
            startTime: startTime,
            endTime: endTime,
            sessionType: "Pre-jogging",
            status: "Not started yet",
            calendarEventID: "placeholder"
        )
    }
    
    // Create mock upcoming session
    private func createMockUpcomingSession() -> SessionData {
        let calendar = Calendar.current
        let now = Date()
        let startTime = calendar.date(byAdding: .hour, value: 2, to: now)!
        let endTime = calendar.date(byAdding: .minute, value: 30, to: startTime)!
        
        return SessionData(
            id: "mock-\(now.timeIntervalSince1970)",
            startTime: startTime,
            endTime: endTime,
            sessionType: "Jogging",
            status: "Not started yet",
            calendarEventID: "mock"
        )
    }
}

// MARK: - Entry View
struct SwifterComplicationsEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        if let session = entry.session {
            switch family {
            case .accessoryRectangular:
                RectangularComplicationView(session: session)
            case .accessoryCircular:
                CircularComplicationView(session: session)
            case .accessoryInline:
                InlineComplicationView(session: session)
            default:
                RectangularComplicationView(session: session)
            }
        } else {
            // Empty state
            VStack {
                Image(systemName: "figure.run")
                    .font(.caption)
                Text("No sessions")
                    .font(.caption2)
            }
            .foregroundColor(.gray)
        }
    }
}

// MARK: - Rectangular Complication View
struct RectangularComplicationView: View {
    let session: SessionData
    
    var body: some View {
        HStack(spacing: 0) {
            // Green accent bar
            Rectangle()
                .fill(Color.green)
                .frame(width: 4)
            
            // Main content area
            VStack(alignment: .leading, spacing: 2) {
                // Title text
                Text(titleText)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                // Time text
                Text(timeRangeText)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                // App name
                Text("Swifter")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            .padding(.leading, 8)
            .padding(.vertical, 4)
            
            Spacer()
            
            // Running icon with motion lines
            ZStack {
                // Motion lines
                HStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.green)
                        .frame(width: 2, height: 8)
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.blue)
                        .frame(width: 2, height: 6)
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.green)
                        .frame(width: 2, height: 4)
                }
                .offset(x: -8)
                
                // Running figure
                Image(systemName: "figure.run")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundColor(.white)
            }
            .padding(.trailing, 8)
        }
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var titleText: String {
        switch session.sessionType {
        case "Pre-jogging":
            return "Upcoming Pre-Jog"
        case "Jogging":
            return "Upcoming Jog"
        case "Post-jogging":
            return "Upcoming Post-Jog"
        default:
            return "Upcoming Session"
        }
    }
    
    private var timeRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "\(formatter.string(from: session.startTime)) - \(formatter.string(from: session.endTime))"
    }
}

// MARK: - Circular Complication View
struct CircularComplicationView: View {
    let session: SessionData
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(Color.black)
            
            // Progress ring (optional)
            Circle()
                .stroke(Color.green, lineWidth: 3)
                .opacity(0.3)
            
            VStack(spacing: 2) {
                // Running icon
                Image(systemName: iconName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                
                // Time until session
                Text(timeUntilText)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.green)
            }
        }
    }
    
    private var iconName: String {
        switch session.sessionType {
        case "Pre-jogging":
            return "figure.flexibility"
        case "Jogging":
            return "figure.run"
        case "Post-jogging":
            return "figure.cooldown"
        default:
            return "figure.run"
        }
    }
    
    private var timeUntilText: String {
        let timeUntil = session.startTime.timeIntervalSinceNow
        
        if timeUntil < 0 {
            return "NOW"
        }
        
        let hours = Int(timeUntil) / 3600
        let minutes = Int(timeUntil) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "NOW"
        }
    }
}

// MARK: - Inline Complication View
struct InlineComplicationView: View {
    let session: SessionData
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .foregroundColor(.green)
            
            Text("\(timeRangeText) Swifter")
                .foregroundColor(.white)
        }
    }
    
    private var iconName: String {
        switch session.sessionType {
        case "Pre-jogging":
            return "figure.flexibility"
        case "Jogging":
            return "figure.run"
        case "Post-jogging":
            return "figure.cooldown"
        default:
            return "figure.run"
        }
    }
    
    private var timeRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: session.startTime)
    }
}

// MARK: - Preview Support
#Preview("Rectangular", as: .accessoryRectangular) {
    SwifterComplications()
} timeline: {
    ComplicationEntry(
        date: Date(),
        session: SessionData(
            id: "preview",
            startTime: Date(),
            endTime: Date().addingTimeInterval(1800),
            sessionType: "Pre-jogging",
            status: "Not started yet",
            calendarEventID: "preview"
        )
    )
}

#Preview("Circular", as: .accessoryCircular) {
    SwifterComplications()
} timeline: {
    ComplicationEntry(
        date: Date(),
        session: SessionData(
            id: "preview",
            startTime: Date().addingTimeInterval(1800),
            endTime: Date().addingTimeInterval(3600),
            sessionType: "Jogging",
            status: "Not started yet",
            calendarEventID: "preview"
        )
    )
}
