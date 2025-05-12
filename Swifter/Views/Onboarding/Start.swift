//
//  OnboardStart.swift
//  SwifterSwiftUi
//
//  Created by Natasya Felicia on 26/03/25.
//

import SwiftUI

struct OnboardStart: View {
    @State private var animateText = false
    @State private var animateButton = false
    
    @State var showOnboarding: Bool = true

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Spacer()
                
                // Welcome Title
                Text("Welcome To Swifter")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.primary)
                    .opacity(animateText ? 1 : 0)
                    .offset(y: animateText ? 0 : 20)
                    .animation(.easeOut(duration: 0.8), value: animateText)

                // Subtitle
                Text("Let's personalize your jogging experience!")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
                    .opacity(animateText ? 1 : 0)
                    .offset(y: animateText ? 0 : 20)
                    .animation(.easeOut(duration: 1.0).delay(0.2), value: animateText)

                // Start Button
                NavigationLink(destination: OnboardTimeOnFeet()) {
                    Text("Start Onboarding")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .padding()
                        .frame(width: 180, height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color.primary, lineWidth: 1)
                        )
                        .scaleEffect(animateButton ? 1.05 : 1.0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.5), value: animateButton)
                }
                .padding(.top, 20)
                .onAppear {
                    animateButton = true
                }

                Spacer()
            }
            .padding(30)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color(.systemBackground).ignoresSafeArea())
            .onAppear {
                animateText = true
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    OnboardStart()
}
