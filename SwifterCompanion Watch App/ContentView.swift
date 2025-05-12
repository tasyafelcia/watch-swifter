//  ContentView.swift (Watch App) - FIXED VERSION
//  Replace in SwifterCompanion Watch App target

import SwiftUI

struct ContentView: View {
    @StateObject private var sessionManager = WatchSessionManager.shared
    @State private var isRefreshing = false
    
    var body: some View {
        NavigationView {
            VStack {
                if sessionManager.sortedSessionsForToday.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "figure.run.circle")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("No sessions today")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Button("Refresh") {
                            refreshSessions()
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Sessions list
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(sessionManager.sortedSessionsForToday, id: \.id) { session in
                                SessionCard(session: session)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.bottom, 20)
                    }
                    .refreshable {
                        await refreshSessionsAsync()
                    }
                }
            }
            .navigationTitle("Sessions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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
    
    private func refreshSessions() {
        isRefreshing = true
        sessionManager.requestSessionsFromPhone()
        
        // Stop animation after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isRefreshing = false
        }
    }
    
    private func refreshSessionsAsync() async {
        await withCheckedContinuation { continuation in
            refreshSessions()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                continuation.resume()
            }
        }
    }
}

struct SessionCard: View {
    let session: SessionData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Session type and status
            HStack {
                Text(session.sessionType)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                StatusBadge(status: session.status)
            }
            
            // Time information
            HStack {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(iconColor)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(timeRangeText)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    if session.startTime > Date() {
                        Text("in \(timeUntilText)")
                            .font(.caption)
                            .foregroundColor(.orange)
                    } else if session.endTime > Date() {
                        Text("Currently active")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor.opacity(0.8))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(iconColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var iconName: String {
        switch session.sessionType {
        case "Pre-jogging":
            return "figure.flexibility"
        case "Jogging":
            return "figure.run"
        case "Post-jogging":
            return "figure.cooldown"
        default:
            return "figure.run"
        }
    }
    
    private var iconColor: Color {
        switch session.sessionType {
        case "Pre-jogging":
            return .green
        case "Jogging":
            return .blue
        case "Post-jogging":
            return .purple
        default:
            return .blue
        }
    }
    
    // FIXED: Use a more compatible approach for background color
    private var backgroundColor: Color {
        if #available(watchOS 7.0, *) {
            return Color(UIColor.black)
        } else {
            return Color.gray.opacity(0.2)
        }
    }
    
    private var timeRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "\(formatter.string(from: session.startTime)) - \(formatter.string(from: session.endTime))"
    }
    
    private var timeUntilText: String {
        let timeUntil = session.startTime.timeIntervalSinceNow
        
        let hours = Int(timeUntil) / 3600
        let minutes = Int(timeUntil) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "now"
        }
    }
}

struct StatusBadge: View {
    let status: String
    
    var body: some View {
        Text(status)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.8))
            .foregroundColor(.white)
            .clipShape(Capsule())
    }
    
    private var statusColor: Color {
        switch status {
        case "Done":
            return .green
        case "Not started yet":
            return .orange
        case "Missed":
            return .red
        default:
            return .gray
        }
    }
}

#Preview {
    ContentView()
}
