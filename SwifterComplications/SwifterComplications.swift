//  SwifterComplications.swift
//  Fixed for proper rendering in all contexts

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
        .supportedFamilies([.accessoryRectangular])
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
        
        // Try to get session data from UserDefaults (shared with watch app)
        let nextSession = getNextSessionFromUserDefaults()
        
        let entry = ComplicationEntry(
            date: currentDate,
            session: nextSession ?? createPlaceholderSession()
        )
        
        // Refresh every 5 minutes
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 5, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }
    
    // Get session data from UserDefaults (shared container)
    private func getNextSessionFromUserDefaults() -> SessionData? {
        // Try to get from UserDefaults with app group
        if let appGroupDefaults = UserDefaults(suiteName: "group.com.yourteam.swifter.shared") {
            if let sessionData = appGroupDefaults.data(forKey: "nextSession") {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try? decoder.decode(SessionData.self, from: sessionData)
            }
        }
        
        // Fallback to standard UserDefaults
        if let sessionData = UserDefaults.standard.data(forKey: "nextSession") {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try? decoder.decode(SessionData.self, from: sessionData)
        }
        
        return nil
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
}

// MARK: - Entry View
struct SwifterComplicationsEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    @Environment(\.widgetRenderingMode) var renderingMode

    var body: some View {
        if let session = entry.session {
            AdaptiveComplicationView(session: session)
        } else {
            // Fallback view
            EmptyAdaptiveComplicationView()
        }
    }
}

// MARK: - Adaptive Complication View (Works in all contexts)
struct AdaptiveComplicationView: View {
    let session: SessionData
    @Environment(\.widgetRenderingMode) var renderingMode
    
    var body: some View {
        HStack(spacing: 0) {
            // Green accent bar (adapts to context)
            Rectangle()
                .fill(accentColor)
                .frame(width: 4)
            
            // Main content area
            VStack(alignment: .leading, spacing: 2) {
                // Title text
                Text(titleText)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(primaryColor)
                    .lineLimit(1)
                
                // Time text
                Text(timeRangeText)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(primaryColor)
                    .lineLimit(1)
                
                // App name
                Text("Swifter")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(secondaryColor)
                    .lineLimit(1)
            }
            .padding(.leading, 8)
            .padding(.vertical, 4)
            
            Spacer()
            
            // Right side icon with motion lines
            ZStack {
                // Motion lines
                HStack(spacing: 2) {
                    Rectangle()
                        .fill(accentColor)
                        .frame(width: 2, height: 8)
                        .cornerRadius(1)
                    
                    Rectangle()
                        .fill(secondaryAccentColor)
                        .frame(width: 2, height: 6)
                        .cornerRadius(1)
                    
                    Rectangle()
                        .fill(accentColor)
                        .frame(width: 2, height: 4)
                        .cornerRadius(1)
                }
                .offset(x: -8)
                
                // Running figure icon
                Image(systemName: "figure.run")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundColor(primaryColor)
            }
            .padding(.trailing, 8)
        }
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    // Adaptive colors based on rendering mode
    private var backgroundColor: Color {
        switch renderingMode {
        case .fullColor:
            return Color.black
        case .accented:
            return Color.clear
        case .vibrant:
            return Color.clear
        default:
            return Color.black
        }
    }
    
    private var primaryColor: Color {
        switch renderingMode {
        case .fullColor:
            return Color.white
        case .accented:
            return Color.primary
        case .vibrant:
            return Color.primary
        default:
            return Color.white
        }
    }
    
    private var secondaryColor: Color {
        switch renderingMode {
        case .fullColor:
            return Color.gray
        case .accented:
            return Color.secondary
        case .vibrant:
            return Color.secondary
        default:
            return Color.gray
        }
    }
    
    private var accentColor: Color {
        switch renderingMode {
        case .fullColor:
            return Color.green
        case .accented:
            return Color.accentColor
        case .vibrant:
            return Color.accentColor
        default:
            return Color.green
        }
    }
    
    private var secondaryAccentColor: Color {
        switch renderingMode {
        case .fullColor:
            return Color.cyan
        case .accented:
            return Color.accentColor.opacity(0.7)
        case .vibrant:
            return Color.accentColor.opacity(0.7)
        default:
            return Color.cyan
        }
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

// MARK: - Empty Adaptive Complication View
struct EmptyAdaptiveComplicationView: View {
    @Environment(\.widgetRenderingMode) var renderingMode
    
    var body: some View {
        HStack(spacing: 0) {
            // Green accent bar
            Rectangle()
                .fill(accentColor)
                .frame(width: 4)
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text("No Sessions")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(primaryColor)
                    .lineLimit(1)
                
                Text("Tap to open")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(secondaryColor)
                    .lineLimit(1)
                
                Text("Swifter")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(secondaryColor)
                    .lineLimit(1)
            }
            .padding(.leading, 8)
            .padding(.vertical, 4)
            
            Spacer()
            
            // Running icon
            Image(systemName: "figure.run")
                .font(.system(size: 20, weight: .regular))
                .foregroundColor(primaryColor)
                .padding(.trailing, 8)
        }
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    // Adaptive colors based on rendering mode
    private var backgroundColor: Color {
        switch renderingMode {
        case .fullColor:
            return Color.black
        case .accented:
            return Color.clear
        case .vibrant:
            return Color.clear
        default:
            return Color.black
        }
    }
    
    private var primaryColor: Color {
        switch renderingMode {
        case .fullColor:
            return Color.white
        case .accented:
            return Color.primary
        case .vibrant:
            return Color.primary
        default:
            return Color.white
        }
    }
    
    private var secondaryColor: Color {
        switch renderingMode {
        case .fullColor:
            return Color.gray
        case .accented:
            return Color.secondary
        case .vibrant:
            return Color.secondary
        default:
            return Color.gray
        }
    }
    
    private var accentColor: Color {
        switch renderingMode {
        case .fullColor:
            return Color.green
        case .accented:
            return Color.accentColor
        case .vibrant:
            return Color.accentColor
        default:
            return Color.green
        }
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
            startTime: Calendar.current.date(bySettingHour: 10, minute: 30, second: 0, of: Date()) ?? Date(),
            endTime: Calendar.current.date(bySettingHour: 11, minute: 0, second: 0, of: Date()) ?? Date(),
            sessionType: "Pre-jogging",
            status: "Not started yet",
            calendarEventID: "preview"
        )
    )
}
