//  WatchSessionManager.swift (Watch App) - COMPLETE UPDATED VERSION
//  Note: SessionData is now imported from SharedModels.swift

import Foundation
import WatchConnectivity
import WidgetKit

class WatchSessionManager: NSObject, ObservableObject {
    static let shared = WatchSessionManager()
    
    @Published var sessions: [SessionData] = []
    @Published var isConnected = false
    @Published var lastUpdate = Date()
    
    private override init() {
        super.init()
        
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    func reloadComplications() {
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func requestSessionsFromPhone() {
        guard WCSession.default.activationState == .activated && WCSession.default.isReachable else {
            print("iPhone not reachable")
            return
        }
        
        WCSession.default.sendMessage(["request": "sessions"], replyHandler: { response in
            print("iPhone responded")
        }) { error in
            print("Error requesting sessions: \(error.localizedDescription)")
        }
    }
    
    var upcomingSessions: [SessionData] {
        return sessions
            .filter { $0.startTime > Date() && $0.status != "Done" }
            .sorted { $0.startTime < $1.startTime }
    }
    
    var sortedSessionsForToday: [SessionData] {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        return sessions
            .filter { session in
                session.startTime >= today && session.startTime < tomorrow
            }
            .sorted { first, second in
                // Sort by type: pre-jog → jog → post-jog
                let order = ["Pre-jogging": 0, "Jogging": 1, "Post-jogging": 2]
                let firstOrder = order[first.sessionType] ?? 3
                let secondOrder = order[second.sessionType] ?? 3
                
                if firstOrder != secondOrder {
                    return firstOrder < secondOrder
                }
                return first.startTime < second.startTime
            }
    }
    
    // Get next session for complications
    var nextSession: SessionData? {
        return upcomingSessions.first
    }
}

extension WatchSessionManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isConnected = activationState == .activated
        }
        print("Watch WC activated: \(activationState.rawValue)")
        
        // Automatically request sessions when connection is established
        if activationState == .activated {
            // Add a small delay to ensure connection is fully established
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.requestSessionsFromPhone()
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            if let sessionData = message["sessions"] as? Data {
                do {
                    let sessions = try JSONDecoder().decode([SessionData].self, from: sessionData)
                    self.sessions = sessions
                    self.lastUpdate = Date()
                    print("Received \(sessions.count) sessions from iPhone")
                    
                    // Reload complications with new data
                    self.reloadComplications()
                    
                } catch {
                    print("Error decoding sessions: \(error.localizedDescription)")
                }
            }
        }
    }
}
