////
////  Testing.swift
////  Swifter
////
////  Created by Adeline Charlotte Augustinne on 31/03/25.
////
//
//import SwiftUI
//import SwiftData
//
//struct Testing: View {
//    
//    @EnvironmentObject private var eventStoreManager: EventStoreManager
//    
//    @Environment(\.modelContext) private var modelContext
//    private var jogSeshManager: JoggingSessionManager {
//        JoggingSessionManager(modelContext: modelContext)
//    }
//    
//    @State var id: PersistentIdentifier?
//    
//    var body: some View {
//        Button{
//           if let time = eventStoreManager.findDayOfWeek(date: Date(), duration: 60*60*6),
//              let tempId = jogSeshManager.createNewSession(storeManager: eventStoreManager, start: time[0], end: time[1], sessionType: SessionType.jogging){
//               id = tempId
//               print(id)
//            }
//        } label: {
//            Text("Seed this mfing DB")
//        }
//        
//        Button{
//           if let time2 = eventStoreManager.findDayOfWeek(date: Date(), duration: 60*60*6){
//               do {
//                   try jogSeshManager.updateSessionTimes(id: id!, newStart: time2[0], newEnd: time2[1], eventStoreManager: eventStoreManager)
//               } catch {
//                   print("error bro")
//               }
//            }
//        } label: {
//            Text("Reschedule the thingy!?!?!?")
//        }
//    }
//}
//
//#Preview {
//    Testing(id: nil)
//}
