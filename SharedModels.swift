//  SharedModels.swift
//  Make sure this file is added to ALL three targets:
//  - Swifter (iPhone app)
//  - SwifterCompanion Watch App
//  - SwifterComplications
//  - SwifterWatchWidget

import Foundation

struct SessionData: Codable {
    let id: String
    let startTime: Date
    let endTime: Date
    let sessionType: String
    let status: String
    let calendarEventID: String
}

// Add SessionType extension for display names
extension String {
    var displayName: String {
        switch self {
        case "Pre-jogging":
            return "Pre-Jog"
        case "Jogging":
            return "Jog"
        case "Post-jogging":
            return "Post-Jog"
        default:
            return self
        }
    }
}
