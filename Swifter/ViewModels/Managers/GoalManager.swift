//
//  GoalManager.swift
//  Swifter
//
//  Created by Adeline Charlotte Augustinne on 29/03/25.
//

import SwiftData
import SwiftData
import Foundation

class GoalManager: ObservableObject {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("❌ Failed to save preferences: \(error)")
        }
    }
    
    func createNewGoal(targetFreq: Int, startingDate: Date, endingDate: Date) -> GoalModel? {
        let myGoal = GoalModel(targetFrequency: targetFreq, startDate: startingDate, endDate: endingDate)
        modelContext.insert(myGoal)
        
        do {
            try modelContext.save()
            print("✅ Preference saved successfully")
            return myGoal
        } catch {
            print("❌ Failed to save preferences: \(error)")
            return nil
        }
    }
    
    func fetchGoals() -> [GoalModel]? {
        let goals = FetchDescriptor<GoalModel>()
        return try? modelContext.fetch(goals)
    }

    func updateGoal(goalToEdit: GoalModel, targetFreq: Int, startingDate: Date, endingDate: Date) {
        goalToEdit.targetFrequency = targetFreq
        goalToEdit.startDate = startingDate
        goalToEdit.endDate = endingDate
        goalToEdit.progress = 0
            
        do {
            try modelContext.save()
            print("✅ Goal updated successfully")
            print("Target frequency: \(goalToEdit.targetFrequency)")
            print("Start date: \(goalToEdit.startDate)")
            print("End date: \(goalToEdit.endDate)")
        } catch {
            print("❌ Failed to update goal: \(error)")
        }
    }
}
