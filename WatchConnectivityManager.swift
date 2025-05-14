
import Foundation
import WatchConnectivity
import SwiftData

class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()
    
    private var modelContext: ModelContext?
    
    private override init() {
        super.init()
        
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
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

            // ✅ 1. Try sendMessage
            if WCSession.default.isReachable {
                WCSession.default.sendMessage(["sessions": data], replyHandler: { response in
                    print("Sessions sent successfully via message")
                }) { error in
                    print("Failed to send message: \(error.localizedDescription)")
                    // ✅ 2. Fallback to transferUserInfo
                    WCSession.default.transferUserInfo(["sessions": data])
                    print("Sessions sent via transferUserInfo (fallback)")
                }
            } else {
                // ✅ 3. transferUserInfo as background fallback
                WCSession.default.transferUserInfo(["sessions": data])
                print("Sessions sent via transferUserInfo (background)")
            }

            // ✅ 4. Always try updateApplicationContext for guaranteed delivery
            do {
                try WCSession.default.updateApplicationContext(["sessions": data])
                print("Sessions sent via updateApplicationContext")
            } catch {
                print("Failed to send application context: \(error.localizedDescription)")
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

        let sessionManager = JoggingSessionManager(modelContext: modelContext)
        
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

// MARK: - WCSessionDelegate
extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            print("iPhone WC activated: \(activationState.rawValue)")
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
        #if os(iOS)
        WCSession.default.activate()
        #endif
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        print("iPhone received message with reply handler: \(message)")
        DispatchQueue.main.async {
            if message["request"] as? String == "sessions" {
                print("Watch requested sessions")
                self.fetchAndSendSessions()
                replyHandler(["status": "sessions_sent"])
            } else {
                replyHandler(["status": "unknown_request"])
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("iPhone received message (no reply): \(message)")
        DispatchQueue.main.async {
            if message["request"] as? String == "sessions" {
                self.fetchAndSendSessions()
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any]) {
        print("iPhone received user info: \(userInfo)")
        DispatchQueue.main.async {
            if userInfo["request"] as? String == "sessions" {
                self.fetchAndSendSessions()
            }
        }
    }
}
