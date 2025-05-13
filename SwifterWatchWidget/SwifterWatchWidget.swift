//  SwifterWatchWidget.swift
//  Custom widget complication for Apple Watch

import WidgetKit
import SwiftUI


struct SwifterWatchWidgetBundle: WidgetBundle {
    var body: some Widget {
        SwifterWatchWidget()
    }
}

struct SwifterWatchWidget: Widget {
    let kind: String = "SwifterWatchWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: JoggingProvider()) { entry in
            JoggingWidgetView(entry: entry)
                .widgetURL(URL(string: "swifter://sessions"))
        }
        .configurationDisplayName("Swifter Custom")
        .description("Custom jogging session widget")
        .supportedFamilies([.accessoryRectangular])
    }
}

// MARK: - Timeline Entry
struct JoggingEntry: TimelineEntry {
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
struct JoggingProvider: TimelineProvider {
    func placeholder(in context: Context) -> JoggingEntry {
        JoggingEntry(
            date: Date(),
            sessionType: "Pre-jogging",
            startTime: Calendar.current.date(bySettingHour: 10, minute: 30, second: 0, of: Date()) ?? Date(),
            endTime: Calendar.current.date(bySettingHour: 11, minute: 0, second: 0, of: Date()) ?? Date()
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (JoggingEntry) -> ()) {
        let entry = JoggingEntry(
            date: Date(),
            sessionType: "Pre-jogging",
            startTime: Calendar.current.date(bySettingHour: 10, minute: 30, second: 0, of: Date()) ?? Date(),
            endTime: Calendar.current.date(bySettingHour: 11, minute: 0, second: 0, of: Date()) ?? Date()
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        // Create timeline entries
        var entries: [JoggingEntry] = []
        
        // Get session data from UserDefaults
        let sessionData = getSessionFromUserDefaults()
        
        let entry = JoggingEntry(
            date: Date(),
            sessionType: sessionData?.sessionType ?? "Pre-jogging",
            startTime: sessionData?.startTime ?? Calendar.current.date(bySettingHour: 10, minute: 30, second: 0, of: Date())!,
            endTime: sessionData?.endTime ?? Calendar.current.date(bySettingHour: 11, minute: 0, second: 0, of: Date())!
        )
        entries.append(entry)
        
        // Create timeline with 5-minute refresh
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 5, to: Date())!
        let timeline = Timeline(entries: entries, policy: .after(refreshDate))
        completion(timeline)
    }
    
    private func getSessionFromUserDefaults() -> SessionData? {
        // Try app group first
        if let appGroup = UserDefaults(suiteName: "group.com.yourteam.swifter.shared") {
            if let data = appGroup.data(forKey: "nextSession") {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try? decoder.decode(SessionData.self, from: data)
            }
        }
        
        // Fallback to standard UserDefaults
        if let data = UserDefaults.standard.data(forKey: "nextSession") {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try? decoder.decode(SessionData.self, from: data)
        }
        
        return nil
    }
}

// MARK: - Widget View
struct JoggingWidgetView: View {
    var entry: JoggingProvider.Entry
    @Environment(\.widgetRenderingMode) var renderingMode

    var body: some View {
        CustomComplicationView(entry: entry)
    }
}

// MARK: - Custom Design
struct CustomComplicationView: View {
    let entry: JoggingEntry
    
    var body: some View {
        HStack(spacing: 0) {
            // Green accent bar
            Rectangle()
                .fill(Color.green)
                .frame(width: 4)
            
            // Main content
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.titleText)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(entry.timeText)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text("Swifter")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.gray)
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
                        .fill(Color.green)
                        .frame(width: 2, height: 8)
                        .cornerRadius(1)
                    
                    Rectangle()
                        .fill(Color.cyan)
                        .frame(width: 2, height: 6)
                        .cornerRadius(1)
                    
                    Rectangle()
                        .fill(Color.green)
                        .frame(width: 2, height: 4)
                        .cornerRadius(1)
                }
                .offset(x: -8)
                
                // Running figure
                Image(systemName: "figure.run")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundColor(.white)
            }
            .padding(.trailing, 8)
        }
        .containerBackground(Color.black, for: .widget)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Preview
#Preview(as: .accessoryRectangular) {
    SwifterWatchWidget()
} timeline: {
    JoggingEntry(
        date: Date(),
        sessionType: "Pre-jogging",
        startTime: Date(),
        endTime: Date().addingTimeInterval(1800)
    )
}
