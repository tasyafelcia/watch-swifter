import SwiftUI

struct OnboardPreferredJogTime: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme // Access system theme

    private var preferencesManager: PreferencesManager {
        PreferencesManager(modelContext: modelContext)
    }

    @State private var timesOfDay: [TimeOfDay] = []
    @Namespace private var animation

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer()

            Text("What's your preferred jogging time?")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
                .transition(.opacity.combined(with: .move(edge: .top)))

            Text("Select all that apply.")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .transition(.opacity.combined(with: .move(edge: .top)))

            // Time selection
            HStack(spacing: 10) {
                ForEach(TimeOfDay.allCases) { time in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            toggleSelection(for: time)
                        }
                    }) {
                        Text(time.rawValue)
                            .font(.system(size: 13))
                            .padding(.horizontal, 15)
                            .padding(.vertical, 10)
                            .background(
                                timesOfDay.contains(time)
                                ? Color.primary
                                : Color.clear
                            )
                            .foregroundColor(
                                timesOfDay.contains(time)
                                ? (colorScheme == .dark ? Color.black : Color.white)
                                : Color.primary
                            )
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(Color.primary, lineWidth: 1)
                            )
                            .matchedGeometryEffect(id: time.rawValue, in: animation)
                    }
                    .animation(.easeInOut, value: timesOfDay)
                }
            }
            .padding(.top, 10)

            Spacer()

            // Bottom buttons
            HStack {
                NavigationLink(destination: OnboardPreferredJogDays()) {
                    Text("Skip")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(width: 100, height: 45)
                }

                Spacer()

                if !timesOfDay.isEmpty {
                    NavigationLink(destination: OnboardPreferredJogDays()) {
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
                    .simultaneousGesture(TapGesture().onEnded {
                        preferencesManager.setTimesOfDay(timesOfDay: timesOfDay)
                    })
                    .transition(.scale)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: timesOfDay)
            
            // Progress Bar - Moved to bottom
            ProgressView(value: 0.6, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle())
                .tint(.primary)
                .frame(height: 6)
                .padding(.top, 20)
                .padding(.bottom, 20)
        }
        .padding(30)
        .navigationBarBackButtonHidden(true)
    }

    private func toggleSelection(for time: TimeOfDay) {
        if timesOfDay.contains(time) {
            timesOfDay.removeAll { $0 == time }
        } else {
            timesOfDay.append(time)
        }
    }
}

#Preview {
    NavigationStack {
        OnboardPreferredJogTime()
    }
}
