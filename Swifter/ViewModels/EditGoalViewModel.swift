//
 //  EditGoalViewModel.swift
 //  Swifter
 //
 //  Created by Adeline Charlotte Augustinne on 26/03/25.
 //

 import Foundation
 import SwiftUI
 import SwiftData

 final class EditGoalViewModel: ObservableObject {
     var prevGoal: GoalModel? = nil
     
     @Published var targetFrequency: Int
     @Published var startDate: Date
     @Published var endDate: Date
    
     init() {
             // Default values if no goal exists
             self.targetFrequency = 1
             self.startDate = Date()
             self.endDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
     }
    
     // Update existing goal or create new one if none exists
     func saveGoal(goalManager: GoalManager, goalToEdit: GoalModel) {
            goalManager.updateGoal(
                goalToEdit: goalToEdit,
                targetFreq: self.targetFrequency,
                startingDate: self.startDate,
                endingDate: self.endDate
             )
     }
     
     func fetchData(prevGoal: GoalModel) {
         self.prevGoal = prevGoal
         self.targetFrequency = prevGoal.targetFrequency
         self.startDate = prevGoal.startDate
         self.endDate = prevGoal.endDate
     }
}
