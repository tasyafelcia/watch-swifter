//
//  PreferencesManager.swift
//  Swifter
//
//  Created by Adeline Charlotte Augustinne on 29/03/25.
//

import Foundation
import SwiftData

class PreferencesManager: ObservableObject {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// fetch the one existing preference
    func fetchPreferences() -> PreferencesModel? {
        let descriptor = FetchDescriptor<PreferencesModel>()
        return try? modelContext.fetch(descriptor).first
    }
    
    /// create new preference and store to DB via onboarding
    func createNewPreference(timeOnFeet: Int){
        let myPreferences = PreferencesModel(timeOnFeet: timeOnFeet)
        modelContext.insert(myPreferences)
        
        do {
            try modelContext.save()
            print("✅ Preference saved successfully")
            print(fetchPreferences())
        } catch {
            print("❌ Failed to save preferences: \(error)")
        }
    }
    
    /// set preferred prejog time for existing preferences data
    func setJogTime(timeOnFeet: Int){
        let myPreferences = fetchPreferences()
        myPreferences?.jogDuration = timeOnFeet
        
        do {
            try modelContext.save()
            print("✅ New jog time saved: \(myPreferences?.jogDuration) minutes")
        } catch {
            print("❌ Failed: \(error)")
           }
    }
    
    /// set preferred prejog time for existing preferences data
    func setPrejogTime(prejogTime: Int){
        let myPreferences = fetchPreferences()
        myPreferences?.preJogDuration = prejogTime
        
        do {
            try modelContext.save()
            print("✅ New pre-jog time saved: \(myPreferences?.preJogDuration) minutes")
        } catch {
            print("❌ Failed: \(error)")
           }
    }
    
    /// set preferred post jog time for existing preferences data
    func setPostjogTime(postjogTime: Int){
        let myPreferences = fetchPreferences()
        myPreferences?.postJogDuration = postjogTime
        
        do {
            try modelContext.save()
            print("✅ New post-jog time saved: \(myPreferences?.postJogDuration) minutes")
        } catch {
            print("❌ Failed: \(error)")
           }
    }
    
    /// set preferred time of day for existing preferences data
    func setTimesOfDay(timesOfDay: [TimeOfDay]){
        let myPreferences = fetchPreferences()
        myPreferences?.preferredTimesOfDay = timesOfDay
        
        do {
            try modelContext.save()
            print("✅ New times of day saved: \(myPreferences?.preferredTimesOfDay)")
        } catch {
            print("❌ Failed: \(error)")
           }
    }
    
    /// set preferred days of the week for existing preferences data
    func setDaysOfWeek(daysOfWeek: [DayOfWeek]){
        let myPreferences = fetchPreferences()
        myPreferences?.preferredDaysOfWeek = daysOfWeek
        
        do {
            try modelContext.save()
            print("✅ New days of week saved: \(myPreferences?.preferredDaysOfWeek)")
        } catch {
            print("❌ Failed: \(error)")
           }
    }
    
    func debug(){
        let myPreferences = fetchPreferences()
        print("Jog duration: \(myPreferences?.jogDuration)")
        print("Prejog duration: \(myPreferences?.preJogDuration)")
        print("Postjog duration: \(myPreferences?.postJogDuration)")
        print("Times of day: \(myPreferences?.preferredTimesOfDay)")
        print("Days of week: \(myPreferences?.preferredDaysOfWeek)")
    }
    
//    /// Save user preferences to SwiftData
//    func savePreferences(tempPreferences: PreferencesModel) {
//        let newPreferences = PreferencesModel(
//            timeOfDay: tempPreferences.preferredTimesOfDay,
//            dayOfWeek: tempPreferences.preferredDaysOfWeek,
//            preJogDuration: tempPreferences.preJogDuration,
//            postJogDuration: tempPreferences.postJogDuration
//        )
//        
//        modelContext.insert(newPreferences)
//    }
//
    
}
