import SwiftUI
import SwiftData

struct OnboardThanksForLettingUsKnow: View {
    
    @AppStorage("isNewUser") private var isNewUser: Bool = true

    @StateObject private var viewModel = OnboardingViewModel()

    @EnvironmentObject private var eventStoreManager: EventStoreManager

    @Environment(\.modelContext) private var modelContext
    private var goalManager: GoalManager {
        GoalManager(modelContext: modelContext)
    }
    private var sessionManager: JoggingSessionManager {
        JoggingSessionManager(modelContext: modelContext)
    }
    private var preferencesManager: PreferencesManager {
        PreferencesManager(modelContext: modelContext)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer()

            // Title
            Text("Thanks for letting us know!")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.primary)
                .transition(.move(edge: .leading).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.4), value: UUID())

            // Subtitle
            Text("Your jogging schedule has been updated accordingly.")
                .font(.system(size: 18))
                .foregroundColor(.secondary)
                .transition(.opacity)
                .animation(.easeIn(duration: 0.3), value: UUID())

        

            // Start Jogging Button
            Button {
                eventStoreManager.eventStore.requestAccess(to: .event) { granted, error in
                    DispatchQueue.main.async {
                        if granted {
                            Task {
                                await viewModel.scheduleFirstJog(sessionManager: sessionManager, storeManager: eventStoreManager)
                                isNewUser = false  /// runs after session creation + save is done so that when upcoming session is loaded, no dummy data
                            }
                        } else {
                            print("❌ Calendar access not granted.")
                        }
                    }
                }
            } label: {
                Text("Let's start jogging!")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .padding()
                    .frame(width: 200, height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Color.primary, lineWidth: 1)
                    )
            }
            .transition(.scale)
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: UUID())

            Spacer()
            
            // Progress Bar - Moved to bottom
            ProgressView(value: 1.0, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle())
                .tint(.primary)
                .frame(height: 6)
                .padding(.top, 20)
                .padding(.bottom, 20)
        }
        .padding(40)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .onAppear{
            viewModel.fetchData(goalManager: goalManager, preferencesManager: preferencesManager)
        }
    }
}

#Preview {
    NavigationStack {
        OnboardThanksForLettingUsKnow()
    }
}
