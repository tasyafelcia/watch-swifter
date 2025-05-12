import SwiftUI

struct OnboardAllSet: View {
    // Animation States
    @State private var showTitle = false
    @State private var showSubtitle = false
    @State private var showQuestion = false
    @State private var showYesButton = false
    @State private var showMaybeButton = false
    @State private var showProgress = false

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
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Spacer()

                // Title
                Text("Great! We're all set.")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.primary)
                    .opacity(showTitle ? 1 : 0)
                    .offset(y: showTitle ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.1), value: showTitle)

                // Subtitle
                Text("Thanks for letting us get to know you a little bit better. We've scheduled your next jogging session!")
                    .font(.system(size: 18))
                    .foregroundColor(.primary)
                    .opacity(showSubtitle ? 1 : 0)
                    .offset(y: showSubtitle ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.2), value: showSubtitle)

                // Question
                Text("Before we start, do you want to further customize your preferences?")
                    .font(.system(size: 18))
                    .foregroundColor(.primary)
                    .opacity(showQuestion ? 1 : 0)
                    .offset(y: showQuestion ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.3), value: showQuestion)

                // Yes Button
                NavigationLink(destination: OnboardPreJogTime()) {
                    Text("Yes, please")
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color.primary, lineWidth: 1)
                        )
                }
                .fixedSize(horizontal: true, vertical: false)
                .opacity(showYesButton ? 1 : 0)
                .offset(y: showYesButton ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.4), value: showYesButton)

                // Maybe Later Button
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
                } label: { // TODO: Replace EmptyView() with your HomePageView
                    HStack(spacing: 5) {
                        Text("Maybe Later")
                            .font(.system(size: 12))
                            .foregroundColor(.primary)
                            .opacity(0.6)
                            .padding(.leading, 7)

                        Image(systemName: "arrow.right")
                            .font(.system(size: 12))
                            .foregroundColor(.primary)
                            .opacity(0.6)
                            .padding(.leading, -2)
                    }
                    .padding(.vertical, 10)
                }
                .fixedSize(horizontal: true, vertical: false)
                .padding(.top, -15)
                .opacity(showMaybeButton ? 1 : 0)
                .offset(y: showMaybeButton ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.5), value: showMaybeButton)

                Spacer()

                // Progress Bar
                ProgressView(value: 1, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle())
                    .accentColor(.primary)
                    .frame(height: 4)
                    .padding(.top, 10)
                    .opacity(showProgress ? 1 : 0)
                    .offset(y: showProgress ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.6), value: showProgress)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(40)
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            showTitle = true
            showSubtitle = true
            showQuestion = true
            showYesButton = true
            showMaybeButton = true
            showProgress = true
            
            viewModel.fetchData(goalManager: goalManager, preferencesManager: preferencesManager)
        }
    }
}

#Preview {
    OnboardAllSet()
}
