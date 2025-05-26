// tasyafelcia/watch-swifter/watch-swifter-e582a31a3fb6dc08417297febf88ab00ecc25ae5/SwifterCompanion Watch App/WatchSessionManager.swift
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
    
    // GANTI DENGAN APP GROUP ID ANDA YANG SEBENARNYA
    private let appGroupId = "group.com.yourteam.swifter.shared"
    private let widgetSessionKey = "nextSessionWidgetData"

    private override init() {
        super.init()

        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        } else {
            connectionStatus = "Watch Connectivity not supported"
        }
    }

    func requestSessionsFromPhone() {
        guard WCSession.default.activationState == .activated else {
            connectionStatus = "Watch Connectivity not activated"
            print("WCSession not activated. State: \(WCSession.default.activationState.rawValue)")
            return
        }

        if !WCSession.default.isReachable {
            connectionStatus = "iPhone not reachable"
            print("iPhone not reachable. Using transferUserInfo...")
            WCSession.default.transferUserInfo(["request": "sessions"])
            return
        }

        connectionStatus = "Requesting sessions..."
        print("Sending session request to iPhone...")

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

    // MARK: - UserDefaults Integration for Widget/Complications
    func saveNextSessionForWidget() {
        guard let sessionToSave = self.nextSession else {
            print("No next session to save for widget")
            if let appGroupDefaults = UserDefaults(suiteName: appGroupId) {
                appGroupDefaults.removeObject(forKey: widgetSessionKey)
                print("Removed next session from app group UserDefaults for widget")
            }
            // Fallback jika perlu, meskipun idealnya app group selalu berhasil
            // UserDefaults.standard.removeObject(forKey: widgetSessionKey)
            WidgetCenter.shared.reloadAllTimelines()
            return
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        do {
            let sessionData = try encoder.encode(sessionToSave)
            if let appGroupDefaults = UserDefaults(suiteName: appGroupId) {
                appGroupDefaults.set(sessionData, forKey: widgetSessionKey)
                print("Saved next session to app group UserDefaults for widget: \(sessionToSave.sessionType) at \(sessionToSave.startTime)")
            } else {
                print("Failed to get app group UserDefaults when saving for widget")
                // Pertimbangkan fallback atau logging error yang lebih detail
            }
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("Error encoding session for widget: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Custom Widget Integration (Jika ada logika spesifik selain reload)
    // Jika forceRefreshWidgets sudah mencakup reloadAllTimelines, fungsi ini mungkin redundan
    // Kecuali jika ada data spesifik lain yang perlu disiapkan hanya untuk widget tertentu.
    // Untuk saat ini, saveNextSessionForWidget sudah memanggil reloadAllTimelines.

    func forceRefreshWidgets() {
        // Clear cached data
        if let appGroup = UserDefaults(suiteName: appGroupId) {
            appGroup.removeObject(forKey: widgetSessionKey)
        }
        // UserDefaults.standard.removeObject(forKey: widgetSessionKey) // Fallback

        // Save current session data
        saveNextSessionForWidget() // Ini akan menyimpan data baru dan memanggil reloadAllTimelines()

        // Pastikan semua jenis widget relevan juga dimuat ulang jika ada beberapa
        // WidgetCenter.shared.reloadTimelines(ofKind: "SwifterComplications") // Jika ini widget lama/berbeda
        // WidgetCenter.shared.reloadTimelines(ofKind: "SwifterWatchWidget")   // Widget baru
        
        print("Force refreshed all widgets")
    }

    // Helper method to process session data
    private func processSessions(from data: Data, source: String) {
        do {
            let decodedSessions = try JSONDecoder().decode([SessionData].self, from: data)
            self.sessions = decodedSessions
            self.lastUpdate = Date()
            self.connectionStatus = "Sessions updated (\(source))"
            print("Received \(self.sessions.count) sessions from iPhone via \(source)")

            // Simpan sesi yang relevan (self.nextSession akan diperbarui) untuk widget
            self.saveNextSessionForWidget() // Ini akan menyimpan dan memuat ulang widget

        } catch {
            print("Error decoding sessions from \(source): \(error.localizedDescription)")
            self.connectionStatus = "Decode error"
        }
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

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("Watch received message: \(message)")
        DispatchQueue.main.async {
            if let sessionData = message["sessions"] as? Data {
                self.processSessions(from: sessionData, source: "message")
            }
        }
    }

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

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any]) {
        print("Watch received user info: \(userInfo)")
        DispatchQueue.main.async {
            if let sessionData = userInfo["sessions"] as? Data {
                self.processSessions(from: sessionData, source: "user info")
            }
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print("Watch received application context: \(applicationContext)")
        DispatchQueue.main.async {
            if let sessionData = applicationContext["sessions"] as? Data {
                self.processSessions(from: sessionData, source: "application context")
            }
        }
    }
}
