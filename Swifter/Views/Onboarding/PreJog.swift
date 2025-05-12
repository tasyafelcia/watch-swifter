//
//  OnboardPreJogTime.swift
//  SwifterSwiftUi
//
//  Created by Natasya Felicia on 26/03/25.
//

import SwiftUI
import SwiftData

struct OnboardPreJogTime: View {
    @Environment(\.modelContext) private var modelContext
    private var preferencesManager: PreferencesManager {
        PreferencesManager(modelContext: modelContext)
    }

    @State private var preJogDuration: Int = 10

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer()

            // Title
            Text("How much time do you need to prepare before a jog?")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)

            // Custom Stepper
            HStack {
                // Minus Button
                Button(action: {
                    withAnimation {
                        preJogDuration = max(0, preJogDuration - 5)
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundColor(preJogDuration == 0 ? .gray : .primary)
                        .scaleEffect(preJogDuration == 0 ? 1.0 : 1.1)
                        .animation(.easeInOut(duration: 0.2), value: preJogDuration)
                }
                .disabled(preJogDuration == 0)

                Spacer()

                // Jogging Minutes Display (with animation)
                Text("\(preJogDuration) min")
                    .font(.system(size: 24, weight: .bold))
                    .frame(minWidth: 100)
                    .multilineTextAlignment(.center)
                    .scaleEffect(1.1)
                    .transition(.opacity)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: preJogDuration)

                Spacer()

                // Plus Button
                Button(action: {
                    withAnimation {
                        preJogDuration = min(120, preJogDuration + 5)
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.primary)
                        .scaleEffect(1.1)
                        .animation(.easeInOut(duration: 0.2), value: preJogDuration)
                }
            }
            .padding(.top, 10)

            // Next & Skip Button Row
            HStack {
                // Skip Button
                NavigationLink(destination: OnboardPostJogTime()) {
                    Text("Skip")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(width: 100, height: 45)
                }

                Spacer()

                // Next Button
                NavigationLink(destination: OnboardPostJogTime()) {
                    Text("Next")
                        .font(.system(size: 14))
                        .foregroundColor(preJogDuration > 0 ? .primary : .secondary)
                        .padding()
                        .frame(width: 150, height: 45)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(preJogDuration > 0 ? Color.primary : Color.secondary, lineWidth: 1)
                        )
                }
                .disabled(preJogDuration == 0)
                .simultaneousGesture(TapGesture().onEnded {
                    preferencesManager.setPrejogTime(prejogTime: preJogDuration)
                })
            }
            .padding(.top, 150)
            .padding(.bottom, 100)

            // Progress Bar
            ProgressView(value: 0.2, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle())
                .tint(.primary)
                .frame(height: 4)
                .padding(.top, 10)
        }
        .padding(30)
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    NavigationStack {
        OnboardPreJogTime()
    }
}
