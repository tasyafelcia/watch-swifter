// Swifter/Views/UpcomingSession.swift
import SwiftUI

struct UpcomingSession: View {
    @State private var showProgress = false
    @State private var forceUpdateProgress = false

    @EnvironmentObject private var eventStoreManager: EventStoreManager
    @Environment(\.modelContext) private var modelContext

    private var goalManager: GoalManager { GoalManager(modelContext: modelContext) }
    private var sessionManager: JoggingSessionManager { JoggingSessionManager(modelContext: modelContext) }
    private var preferencesManager: PreferencesManager { PreferencesManager(modelContext: modelContext) }

    @StateObject private var viewModel = UpcomingSessionViewModel()

    // ... (Formatter dan fungsi formatTimeUntil tidak berubah) ...
    private let cardDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, d MMM"
        return formatter
    }()

    private let cardTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        return formatter
    }()
    
    private func formatTimeUntil(nextStart: Date) -> String {
        let now = Date()
        let timeInterval = nextStart.timeIntervalSince(now)

        if timeInterval < 0 {
            return "Happening now"
        } else if timeInterval < 60 {
            return "In <1 minute"
        } else if timeInterval < 3600 {
            return "In \(Int(timeInterval / 60)) minutes"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            if Calendar.current.isDateInTomorrow(nextStart) {
                return "Tomorrow at \(cardTimeFormatter.string(from: nextStart).lowercased())"
            }
            return "In \(hours) hour\(hours > 1 ? "s" : "")"
        } else {
            let days = Int(timeInterval / 86400)
            if days == 1 && Calendar.current.isDateInTomorrow(nextStart) {
               return "Tomorrow at \(cardTimeFormatter.string(from: nextStart).lowercased())"
            }
            return "In \(days) days"
        }
    }


    var body: some View {
        // Tidak ada NavigationView atau NavigationStack di sini
        ScrollView {
            VStack(spacing: 24) {
                upcomingSessionCard()
                    .padding(.horizontal, 16)

                actionButtons()
                    .padding(.horizontal, 16)

                weeklyProgressCard()
                    .padding(.horizontal, 16)
            }
            .padding(.vertical, 20)
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .navigationTitle("Sessions") // Ini akan mengatur judul di NavigationBar
        .navigationBarTitleDisplayMode(.large) // Untuk judul besar
        .toolbar { // Ini akan menempatkan item di NavigationBar
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    viewModel.preferencesModalShown = true
                }) {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(.white)
                }
            }
        }
        // ... (sheet, alert, onAppear tidak berubah) ...
        .sheet(isPresented: $viewModel.preferencesModalShown) {
            EditPreferencesModal(isPresented: $viewModel.preferencesModalShown, modelContext: modelContext, onSave: {
                viewModel.rescheduleSessions(eventStoreManager: eventStoreManager, preferencesManager: preferencesManager, sessionManager: sessionManager)
                viewModel.fetchData(goalManager: goalManager, sessionManager: sessionManager)
                updateProgressAnimation()
            })
            .presentationDetents([.height(600)])
            .preferredColorScheme(.dark)
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
                    updateProgressAnimation()
                }
            )
            .presentationDetents([.height(300)])
            .preferredColorScheme(.dark)
        }
        .alert(isPresented: $viewModel.alertIsShown) {
            if(viewModel.goalIsCompleted) {
                Alert(
                    title: Text("Weekly goal completed! 🎉"),
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
                    title: Text("Jog sessions updated 🗓️"),
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
                // Handle access
            }
            updateProgressAnimation()
        }
    }

    // ... (updateProgressAnimation dan @ViewBuilder untuk kartu tidak berubah) ...
    private func updateProgressAnimation() {
        showProgress = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            showProgress = true
            forceUpdateProgress.toggle()
        }
    }

    @ViewBuilder
    private func upcomingSessionCard() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Upcoming Jog Session at")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(UIColor.systemGray2))
                .padding(EdgeInsets(top: 20, leading: 20, bottom: 10, trailing: 20))

            Divider()
                .background(Color(UIColor.systemGray3))

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(cardDateFormatter.string(from: viewModel.nextStart))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)

                        Text("\(cardTimeFormatter.string(from: viewModel.nextStart).lowercased()) - \(cardTimeFormatter.string(from: viewModel.nextEnd).lowercased())")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Image("Swifter.logo") //
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 65, height: 65)
                }
                
                Text(formatTimeUntil(nextStart: viewModel.nextStart))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.orange)
            }
            .padding(EdgeInsets(top: 16, leading: 20, bottom: 20, trailing: 20))
        }
        .background(Color(red: 22/255, green: 22/255, blue: 24/255))
        .cornerRadius(20)
    }

    @ViewBuilder
    private func actionButtons() -> some View {
        HStack(spacing: 16) {
            Button(action: {
                viewModel.rescheduleSessions(eventStoreManager: eventStoreManager, preferencesManager: preferencesManager, sessionManager: sessionManager)
                viewModel.fetchData(goalManager: goalManager, sessionManager: sessionManager)
                viewModel.alertIsShown = true
                viewModel.sessionIsChanged = true
            }) {
                Text("Reschedule")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Color(UIColor.systemGray2).opacity(0.25))
                    .clipShape(Capsule())
            }

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
                updateProgressAnimation()
            }) {
                Text("Mark as Done")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Color.green)
                    .clipShape(Capsule())
            }
        }
    }

    @ViewBuilder
    private func weeklyProgressCard() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Weekly Progress")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Button(action: {
                    viewModel.goalModalShown = true
                }) {
                    HStack(spacing: 5) {
                        Text("Edit Goal")
                        Image(systemName: "pencil")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(UIColor.systemGray2))
                    .padding(EdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14))
                    .background(Color(UIColor.systemGray2).opacity(0.2))
                    .clipShape(Capsule())
                }
            }
            .padding(EdgeInsets(top: 20, leading: 20, bottom: 12, trailing: 20))

            Divider()

            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(Color(UIColor.systemGray3).opacity(0.8), lineWidth: 11)
                        .frame(width: 75, height: 75)

                    Circle()
                        .trim(from: 0.0, to: showProgress ? (viewModel.currentGoal.targetFrequency > 0 ? Double(viewModel.currentGoal.progress) / Double(viewModel.currentGoal.targetFrequency) : 0.0) : 0.0)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.green]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 11, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 75, height: 75)
                        .animation(.easeOut(duration: 1.0), value: showProgress)
                        .animation(.easeOut(duration: 1.0), value: viewModel.currentGoal.progress)
                        .animation(.easeOut(duration: 1.0), value: forceUpdateProgress)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(viewModel.currentGoal.progress)/\(viewModel.currentGoal.targetFrequency)")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.white)
                    Text("Runs completed this week")
                        .font(.system(size: 15))
                        .foregroundColor(Color(UIColor.systemGray2))
                }
                Spacer()
            }
            .padding(EdgeInsets(top: 16, leading: 20, bottom: 20, trailing: 20))
        }
        .background(Color(red: 22/255, green: 22/255, blue: 24/255))
        .cornerRadius(20)
    }
}

#Preview {
    NavigationView {
        UpcomingSession()
            .environmentObject(EventStoreManager())
    }
    .preferredColorScheme(.dark)
}
