//
//  PreferencesModel.swift
//  Swifter
//
//  Created by Teuku Fazariz Basya on 26/03/25.
//

import Foundation
import SwiftData

enum TimeOfDay: String, CaseIterable, Identifiable, Codable{
    case morning = "Morning"
    case noon = "Noon"
    case afternoon = "Afternoon"
    case evening = "Evening"
    
    var id: String { self.rawValue }
}

enum DayOfWeek: Int, CaseIterable, Identifiable, Codable{
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
    case sunday = 1

    var id: Int { self.rawValue }

    var name: String {
        switch self {
        case .monday : return "Monday"
        case .tuesday : return "Tuesday"
        case .wednesday : return "Wednesday"
        case .thursday : return "Thursday"
        case .friday : return "Friday"
        case .saturday : return "Saturday"
        case .sunday : return "Sunday"
        }
    }
}

@Model
class PreferencesModel {
    var jogDuration: Int
    
    // optional variables
    // set with default value
    var preJogDuration: Int = 0
    var postJogDuration: Int = 0
    
    var preferredTimesOfDay: [TimeOfDay] = [TimeOfDay.morning, TimeOfDay.afternoon]
    var preferredDaysOfWeek: [DayOfWeek]? = nil
    
    init(timeOnFeet: Int,
         preJogDuration: Int = 0,
         postJogDuration: Int = 0,
         timeOfDay: [TimeOfDay] = [TimeOfDay.morning, TimeOfDay.afternoon],
         dayOfWeek: [DayOfWeek] = [DayOfWeek.monday, DayOfWeek.wednesday, DayOfWeek.friday]
    ){
        self.jogDuration = timeOnFeet
        self.preJogDuration = preJogDuration
        self.postJogDuration = postJogDuration
        self.preferredTimesOfDay = timeOfDay
        self.preferredDaysOfWeek = dayOfWeek
    }
}
