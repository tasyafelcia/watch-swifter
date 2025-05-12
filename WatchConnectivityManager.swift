//  WatchConnectivityManager.swift (iPhone app)
//  Remove the SessionData struct from this file since it's now in SharedModels.swift

import Foundation
import WatchConnectivity

class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()
    
    private override init() {
        super.init()
        
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    func sendSessionsToWatch(_ sessions: [SessionModel]) {
        guard WCSession.default.activationState == .activated else { return }
        
        let sessionData = sessions.map { session in
            SessionData(
                id: session.calendarEventID, // Using calendarEventID as unique identifier
                startTime: session.startTime,
                endTime: session.endTime,
                sessionType: session.sessionType.rawValue,
                status: session.status.rawValue,
                calendarEventID: session.calendarEventID
            )
        }
        
        do {
            let data = try JSONEncoder().encode(sessionData)
            WCSession.default.sendMessage(["sessions": data], replyHandler: nil) { error in
                print("Error sending sessions to watch: \(error.localizedDescription)")
            }
        } catch {
            print("Error encoding sessions: \(error.localizedDescription)")
        }
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("iPhone WC activated: \(activationState.rawValue)")
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("WC session did become inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("WC session did deactivate")
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("Received message from watch: \(message)")
        
        if message["request"] as? String == "sessions" {
            DispatchQueue.main.async {
                print("Watch is requesting sessions - implementing session fetch...")
            }
        }
    }
}
