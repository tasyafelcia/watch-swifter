import SwiftUI

struct OnboardTimeOnFeet: View {
    @State private var joggingMinutes: Int = 40  // Default value
    @State private var animateText = false
    @State private var animateStepper = false
    @State private var animateNextButton = false

    @Environment(\.modelContext) private var modelContext
    private var preferencesManager: PreferencesManager {
        PreferencesManager(modelContext: modelContext)
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Spacer()
                
                Text("How long do you usually stay on your feet during a jog?")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                    .opacity(animateText ? 1 : 0)
                    .offset(y: animateText ? 0 : 20)
                    .animation(.easeOut(duration: 0.8), value: animateText)
                    .navigationBarBackButtonHidden(true)

                // Custom Stepper with animation
                HStack {
                    // Minus Button
                    Button(action: {
                        if joggingMinutes > 0 {
                            joggingMinutes -= 5
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(joggingMinutes == 0 ? .gray : .primary)
                            .opacity(joggingMinutes == 0 ? 0.5 : 1.0)
                            .scaleEffect(animateStepper ? 1.0 : 0.8)
                            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: animateStepper)
                    }
                    .disabled(joggingMinutes == 0)

                    Spacer()

                    // Jogging Minutes in the Middle
                    Text("\(joggingMinutes) min")
                        .foregroundColor(.primary)
                        .font(.system(size: 24, weight: .bold))
                        .frame(minWidth: 100)
                        .multilineTextAlignment(.center)
                        .opacity(animateStepper ? 1 : 0)
                        .offset(y: animateStepper ? 0 : 10)
                        .animation(.easeOut(duration: 0.7).delay(0.3), value: animateStepper)

                    Spacer()

                    // Plus Button
                    Button(action: {
                        if joggingMinutes < 120 {
                            joggingMinutes += 5
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.primary)
                            .scaleEffect(animateStepper ? 1.0 : 0.8)
                            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: animateStepper)
                    }
                }
                .padding(.top, 10)

                // Next Button Row
                HStack {
                    Spacer()
                    if joggingMinutes > 0 {
                        NavigationLink(destination: OnboardJoggingFrequency()) {
                            Text("Next")
                                .font(.system(size: 14))
                                .foregroundColor(.primary)
                                .padding()
                                .frame(width: 150, height: 45)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(Color.primary, lineWidth: 1)
                                )
                                .scaleEffect(animateNextButton ? 1.05 : 1.0)
                                .animation(.spring(response: 0.5, dampingFraction: 0.5), value: animateNextButton)
                        }
                        .padding(.top, 150)
                        .padding(.bottom, 100)
                        .simultaneousGesture(TapGesture().onEnded {
                            preferencesManager.createNewPreference(timeOnFeet: joggingMinutes)
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

                // Progress Bar
                ProgressView(value: 0.25, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle())
                    .tint(.primary)
                    .frame(height: 5)
                    .padding(.bottom, 10)
                    .scaleEffect(animateText ? 1.0 : 0.9)
                    .opacity(animateText ? 1 : 0)
                    .animation(.easeOut(duration: 0.7).delay(0.2), value: animateText)

            }
            .padding(30)
            .onAppear {
                animateText = true
                animateStepper = true
                animateNextButton = true
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    OnboardTimeOnFeet()
}
