//  JogComplicationEntry.swift
//  Add to your SwifterComplications target

import WidgetKit
import Foundation

struct JogComplicationEntry: TimelineEntry {
    let date: Date
    let sessionType: String
    let startTime: Date
    let endTime: Date
    let isActive: Bool
    
    var timeRangeText: String {
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
