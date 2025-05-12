//
//  JogSession.swift
//  Swifter
//
//  Created by Adeline Charlotte Augustinne on 26/03/25.
//

import Foundation
import SwiftData
import EventKit

enum SessionType: String, Codable {
    case prejog = "Pre-jogging"
    case jogging = "Jogging"
    case postjog = "Post-jogging"
}

enum isCompleted : String, Codable {
    case completed = "Done"
    case incomplete = "Not started yet"
    case missed = "Missed"
}

@Model
class SessionModel: Identifiable {
    
    var startTime: Date
    var endTime: Date
    var calendarEventID: String
    
    /// enums
    var sessionType: SessionType
    var status: isCompleted
    
    init(startTime: Date, endTime: Date, calendarEventID: String, sessionType: SessionType){
        self.startTime = startTime
        self.endTime = endTime
        self.calendarEventID = calendarEventID
        self.sessionType = sessionType
        self.status = isCompleted.incomplete
    }
}
