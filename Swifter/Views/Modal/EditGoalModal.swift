import SwiftUI
import SwiftData

struct GoalSettingModal: View {
    // modal
    @Binding var isPresented: Bool
    @StateObject private var viewModel: EditGoalViewModel
    let goalToEdit: GoalModel
    let onPreSave: () -> Void
    let onPostSave: () -> Void
    
    @Environment(\.modelContext) private var modelContext
    private var goalManager: GoalManager {
        GoalManager(modelContext: modelContext)
    }
    
    @State private var showSaveAlert = false
    @State private var showingFrequencyPicker = false
    
    init(isPresented: Binding<Bool>, goalToEdit: GoalModel, onPreSave: @escaping () -> Void, onPostSave: @escaping () -> Void) {
        self._isPresented = isPresented
        self.goalToEdit = goalToEdit
        _viewModel = StateObject(wrappedValue: EditGoalViewModel())
        self.onPreSave = onPreSave
        self.onPostSave = onPostSave
    }
    
    var body: some View {
        VStack {
            ZStack{
                Rectangle().fill(.ultraThinMaterial)
                    .ignoresSafeArea()
                VStack {
                    Spacer()
                    VStack(alignment: .leading, spacing: 25) {
                        HStack {
                            Text("Edit Your Weekly Goal")
                                .font(.system(size: 20, weight: .bold))
                            Spacer()
                            Button("Save") {
                                showSaveAlert = true
                            }
                            .font(.title3)
                        }
                        
                        VStack(alignment: .leading, spacing: 25) {
                            // Frequency Picker
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Target Jog Frequency")
                                    .font(.system(size: 18, weight: .medium))
                                
                                FrequencyPickerButton(
                                    value: $viewModel.targetFrequency,
                                    isShowingPicker: $showingFrequencyPicker
                                )
                            }
                            
                            HStack {
                                Text("Start Date")
                                    .font(.system(size: 18, weight: .medium))
                                    .frame(width: 155, alignment: .leading)
                                
                                Spacer()
                                
                                DatePicker("", selection: $viewModel.startDate, displayedComponents: .date)
                                    .datePickerStyle(CompactDatePickerStyle())
                                    .labelsHidden()
                                    .frame(width: 200, height: 30)
                                    .scaleEffect(0.9)
                            }
                            
                            HStack {
                                Text("End Date")
                                    .font(.system(size: 18, weight: .medium))
                                    .frame(width: 155, alignment: .leading)
                                
                                Spacer()
                                
                                DatePicker("", selection: $viewModel.endDate, displayedComponents: .date)
                                    .datePickerStyle(CompactDatePickerStyle())
                                    .labelsHidden()
                                    .frame(width: 200, height: 30)
                                    .scaleEffect(0.9)
                            }
                        }
                    }
                    .padding(20)
                    .background(Color(UIColor.systemBackground))
                    .frame(maxWidth: 800)
                    .alert(isPresented: $showSaveAlert) {
                        Alert(
                            title: Text("Update your current goal?"),
                            message: Text("⚠️ Your current goal progress will be reset!"),
                            primaryButton: .default(Text("Save")) {
                                onPreSave()
                                viewModel.saveGoal(goalManager: goalManager, goalToEdit: goalToEdit)
                                onPostSave()
                                isPresented = false
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
                .transition(.move(edge: .bottom))
            }
            .onAppear {
                viewModel.fetchData(prevGoal: goalToEdit)
            }
        }
    }
}

// MARK: - Frequency Picker Components

struct FrequencyPickerButton: View {
    @Binding var value: Int
    @Binding var isShowingPicker: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation {
                    isShowingPicker.toggle()
                }
            }) {
                HStack {
                    Text("\(value) times / week")
                        .font(.system(size: 16, weight: .medium))
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                    
                    Spacer()
                    
                    Image(systemName: isShowingPicker ? "chevron.up" : "chevron.down")
                        .foregroundColor(.primary)
                        .font(.system(size: 14, weight: .medium))
                        .frame(width: 30)
                        .padding(.trailing, 8)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            if isShowingPicker {
                FrequencyPickerView(value: $value)
                    .padding(.top, 8)
                    .transition(.opacity)
            }
        }
    }
}

struct FrequencyPickerView: View {
    @Binding var value: Int
    private let minValue = 1
    private let maxValue = 7
    
    var body: some View {
        VStack(spacing: 12) {
            // Slider for frequency
            HStack {
                Text("\(minValue)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Slider(
                    value: Binding(
                        get: { Double(value - minValue) },
                        set: { newValue in
                            value = Int(newValue) + minValue
                        }
                    ),
                    in: 0...Double(maxValue - minValue),
                    step: 1
                )
                .accentColor(.accentColor)
                
                Text("\(maxValue)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Days of the week selection
            HStack(spacing: 12) {
                ForEach(minValue...maxValue, id: \.self) { day in
                    Button(action: {
                        value = day
                    }) {
                        ZStack {
                            Circle()
                                .fill(value == day ? Color.accentColor : Color(UIColor.tertiarySystemBackground))
                                .frame(width: 40, height: 40)
                            
                            Text("\(day)")
                                .font(.system(size: 16, weight: value == day ? .bold : .medium))
                                .foregroundColor(value == day ? .white : .primary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // Selected value description
            Text("\(value) \(value == 1 ? "day" : "days") per week")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 4)
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
}

// MARK: - Preview without SwiftData

struct GoalSettingModal_Preview: PreviewProvider {
    struct PreviewGoalSettingModal: View {
        @Binding var isPresented: Bool
        @State private var targetFrequency: Int = 3
        @State private var startDate: Date = Date().addingTimeInterval(-7*24*60*60)
        @State private var endDate: Date = Date().addingTimeInterval(30*24*60*60)
        @State private var showSaveAlert = false
        @State private var showingFrequencyPicker = false
        
        var body: some View {
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
                    .onTapGesture {
                        isPresented = false
                    }
                
                VStack {
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 25) {
                        HStack {
                            Text("Edit Your Weekly Goal")
                                .font(.system(size: 20, weight: .bold))
                            Spacer()
                            Button("Save") {
                                showSaveAlert = true
                            }
                            .font(.title3)
                        }
                        
                        VStack(alignment: .leading, spacing: 25) {
                            // Frequency Picker
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Target Jog Frequency")
                                    .font(.system(size: 18, weight: .medium))
                                
                                FrequencyPickerButton(
                                    value: $targetFrequency,
                                    isShowingPicker: $showingFrequencyPicker
                                )
                            }
                            
                            HStack {
                                Text("Start Date")
                                    .font(.system(size: 18, weight: .medium))
                                    .frame(width: 155, alignment: .leading)
                                
                                Spacer()
                                
                                DatePicker("", selection: $startDate, displayedComponents: .date)
                                    .datePickerStyle(CompactDatePickerStyle())
                                    .labelsHidden()
                                    .frame(width: 200, height: 30)
                                    .scaleEffect(0.9)
                            }
                            
                            HStack {
                                Text("End Date")
                                    .font(.system(size: 18, weight: .medium))
                                    .frame(width: 155, alignment: .leading)
                                
                                Spacer()
                                
                                DatePicker("", selection: $endDate, displayedComponents: .date)
                                    .datePickerStyle(CompactDatePickerStyle())
                                    .labelsHidden()
                                    .frame(width: 200, height: 30)
                                    .scaleEffect(0.9)
                            }
                        }
                    }
                    .padding(20)
                    .background(Color(UIColor.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(radius: 10)
                    .padding(.horizontal, 20)
                    .frame(maxWidth: 800)
                    .alert(isPresented: $showSaveAlert) {
                        Alert(
                            title: Text("Save Goal"),
                            message: Text("Are you sure you want to save your weekly goal?"),
                            primaryButton: .default(Text("Save")) {
                                isPresented = false
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
                .transition(.move(edge: .bottom))
            }
        }
    }
    
    static var previews: some View {
        PreviewGoalSettingModal(isPresented: .constant(true))
    }
}
