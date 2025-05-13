//  WatchConnectivityManager.swift (iPhone app) - PROPERLY FIXED
//  Add to your Swifter (iPhone) target

import Foundation
import WatchConnectivity
import SwiftData

class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()
    
    // Add a property to hold the model context
    private var modelContext: ModelContext?
    
    private override init() {
        super.init()
        
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    // Method to set the model context from SwifterApp
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        print("Model context set in WatchConnectivityManager")
    }
    
    func sendSessionsToWatch(_ sessions: [SessionModel]) {
        guard WCSession.default.activationState == .activated else {
            print("WCSession not activated")
            return
        }
        
        let sessionData = sessions.map { session in
            SessionData(
                id: session.calendarEventID,
                startTime: session.startTime,
                endTime: session.endTime,
                sessionType: session.sessionType.rawValue,
                status: session.status.rawValue,
                calendarEventID: session.calendarEventID
            )
        }
        
        do {
            let data = try JSONEncoder().encode(sessionData)
            
            // Try sendMessage first (for when watch app is active)
            if WCSession.default.isReachable {
                WCSession.default.sendMessage(["sessions": data], replyHandler: { response in
                    print("Sessions sent successfully via message")
                }) { error in
                    print("Failed to send message, trying transferUserInfo: \(error.localizedDescription)")
                    // Fallback to transferUserInfo for background delivery
                    WCSession.default.transferUserInfo(["sessions": data])
                }
            } else {
                // Use transferUserInfo for background delivery
                WCSession.default.transferUserInfo(["sessions": data])
                print("Sessions sent via transferUserInfo (background)")
            }
        } catch {
            print("Error encoding sessions: \(error.localizedDescription)")
        }
    }
    
    private func fetchAndSendSessions() {
        guard let modelContext = modelContext else {
            print("Model context not set")
            return
        }
        
        // Create session manager to fetch sessions
        let sessionManager = JoggingSessionManager(modelContext: modelContext)
        
        // Get sessions for today and future
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 3, to: today)!
        
        let allSessions = sessionManager.fetchAllSessions()
        
        let relevantSessions = allSessions.filter { session in
            session.startTime >= today && session.startTime < tomorrow
        }
        
        print("Sending \(relevantSessions.count) sessions to watch")
        sendSessionsToWatch(relevantSessions)
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            print("iPhone WC activated: \(activationState.rawValue)")
            
            // Send sessions immediately after activation
            if activationState == .activated {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.fetchAndSendSessions()
                }
            }
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("iPhone WC session did become inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("iPhone WC session did deactivate")
        
        // Reactivate the session for iOS
        #if os(iOS)
        WCSession.default.activate()
        #endif
    }
    
    // IMPORTANT: This is the method that handles messages WITH reply handler
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        print("iPhone received message with reply handler: \(message)")
        
        DispatchQueue.main.async {
            if message["request"] as? String == "sessions" {
                print("Watch requested sessions")
                self.fetchAndSendSessions()
                
                // IMPORTANT: Send a reply back to the watch
                replyHandler(["status": "sessions_sent"])
            } else {
                replyHandler(["status": "unknown_request"])
            }
        }
    }
    
    // Handle messages without reply handler
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("iPhone received message (no reply): \(message)")
        
        DispatchQueue.main.async {
            if message["request"] as? String == "sessions" {
                self.fetchAndSendSessions()
            }
        }
    }
    
    // Handle transferUserInfo
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any]) {
        print("iPhone received user info: \(userInfo)")
        
        DispatchQueue.main.async {
            if userInfo["request"] as? String == "sessions" {
                self.fetchAndSendSessions()
            }
        }
    }
}
