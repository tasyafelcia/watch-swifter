import SwiftUI

struct OnboardJoggingFrequency: View {
    @Environment(\.modelContext) private var modelContext
    private var goalManager: GoalManager {
        GoalManager(modelContext: modelContext)
    }

    @State private var joggingFrequency: Int = 0 // Default value
    
    // Animation states
    @State private var showTitle = false
    @State private var showStepper = false
    @State private var showNextButton = false
    @State private var showProgress = false

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Spacer()
                
                // Title with animation
                Text("What’s your target jogging frequency for this week?")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                    .opacity(showTitle ? 1 : 0)
                    .offset(y: showTitle ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.1), value: showTitle)

                // Stepper with animation
                HStack {
                    Button(action: {
                        if joggingFrequency > 0 {
                            joggingFrequency -= 1
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(joggingFrequency == 0 ? .gray : .primary)
                            .opacity(joggingFrequency == 0 ? 0.5 : 1.0)
                    }
                    .disabled(joggingFrequency == 0)

                    Spacer()

                    Text("\(joggingFrequency) times a week")
                        .font(.system(size: 24, weight: .bold))
                        .frame(minWidth: 150)
                        .multilineTextAlignment(.center)

                    Spacer()

                    Button(action: {
                        if joggingFrequency < 7 {
                            joggingFrequency += 1
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.primary)
                    }
                }
                .padding(.top, 10)
                .opacity(showStepper ? 1 : 0)
                .offset(y: showStepper ? 0 : 20)
                .animation(.easeOut(duration: 0.6).delay(0.2), value: showStepper)

                // Next Button with animation
                HStack {
                    Spacer()
                    if joggingFrequency > 0 {
                        NavigationLink(destination: OnboardAllSet()) {
                            Text("Next")
                                .font(.system(size: 14))
                                .foregroundColor(.primary)
                                .padding()
                                .frame(width: 150, height: 45)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(Color.primary, lineWidth: 1)
                                )
                        }
                        .padding(.top, 150)
                        .padding(.bottom, 100)
                        .simultaneousGesture(TapGesture().onEnded {
                            goalManager.createNewGoal(
                                targetFreq: joggingFrequency,
                                startingDate: Date(),
                                endingDate: Date().addingTimeInterval(60 * 60 * 24 * 7)
                            )
                        })
                    } else {
                        Text("Next")
                            .font(.system(size: 14))
                            .frame(width: 150, height: 45)
                            .opacity(0)
                            .padding(.top, 150)
                            .padding(.bottom, 100)
                    }
                }
                .opacity(showNextButton ? 1 : 0)
                .offset(y: showNextButton ? 0 : 20)
                .animation(.easeOut(duration: 0.6).delay(0.3), value: showNextButton)

                // Progress Bar with animation
                ProgressView(value: 0.5, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle())
                    .tint(.primary)
                    .frame(height: 4)
                    .padding(.top, 10)
                    .opacity(showProgress ? 1 : 0)
                    .offset(y: showProgress ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.4), value: showProgress)
            }
            .padding(30)
            .onAppear {
                showTitle = true
                showStepper = true
                showNextButton = true
                showProgress = true
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    OnboardJoggingFrequency()
}
