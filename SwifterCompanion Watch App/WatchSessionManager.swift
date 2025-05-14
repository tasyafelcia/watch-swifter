//  SessionData is now imported from SharedModels.swift

import Foundation
import WatchConnectivity
import WidgetKit

class WatchSessionManager: NSObject, ObservableObject {
    static let shared = WatchSessionManager()
    
    @Published var sessions: [SessionData] = []
    @Published var isConnected = false
    @Published var lastUpdate = Date()
    @Published var connectionStatus = "Checking..."
    
    private var retryCount = 0
    private let maxRetries = 3
    
    private override init() {
        super.init()
        
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        } else {
            connectionStatus = "Watch Connectivity not supported"
        }
    }
    
    func reloadComplications() {
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func requestSessionsFromPhone() {
        guard WCSession.default.activationState == .activated else {
            connectionStatus = "Watch Connectivity not activated"
            print("WCSession not activated. State: \(WCSession.default.activationState.rawValue)")
            return
        }
        
        // First check if iPhone is reachable
        if !WCSession.default.isReachable {
            connectionStatus = "iPhone not reachable"
            print("iPhone not reachable. Using transferUserInfo...")
            
            // Try using transferUserInfo for background delivery
            WCSession.default.transferUserInfo(["request": "sessions"])
            return
        }
        
        connectionStatus = "Requesting sessions..."
        print("Sending session request to iPhone...")
        
        // Use sendMessage when iPhone is reachable
        WCSession.default.sendMessage(["request": "sessions"], replyHandler: { response in
            DispatchQueue.main.async {
                self.connectionStatus = "Request acknowledged"
                self.retryCount = 0
                print("iPhone acknowledged request: \(response)")
            }
        }) { error in
            DispatchQueue.main.async {
                self.connectionStatus = "Request failed: \(error.localizedDescription)"
                print("Error requesting sessions: \(error.localizedDescription)")
                
                // Retry logic
                if self.retryCount < self.maxRetries {
                    self.retryCount += 1
                    print("Retrying request \(self.retryCount)/\(self.maxRetries)")
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.requestSessionsFromPhone()
                    }
                } else {
                    print("Max retries reached. Trying transferUserInfo...")
                    WCSession.default.transferUserInfo(["request": "sessions"])
                }
            }
        }
    }
    
    // Computed properties for session filtering
    var upcomingSessions: [SessionData] {
        let now = Date()
        let thirtyMinutesFromNow = now.addingTimeInterval(30 * 60)
        
        return sessions
            .filter { session in
                (session.startTime > now && session.startTime <= thirtyMinutesFromNow && session.status != "Done") ||
                (session.startTime > thirtyMinutesFromNow && session.status != "Done")
            }
            .sorted { $0.startTime < $1.startTime }
    }
    
    var ongoingSessions: [SessionData] {
        let now = Date()
        
        return sessions
            .filter { session in
                session.startTime <= now && session.endTime > now && session.status != "Done"
            }
            .sorted { $0.startTime < $1.startTime }
    }
    
    var upcomingSoonSessions: [SessionData] {
        let now = Date()
        let thirtyMinutesFromNow = now.addingTimeInterval(30 * 60)
        
        return sessions
            .filter { session in
                session.startTime > now && session.startTime <= thirtyMinutesFromNow && session.status != "Done"
            }
            .sorted { $0.startTime < $1.startTime }
    }
    
    var displaySessions: [SessionData] {
        let ongoing = ongoingSessions
        let upcomingSoon = upcomingSoonSessions
        let futureUpcoming = upcomingSessions.filter { session in
            !upcomingSoon.contains { $0.id == session.id }
        }
        
        let combined = ongoing + upcomingSoon + futureUpcoming
        return combined.sorted { $0.startTime < $1.startTime }
    }
    
    var sortedSessionsForToday: [SessionData] {
        return displaySessions
    }
    
    var nextSession: SessionData? {
        if let ongoing = ongoingSessions.first {
            return ongoing
        }
        return upcomingSessions.first
    }
    
    // MARK: - UserDefaults Integration for Complications
    func saveNextSessionForComplications() {
        guard let nextSession = self.nextSession else {
            print("No next session to save")
            return
        }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let sessionData = try encoder.encode(nextSession)
            
            // Save to app group UserDefaults (if configured)
            if let appGroupDefaults = UserDefaults(suiteName: "group.com.yourteam.swifter.shared") {
                appGroupDefaults.set(sessionData, forKey: "nextSession")
                print("Saved next session to app group UserDefaults")
            }
            
            // Also save to standard UserDefaults as fallback
            UserDefaults.standard.set(sessionData, forKey: "nextSession")
            print("Saved next session to UserDefaults")
            
            // Reload complications
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("Error encoding session for complications: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Custom Widget Integration
    func updateCustomWidget() {
        // Save data for the new custom widget
        saveNextSessionForComplications()
        
        // Reload the specific widget
        WidgetCenter.shared.reloadTimelines(ofKind: "SwifterWatchWidget")
        
        print("Updated custom widget")
    }
    
    // Force refresh all widgets
    func forceRefreshWidgets() {
        // Clear cached data
        UserDefaults.standard.removeObject(forKey: "nextSession")
        if let appGroup = UserDefaults(suiteName: "group.com.yourteam.swifter.shared") {
            appGroup.removeObject(forKey: "nextSession")
        }
        
        // Save current session data
        saveNextSessionForComplications()
        
        // Force reload all widgets
        WidgetCenter.shared.reloadAllTimelines()
        WidgetCenter.shared.reloadTimelines(ofKind: "SwifterComplications")
        WidgetCenter.shared.reloadTimelines(ofKind: "SwifterWatchWidget")
        
        print("Force refreshed all widgets")
    }
}

extension WatchSessionManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isConnected = activationState == .activated
            
            switch activationState {
            case .activated:
                self.connectionStatus = "Connected"
                print("Watch WC activated successfully")
                // Automatically request sessions when connection is established
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.requestSessionsFromPhone()
                }
            case .inactive:
                self.connectionStatus = "Inactive"
                print("Watch WC inactive")
            case .notActivated:
                self.connectionStatus = "Not Activated"
                print("Watch WC not activated")
            @unknown default:
                self.connectionStatus = "Unknown State"
                print("Watch WC unknown state")
            }
        }
        
        if let error = error {
            print("Watch WC activation error: \(error.localizedDescription)")
        }
    }
    
    // Handle incoming messages without reply handler
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("Watch received message: \(message)")
        
        DispatchQueue.main.async {
            if let sessionData = message["sessions"] as? Data {
                self.processSessions(from: sessionData, source: "message")
            }
        }
    }
    
    // Handle incoming messages WITH reply handler
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        print("Watch received message with reply handler: \(message)")
        
        DispatchQueue.main.async {
            if let sessionData = message["sessions"] as? Data {
                self.processSessions(from: sessionData, source: "message with reply")
                replyHandler(["status": "received"])
            } else {
                replyHandler(["status": "no_sessions_data"])
            }
        }
    }
    
    // Handle transferUserInfo
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any]) {
        print("Watch received user info: \(userInfo)")
        
        DispatchQueue.main.async {
            if let sessionData = userInfo["sessions"] as? Data {
                self.processSessions(from: sessionData, source: "user info")
            }
        }
    }
    
    // Handle application context
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print("Watch received application context: \(applicationContext)")
        
        DispatchQueue.main.async {
            if let sessionData = applicationContext["sessions"] as? Data {
                self.processSessions(from: sessionData, source: "application context")
            }
        }
    }
    
    // UPDATED: Helper method to process session data
    private func processSessions(from data: Data, source: String) {
        do {
            let sessions = try JSONDecoder().decode([SessionData].self, from: data)
            self.sessions = sessions
            self.lastUpdate = Date()
            self.connectionStatus = "Sessions updated (\(source))"
            print("Received \(sessions.count) sessions from iPhone via \(source)")
            
            // Save next session for complications
            self.saveNextSessionForComplications()
            
            // Update both old and new widgets
            self.reloadComplications()
            self.updateCustomWidget()
            
        } catch {
            print("Error decoding sessions from \(source): \(error.localizedDescription)")
            self.connectionStatus = "Decode error"
        }
    }
}
