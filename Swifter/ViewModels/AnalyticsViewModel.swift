//
//  AnalyticsViewModel.swift
//  Swifter
//
//  Created by Adeline Charlotte Augustinne on 04/04/25.
//

import Foundation
import SwiftUI

final class AnalyticsViewModel: ObservableObject {
    
    @Published var weeklyProgress: [(category: String, value: Int)]
    @Published var goals: [GoalModel]
    @Published var goalChartData: [(category: String, value: Float)]
    @Published var monthlyJogs: Int
    @Published var totalJogs: Int
    
    init(){
        weeklyProgress = [(category: "", value: 2), (category: "", value: 4)]
        goals = [
            GoalModel(targetFrequency: 10, startDate: Date(), endDate: Date()+60*60*24*7),
                 GoalModel(targetFrequency: 15, startDate: Date()+60*60*24*8, endDate: Date()+60*60*24*14),
                 GoalModel(targetFrequency: 20, startDate: Date()+60*60*24*15, endDate: Date()+60*60*24*21),
                 GoalModel(targetFrequency: 30, startDate: Date()+60*60*24*22, endDate: Date()+60*60*24*28),
                 GoalModel(targetFrequency: 25, startDate: Date()+60*60*24*29, endDate: Date()+60*60*24*35)
            ]
        goalChartData = [(category: "Completed goals", value: 5),
                         (category: "Incomplete goals", value: 0)]
        monthlyJogs = 0
        totalJogs = 0
    }
    
    func fetchGoalData(goalManager: GoalManager){
        if let goalTemp = goalManager.fetchGoals() {
            self.goals = goalTemp
        }
        
        if let currentGoal = goals.sorted(by: { $0.startDate > $1.startDate }).first {
            self.weeklyProgress = [(category: "Completed", value: currentGoal.progress),
                                   (category: "Incomplete", value: currentGoal.targetFrequency - currentGoal.progress)]
        }
        
        self.goalChartData = [(category: "Completed goals", value: Float(goals.filter { $0.status == GoalStatus.completed}.count)+0.2),
                              (category: "Incomplete goals", value: Float(goals.filter { $0.status == GoalStatus.incomplete}.count)+0.2)]
    }
    
    func fetchSessionData(sessionManager: JoggingSessionManager){
        let calendar = Calendar.current
        self.monthlyJogs = sessionManager.fetchAllSessions().filter{
            calendar.isDate($0.startTime, equalTo: Date(), toGranularity: .month) && $0.sessionType == SessionType.jogging && $0.status == isCompleted.completed
        }.count
        
        self.totalJogs = sessionManager.fetchAllSessions().filter{
            $0.sessionType == SessionType.jogging && $0.status == isCompleted.completed
        }.count
    }
    
}
