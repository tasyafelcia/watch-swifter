//
//  OnboardPostJogTime.swift
//  SwifterSwiftUi
//
//  Created by Natasya Felicia on 26/03/25.
//

import SwiftUI
import SwiftData

struct OnboardPostJogTime: View {
    @Environment(\.modelContext) private var modelContext
    private var preferencesManager: PreferencesManager {
        PreferencesManager(modelContext: modelContext)
    }
    
    @State private var postJogDuration: Int = 10  // Default value

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer()
            
            // Title
            Text("How long do you usually cool down after jogging?")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
                .navigationBarBackButtonHidden(true)

            // Custom Stepper
            HStack {
                // Minus Button
                Button(action: {
                    withAnimation {
                        if postJogDuration > 0 {
                            postJogDuration -= 5
                        }
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundColor(postJogDuration == 0 ? .gray : .primary)
                        .scaleEffect(postJogDuration == 0 ? 1.0 : 1.1)
                        .animation(.easeInOut(duration: 0.2), value: postJogDuration)
                }
                .disabled(postJogDuration == 0)

                Spacer()

                // Animated Number
                Text("\(postJogDuration) min")
                    .font(.system(size: 24, weight: .bold))
                    .frame(minWidth: 100)
                    .multilineTextAlignment(.center)
                    .scaleEffect(1.1)
                    .transition(.opacity)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: postJogDuration)

                Spacer()

                // Plus Button
                Button(action: {
                    withAnimation {
                        if postJogDuration < 120 {
                            postJogDuration += 5
                        }
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.primary)
                        .scaleEffect(1.1)
                        .animation(.easeInOut(duration: 0.2), value: postJogDuration)
                }
            }
            .padding(.top, 10)

            // Navigation Buttons
            HStack {
                NavigationLink(destination: OnboardPreferredJogTime()) {
                    Text("Skip")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(width: 100, height: 45)
                }
                
                Spacer()

                NavigationLink(destination: OnboardPreferredJogTime()) {
                    Text("Next")
                        .font(.system(size: 14))
                        .foregroundColor(postJogDuration > 0 ? .primary : .secondary)
                        .padding()
                        .frame(width: 150, height: 45)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(postJogDuration > 0 ? Color.primary : Color.secondary, lineWidth: 1)
                        )
                }
                .disabled(postJogDuration == 0)
                .simultaneousGesture(TapGesture().onEnded {
                    preferencesManager.setPostjogTime(postjogTime: postJogDuration)
                })
            }
            .padding(.top, 150)
            .padding(.bottom, 100)

            // Progress Bar
            ProgressView(value: 0.4, total: 1.0)
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
        OnboardPostJogTime()
    }
}
