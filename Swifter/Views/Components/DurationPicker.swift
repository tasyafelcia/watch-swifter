//
//  DurationPicker.swift
//  Swifter
//
//  Created by Adeline Charlotte Augustinne on 27/03/25.
//

import Foundation
import SwiftUI

struct DurationPicker: View {
    @State var pickerLabel: String
    @Binding var startTime: Date
    @Binding var endTime: Date
    
    var body: some View {
        HStack {
            Text(pickerLabel)
                .fontWeight(.semibold)
            Spacer()
            HStack {
                DatePicker("From",
                           selection: $startTime,
                           displayedComponents: .hourAndMinute)
                .labelsHidden()
                                
                Text("-")
                                
                DatePicker("To", selection: $endTime, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
            }
        }
    }
}

#Preview {
    DurationPicker(pickerLabel: "Post-jog", startTime: .constant(Date()), endTime: .constant(Date()))
}
