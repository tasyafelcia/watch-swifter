import SwiftUI
import WidgetKit

struct ContentView: View {
    @StateObject private var sessionManager = WatchSessionManager.shared
    @State private var isRefreshing = false
    @State private var showDebugInfo = false
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
                        
                        // Connection status
                        Text(sessionManager.connectionStatus)
                            .font(.caption)
                            .foregroundColor(.orange)
                        
                        VStack(spacing: 8) {
                            Button("Refresh") {
                                refreshSessions()
                            }
                            .buttonStyle(.bordered)
                            
                            Button(showDebugInfo ? "Hide Debug" : "Show Debug") {
                                showDebugInfo.toggle()
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
                                isMainCard: true,
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
                    Button(showDebugInfo ? "🐛" : "••") {
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
            // Handle deep link from complication
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
                
                Button("Update Custom Widget") {
                    sessionManager.updateCustomWidget()
                    print("Custom widget updated")
                }
                .buttonStyle(.bordered)
                
                Button("Force Refresh All Widgets") {
                    sessionManager.forceRefreshWidgets()
                    print("All widgets force refreshed")
                }
                .buttonStyle(.bordered)
                
                Button("Clear Widget Cache") {
                    UserDefaults.standard.removeObject(forKey: "nextSession")
                    if let appGroup = UserDefaults(suiteName: "group.com.yourteam.swifter.shared") {
                        appGroup.removeObject(forKey: "nextSession")
                    }
                    WidgetCenter.shared.reloadAllTimelines()
                    print("Widget cache cleared")
                }
                .buttonStyle(.borderless)
                .font(.caption)
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
        
        // Stop animation after 2 seconds
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
                // Session type label (small text at top)
                Text(sessionTypeLabel)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .opacity(isMainCard ? 0.8 : 0.6)
                
                // Main card
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        Text(mainSessionType)
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
                            // Motion lines
                            HStack(spacing: 3) {
                                RoundedRectangle(cornerRadius: 1.5)
                                    .fill(Color.green)
                                    .frame(width: 3, height: 12)
                                RoundedRectangle(cornerRadius: 1.5)
                                    .fill(Color.blue)
                                    .frame(width: 3, height: 9)
                                RoundedRectangle(cornerRadius: 1.5)
                                    .fill(Color.green)
                                    .frame(width: 3, height: 6)
                            }
                            .offset(x: -12)
                            
                            // Running figure
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
                .scaleEffect(cardScale)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: cardScale)
                
                // Bottom session type label (small text at bottom)
                Text(bottomSessionType)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .opacity(isMainCard ? 0.8 : 0.6)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
    
    private var sessionTypeLabel: String {
        let allSessions = WatchSessionManager.shared.displaySessions
        let sessionIndex = allSessions.firstIndex { $0.id == session.id } ?? 0
        
        if sessionIndex > 0 {
            return allSessions[sessionIndex - 1].sessionType
        }
        return ""
    }
    
    private var mainSessionType: String {
        switch session.sessionType {
        case "Pre-jogging":
            return "Pre Jog"
        case "Jogging":
            return "Jog Session"
        case "Post-jogging":
            return "Post Jog"
        default:
            return session.sessionType
        }
    }
    
    private var bottomSessionType: String {
        let allSessions = WatchSessionManager.shared.displaySessions
        let sessionIndex = allSessions.firstIndex { $0.id == session.id } ?? 0
        
        if sessionIndex < allSessions.count - 1 {
            return allSessions[sessionIndex + 1].sessionType == "Pre-jogging" ? "Pre-Jog" :
                   allSessions[sessionIndex + 1].sessionType == "Jogging" ? "Jog Session" :
                   allSessions[sessionIndex + 1].sessionType == "Post-jogging" ? "Post-Jog" :
                   allSessions[sessionIndex + 1].sessionType
        }
        return ""
    }
    
    private var timeRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "H:mm"
        return "\(formatter.string(from: session.startTime)) - \(formatter.string(from: session.endTime))"
    }
    
    private var cardBackgroundColor: Color {
        if session.sessionType == "Jogging" {
            return Color.green
        }
        return Color.black
    }
    
    private var cardScale: CGFloat {
        if currentIndex == index {
            return 1.0 // Full scale for focused card
        } else {
            return 0.85 // Slightly smaller for non-focused cards
        }
    }
}

#Preview {
    ContentView()
}
