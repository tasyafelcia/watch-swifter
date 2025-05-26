// tasyafelcia/watch-swifter/watch-swifter-e582a31a3fb6dc08417297febf88ab00ecc25ae5/SwifterCompanion Watch App/ContentView.swift
import SwiftUI
import WidgetKit

struct ContentView: View {
    @StateObject private var sessionManager = WatchSessionManager.shared
    @State private var isRefreshing = false
    @State private var showDebugInfo = false // Pastikan ini adalah @State
    @State private var currentIndex = 0

    var body: some View {
        NavigationView {
            VStack {
                if sessionManager.displaySessions.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "figure.run.circle")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)

                        Text("No upcoming sessions")
                            .font(.headline)
                            .foregroundColor(.gray)

                        Text(sessionManager.connectionStatus)
                            .font(.caption)
                            .foregroundColor(.orange)

                        VStack(spacing: 8) {
                            Button("Refresh") {
                                refreshSessions()
                            }
                            .buttonStyle(.bordered)

                            // Tombol untuk toggle showDebugInfo
                            Button(showDebugInfo ? "Hide Debug" : "Show Debug") {
                                showDebugInfo.toggle() // Cara yang benar untuk toggle @State Bool
                            }
                            .buttonStyle(.borderless)
                            .font(.caption)
                        }

                        if showDebugInfo {
                            debugInfoView
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Card-based sessions UI
                    TabView(selection: $currentIndex) {
                        ForEach(Array(sessionManager.displaySessions.enumerated()), id: \.element.id) { index, session in
                            SessionCardView(
                                session: session,
                                isMainCard: currentIndex == index, // Dinamis berdasarkan currentIndex
                                index: index,
                                currentIndex: currentIndex
                            )
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.2), value: currentIndex)
                }
            }
            .navigationTitle("Sessions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(showDebugInfo ? "🐛" : "••") { // Toggle debug info
                        showDebugInfo.toggle()
                    }
                    .font(.caption)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: refreshSessions) {
                        Image(systemName: "arrow.clockwise")
                            .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                            .animation(.linear(duration: 1).repeatCount(isRefreshing ? .max : 1, autoreverses: false), value: isRefreshing)
                    }
                }
            }
        }
        .onOpenURL { url in
            if url.absoluteString == "swifter://sessions" {
                refreshSessions()
            }
        }
        .onAppear {
            refreshSessions()
        }
    }

    private var debugInfoView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Debug Info")
                .font(.headline)
                .foregroundColor(.white)

            Text("Status: \(sessionManager.connectionStatus)")
                .font(.caption)
                .foregroundColor(.orange)

            Text("Connected: \(sessionManager.isConnected ? "Yes" : "No")")
                .font(.caption)
                .foregroundColor(sessionManager.isConnected ? .green : .red)

            Text("Last Update: \(DateFormatter.localizedString(from: sessionManager.lastUpdate, dateStyle: .none, timeStyle: .short))")
                .font(.caption)
                .foregroundColor(.gray)

            Text("Total Sessions: \(sessionManager.sessions.count)")
                .font(.caption)
                .foregroundColor(.gray)

            // Widget debug buttons
            VStack(spacing: 6) {
                Text("Widget Controls")
                    .font(.caption)
                    .foregroundColor(.yellow)

                Button("Update Widget Data") {
                    // Panggil fungsi yang benar dari WatchSessionManager
                    sessionManager.saveNextSessionForWidget()
                    print("Widget data update requested via WatchSessionManager")
                }
                .buttonStyle(.bordered)

                Button("Force Refresh All Widgets") {
                    sessionManager.forceRefreshWidgets()
                    print("All widgets force refresh requested via WatchSessionManager")
                }
                .buttonStyle(.bordered)

                // Tombol Clear Widget Cache sebaiknya juga memanggil fungsi di manager jika perlu
                // atau pastikan menggunakan appGroupId dan key yang sama.
                // Untuk saat ini, forceRefreshWidgets di WatchSessionManager sudah melakukan clear dan save.
                // Button("Clear Widget Cache") {
                //     if let appGroup = UserDefaults(suiteName: sessionManager.appGroupId) { // Gunakan appGroupId dari manager
                //         appGroup.removeObject(forKey: sessionManager.widgetSessionKey) // Gunakan key dari manager
                //     }
                //     WidgetCenter.shared.reloadAllTimelines()
                //     print("Widget cache cleared")
                // }
                // .buttonStyle(.borderless)
                // .font(.caption)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
        )
    }

    private func refreshSessions() {
        isRefreshing = true
        sessionManager.requestSessionsFromPhone()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isRefreshing = false
        }
    }
}

struct SessionCardView: View {
    let session: SessionData
    let isMainCard: Bool
    let index: Int
    let currentIndex: Int

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 16) {
                Text(topLabelText) // Menggunakan computed property baru
                    .font(.caption)
                    .foregroundColor(.gray)
                    .opacity(isMainCard ? 0.8 : 0.6)

                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        Text(session.sessionType.displayName) // Menggunakan displayName
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(.white)

                        Text(timeRangeText)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    HStack {
                        Spacer()
                        ZStack {
                            HStack(spacing: 3) {
                                RoundedRectangle(cornerRadius: 1.5).fill(Color.green).frame(width: 3, height: 12)
                                RoundedRectangle(cornerRadius: 1.5).fill(Color.blue).frame(width: 3, height: 9)
                                RoundedRectangle(cornerRadius: 1.5).fill(Color.green).frame(width: 3, height: 6)
                            }
                            .offset(x: -12)
                            Image(systemName: "figure.run")
                                .font(.system(size: 32, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(.trailing, 20)
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(cardBackgroundColor)
                )
                .scaleEffect(isMainCard ? 1.0 : 0.85) // Skala berdasarkan apakah ini kartu utama
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isMainCard)


                Text(bottomLabelText) // Menggunakan computed property baru
                    .font(.caption)
                    .foregroundColor(.gray)
                    .opacity(isMainCard ? 0.8 : 0.6)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }

    private var timeRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "H:mm"
        return "\(formatter.string(from: session.startTime)) - \(formatter.string(from: session.endTime))"
    }

    private var cardBackgroundColor: Color {
        // Warna berdasarkan tipe sesi mentah, bukan displayName
        if session.sessionType == "Jogging" {
            return Color.green
        }
        return Color.black
    }
    
    // Logika untuk label atas dan bawah, mengambil dari WatchSessionManager.shared.displaySessions
    // untuk mendapatkan sesi sebelum dan sesudahnya dalam urutan tampilan saat ini.
    private var topLabelText: String {
        let allDisplaySessions = WatchSessionManager.shared.displaySessions
        guard let currentSessionIndex = allDisplaySessions.firstIndex(where: { $0.id == session.id }) else {
            return ""
        }
        if currentSessionIndex > 0 {
            return allDisplaySessions[currentSessionIndex - 1].sessionType.displayName
        }
        return ""
    }

    private var bottomLabelText: String {
        let allDisplaySessions = WatchSessionManager.shared.displaySessions
        guard let currentSessionIndex = allDisplaySessions.firstIndex(where: { $0.id == session.id }) else {
            return ""
        }
        if currentSessionIndex < allDisplaySessions.count - 1 {
            return allDisplaySessions[currentSessionIndex + 1].sessionType.displayName
        }
        return ""
    }
}

#Preview { // Pastikan preview juga berfungsi jika diperlukan
    ContentView()
}
