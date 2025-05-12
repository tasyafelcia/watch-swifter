//
//  GoalModel.swift
//  Swifter
//
//  Created by Adeline Charlotte Augustinne on 26/03/25.
//

import Foundation
import SwiftData

enum GoalStatus: String, Codable {
    case inProgress = "In progress"
    case completed = "Completed"
    case incomplete = "Incomplete"
}

@Model
class GoalModel {
    var targetFrequency: Int
    var startDate: Date
    var endDate: Date
    var progress: Int = 0
    var status: GoalStatus = GoalStatus.inProgress

    init(targetFrequency: Int, startDate: Date, endDate: Date) {
        self.targetFrequency = targetFrequency
        self.startDate = startDate
        self.endDate = endDate
    }
}
