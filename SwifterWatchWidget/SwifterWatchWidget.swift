//  SwifterWatchWidget.swift
//  Updated with your custom design - green accent bar layout
//  Uses shared SessionData from SharedModels.swift (no duplication)

import WidgetKit
import SwiftUI

// No SessionData definition here - it comes from SharedModels.swift


struct SwifterWatchWidgetBundle: WidgetBundle {
    var body: some Widget {
        SwifterWatchWidget()
    }
}

struct SwifterWatchWidget: Widget {
    let kind: String = "SwifterWatchWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SessionProvider()) { entry in
            SwifterWidgetView(entry: entry)
                .widgetURL(URL(string: "swifter://sessions"))
        }
        .configurationDisplayName("Swifter Sessions")
        .description("Your upcoming jogging sessions")
        .supportedFamilies([.accessoryRectangular])
    }
}

// MARK: - Timeline Entry
struct SessionEntry: TimelineEntry {
    let date: Date
    let sessionType: String
    let startTime: Date
    let endTime: Date
    
    var timeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
    }
    
    var titleText: String {
        switch sessionType {
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
}

// MARK: - Timeline Provider
struct SessionProvider: TimelineProvider {
    func placeholder(in context: Context) -> SessionEntry {
        // Placeholder data that matches your design
        SessionEntry(
            date: Date(),
            sessionType: "Pre-jogging",
            startTime: Calendar.current.date(bySettingHour: 10, minute: 30, second: 0, of: Date()) ?? Date(),
            endTime: Calendar.current.date(bySettingHour: 11, minute: 0, second: 0, of: Date()) ?? Date()
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SessionEntry) -> ()) {
        // Try to get real session data
        if let session = getNextSessionFromUserDefaults() {
            let entry = SessionEntry(
                date: Date(),
                sessionType: session.sessionType,
                startTime: session.startTime,
                endTime: session.endTime
            )
            completion(entry)
        } else {
            // Use placeholder if no data
            completion(placeholder(in: context))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SessionEntry>) -> ()) {
        var entries: [SessionEntry] = []
        let currentDate = Date()
        
        // Get session data from UserDefaults
        if let session = getNextSessionFromUserDefaults() {
            let entry = SessionEntry(
                date: currentDate,
                sessionType: session.sessionType,
                startTime: session.startTime,
                endTime: session.endTime
            )
            entries.append(entry)
        } else {
            // Use placeholder if no data
            entries.append(placeholder(in: context))
        }
        
        // Refresh every 5 minutes
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 5, to: currentDate)!
        let timeline = Timeline(entries: entries, policy: .after(refreshDate))
        completion(timeline)
    }
    
    private func getNextSessionFromUserDefaults() -> SessionData? {
        // Try app group first
        if let appGroup = UserDefaults(suiteName: "group.com.yourteam.swifter.shared") {
            if let data = appGroup.data(forKey: "nextSession") {
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    return try decoder.decode(SessionData.self, from: data)
                } catch {
                    print("SwifterWatchWidget: Error decoding session from app group: \(error)")
                }
            }
        }
        
        // Fallback to standard UserDefaults
        if let data = UserDefaults.standard.data(forKey: "nextSession") {
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(SessionData.self, from: data)
            } catch {
                print("SwifterWatchWidget: Error decoding session from standard UserDefaults: \(error)")
            }
        }
        
        return nil
    }
}

// MARK: - Custom Widget View (Your Design)
struct SwifterWidgetView: View {
    var entry: SessionProvider.Entry

    var body: some View {
        HStack(spacing: 0) {
            // Green accent bar on the left (exactly like your design)
            Rectangle()
                .fill(Color(.sRGB, red: 0.2, green: 0.9, blue: 0.6))
                .frame(width: 6)
                .cornerRadius(3)
                .edgesIgnoringSafeArea(.vertical)
            
            // Main content area
            VStack(alignment: .leading, spacing: 4) {
                // Session type title
                Text(entry.titleText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                // Time range (main text)
                Text(entry.timeText)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                // App branding
                Text("Swifter")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            .padding(.leading, 12)
            .padding(.vertical, 8)
            
            Spacer(minLength: 8)
            
            // Right side: Motion lines + Running figure
            ZStack {
                // Motion lines behind the runner
                HStack(spacing: 4) {
                    // Tallest line (green)
                    Rectangle()
                        .fill(Color(.sRGB, red: 0.2, green: 0.9, blue: 0.6))
                        .frame(width: 3, height: 14)
                        .cornerRadius(1.5)
                    
                    // Medium line (blue)
                    Rectangle()
                        .fill(Color(.sRGB, red: 0.0, green: 0.7, blue: 0.9))
                        .frame(width: 3, height: 10)
                        .cornerRadius(1.5)
                    
                    // Shortest line (green)
                    Rectangle()
                        .fill(Color(.sRGB, red: 0.2, green: 0.9, blue: 0.6))
                        .frame(width: 3, height: 6)
                        .cornerRadius(1.5)
                }
                .offset(x: -18, y: 0)
                
                // Running figure icon
                Image(systemName: "figure.run")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(.trailing, 14)
        }
        .containerBackground(Color.black, for: .widget)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Preview
#Preview(as: .accessoryRectangular) {
    SwifterWatchWidget()
} timeline: {
    SessionEntry(
        date: Date(),
        sessionType: "Pre-jogging",
        startTime: Calendar.current.date(bySettingHour: 10, minute: 30, second: 0, of: Date()) ?? Date(),
        endTime: Calendar.current.date(bySettingHour: 11, minute: 0, second: 0, of: Date()) ?? Date()
    )
}
