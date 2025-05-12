import SwiftUI

struct UpcomingSession: View {
    @State private var showProgress = false
    @State private var forceUpdateProgress = false
    
    @EnvironmentObject private var eventStoreManager: EventStoreManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    
    private var goalManager: GoalManager {
        GoalManager(modelContext: modelContext)
    }
    
    private var sessionManager: JoggingSessionManager {
        JoggingSessionManager(modelContext: modelContext)
    }
    
    private var preferencesManager: PreferencesManager {
        PreferencesManager(modelContext: modelContext)
    }
    
    @StateObject private var viewModel = UpcomingSessionViewModel()
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMMM"
        return formatter
    }()
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 15) {
            // Header
            HStack {
                Text("Sessions")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.leading)
                
                Spacer()
                
                Button(action: {
                    viewModel.preferencesModalShown = true
                }) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                .padding(.trailing)
            }
            .padding(.top)
            .padding(.bottom, 15)
            
            ScrollView {
                VStack(spacing: 16) {
                    // Upcoming Session Card
                    VStack(spacing: 0) {
                        // Header section
                        HStack {
                            Text(viewModel.nextStart.timeIntervalSinceNow > 60*60*24 ? "Next Jog Session" : "Next Jogging Session")
                                .font(.headline)
                                .foregroundColor(.white) // Always white for better visibility on card
                                .padding(.horizontal)
                                .padding(.top, 14)
                            Spacer()
                        }
                        
                        Divider()
                            .background(Color.white.opacity(0.3)) // Consistent white divider
                            .padding(.top, 8)
                        
                        // Main content - Improved hierarchy
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 6) {
                                // Primary information: Date (most important)
                                Text(dateFormatter.string(from: viewModel.nextStart))
                                    .font(.system(size: 26, weight: .bold, design: .default))
                                    .foregroundColor(.white)
                                
                                // Secondary information: Time
                                Text("\(timeFormatter.string(from: viewModel.nextStart).lowercased()) - \(timeFormatter.string(from: viewModel.nextEnd).lowercased())")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                // Tertiary information: How soon
                                Text(viewModel.timeUntil > 60 * 60 * 24 ? "In \(viewModel.days) days" : "Tomorrow")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding(.top, 2)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                            
                            Spacer()
                            
                            Image("Swifter.logo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 90, height: 80)
                                .foregroundColor(.white)
                                .padding(.trailing, 24)
                        }
                        
                        // Goal section
                        HStack {
                            HStack {
                                Text("Goal: Jog \(viewModel.currentGoal.targetFrequency) times in a week")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                
                                Button(action: {
                                    viewModel.goalModalShown = true
                                }) {
                                    Image(systemName: "pencil")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(2)
                                        .background(Color.gray.opacity(0.5))
                                        .clipShape(Circle())
                                }
                                .padding(.leading, 4)
                            }
                            .padding(.vertical, 5)
                            .padding(.horizontal, 10)
                            .background(colorScheme == .dark ? Color.gray : Color(UIColor.darkGray))
                            .cornerRadius(20)
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 14)
                        .padding(.top, 4)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(colorScheme == .dark ? Color(uiColor: .systemGray6) : Color.black)
                    )
                    .padding(.horizontal)
                    
                    // Action Buttons
                    HStack(spacing: 12) {
                        Button(action: {
                            viewModel.rescheduleSessions(eventStoreManager: eventStoreManager, preferencesManager: preferencesManager, sessionManager: sessionManager)
                            viewModel.fetchData(goalManager: goalManager, sessionManager: sessionManager)
                            viewModel.alertIsShown = true
                            viewModel.sessionIsChanged = true
                        }) {
                            Text("Reschedule")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .background(
                                    RoundedRectangle(cornerRadius: 30)
                                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                        .background(Color.gray.opacity(0.1).cornerRadius(30))
                                )
                        }
                        .accessibilityLabel("Reschedule jogging session")
                        
                        Button(action: {
                            let flag = viewModel.markSessionAsComplete(sessionManager: sessionManager, goalManager: goalManager)
                            if flag {
                                viewModel.goalIsCompleted = true
                                viewModel.alertIsShown = true
                            } else {
                                viewModel.createNewSession(sessionManager: sessionManager, storeManager: eventStoreManager, preferencesManager: preferencesManager)
                                viewModel.sessionIsChanged = true
                                viewModel.alertIsShown = true
                            }
                            
                            showProgress = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                viewModel.fetchData(goalManager: goalManager, sessionManager: sessionManager)
                                showProgress = true
                                forceUpdateProgress.toggle()
                            }
                        }) {
                            Text("Mark as Done")
                                .font(.headline)
                                .foregroundColor(colorScheme == .dark ? .black : .white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .background(
                                    RoundedRectangle(cornerRadius: 30)
                                        .fill(colorScheme == .dark ? Color.white : Color.black))
                        }
                        .accessibilityLabel("Mark jogging session as completed")
                    }
                    .padding(.horizontal)
                    
                    // Weekly Progress Card - Improved spacing
                    VStack(spacing: 0) {
                        // Header section
                        HStack {
                            Text("Weekly Progress")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                                .padding(.top, 14)
                            Spacer()
                        }
                        
                        Divider()
                            .background(Color.white.opacity(0.3))
                            .padding(.top, 8)
                        
                        // Content area with improved spacing
                        VStack(spacing: 0) {
                            HStack(alignment: .top, spacing: 10) {
                                // Left side - Progress circle
                                ZStack {
                                    
                                    Circle()
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 14)
                                        .frame(width: 100, height: 100) .padding(.top, 10)
                                    
                                    Circle()
                                        .trim(from: 0.0, to: showProgress ? Double(viewModel.currentGoal.progress) / Double(viewModel.currentGoal.targetFrequency) : 0.0)
                                        .stroke(
                                            LinearGradient(
                                                gradient: Gradient(colors: [.blue, Color.green]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                                
                                            ),
                                            lineWidth: 14
                                        )
                                        .rotationEffect(.degrees(-90))
                                        .frame(width: 100, height: 100)
                                        .animation(.easeOut(duration: 1.0), value: showProgress)
                                        .animation(.easeOut(duration: 1.0), value: viewModel.currentGoal.progress)
                                        .animation(.easeOut(duration: 1.0), value: forceUpdateProgress)
                                        .padding(.top, 10)
                                }
                                .padding(.leading, 20)
                                .accessibilityLabel("Progress: \(viewModel.currentGoal.progress) of \(viewModel.currentGoal.targetFrequency) runs completed")
                                
                                // Right side - Text and button
                                VStack(alignment: .leading, spacing: 8) {
                                    // Primary information: Progress fraction
                                    Text("\(viewModel.currentGoal.progress)/\(viewModel.currentGoal.targetFrequency)")
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    
                                    // Secondary information: Label for context
                                    Text("Runs completed this week")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.8))
                                        .padding(.bottom, 16)
                                    
                                    NavigationLink(destination: AnalyticsView()) {
                                        Text("View Summary")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(colorScheme == .dark ? .black : .white)
                                            .padding(.vertical, 10)
                                            .padding(.horizontal, 20)
                                            .background(colorScheme == .dark ? Color.white : Color(UIColor.darkGray))
                                            .cornerRadius(20)
                                    }
                                    .accessibilityHint("View detailed analysis of your jogging activity")
                                }
                                .padding(.leading, 20)
                                .padding(.trailing, 20)
                            }
                            .padding(.vertical, 16)
                        }
                        .padding(.bottom, 5) // Small bottom padding for balance
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(colorScheme == .dark ? Color(uiColor: .systemGray6) : Color.black)
                    )
                    .cornerRadius(16)
                    .padding(.horizontal)
                }
                .padding(.bottom, 16)
            }
        }
        .edgesIgnoringSafeArea(.bottom)
        .sheet(isPresented: $viewModel.preferencesModalShown) {
            EditPreferencesModal(isPresented: $viewModel.preferencesModalShown, modelContext: modelContext, onSave: {
                viewModel.rescheduleSessions(eventStoreManager: eventStoreManager, preferencesManager: preferencesManager, sessionManager: sessionManager)
                viewModel.fetchData(goalManager: goalManager, sessionManager: sessionManager)
                showProgress = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showProgress = true
                    forceUpdateProgress.toggle()
                }
            })
            .presentationDetents([.height(600)])
        }
        .sheet(isPresented: $viewModel.goalModalShown) {
            GoalSettingModal(
                isPresented: $viewModel.goalModalShown,
                goalToEdit: viewModel.currentGoal,
                onPreSave: {
                    viewModel.wipeAllSessionsRelatedToGoal(sessionManager: sessionManager, eventStoreManager: eventStoreManager)
                    viewModel.fetchData(goalManager: goalManager, sessionManager: sessionManager)
                },
                onPostSave: {
                    viewModel.createNewSession(sessionManager: sessionManager, storeManager: eventStoreManager, preferencesManager: preferencesManager)
                    viewModel.fetchData(goalManager: goalManager, sessionManager: sessionManager)
                    showProgress = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        showProgress = true
                        forceUpdateProgress.toggle()
                    }
                }
            )
            .presentationDetents([.height(300)])
        }
        .alert(isPresented: $viewModel.alertIsShown) {
            if(viewModel.goalIsCompleted) {
                Alert(
                    title: Text("Weekly goal completed! 🥳"),
                    message: Text("Congratulations! Let's keep up the pace by setting your next weekly goal."),
                    dismissButton: .default(Text("OK")) {
                        viewModel.alertIsShown = false
                        viewModel.markGoalAsComplete(goalManager: goalManager)
                        viewModel.createNewGoal(goalManager: goalManager)
                        viewModel.goalModalShown = true
                        viewModel.goalIsCompleted = false
                    })
            } else if (viewModel.sessionIsChanged) {
                Alert(
                    title: Text("Jog sessions updated 🏃🏽💨"),
                    message: Text("Don't forget to check in your calendar!"),
                    dismissButton: .default(Text("OK")) {
                        viewModel.alertIsShown = false
                        viewModel.sessionIsChanged = false
                    })
            } else {
                Alert(title: Text("Default alert"), message: Text("Lorem ipsum"), dismissButton: .default(Text("OK")){
                    viewModel.alertIsShown = false
                })
            }
        }
        .onAppear {
            viewModel.fetchData(goalManager: goalManager, sessionManager: sessionManager)
            
            eventStoreManager.eventStore.requestAccess(to: .event) { granted, error in
                DispatchQueue.main.async {
                    if granted {
                        // The calendar access is granted
                    } else {
                        print("❌ Calendar access not granted.")
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showProgress = true
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        UpcomingSession()
            .environmentObject(EventStoreManager())
    }
}
