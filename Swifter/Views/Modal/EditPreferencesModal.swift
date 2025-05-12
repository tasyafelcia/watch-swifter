import SwiftUI
import SwiftData

struct EditPreferencesModal: View {
    @Binding var isPresented: Bool

    var modelContext: ModelContext
    @Query private var preferences: [PreferencesModel]

    @State private var selectedTimesOfDay: Set<TimeOfDay> = []
    @State private var selectedDaysOfWeek: Set<DayOfWeek> = []
    @State private var avgTimeOnFeet: Int = 30
    @State private var preJogDuration: Int = 5
    @State private var postJogDuration: Int = 5
    
    // States for time picker visibility
    @State private var showingAvgTimeOnFeetPicker = false
    @State private var showingPreJogDurationPicker = false
    @State private var showingPostJogDurationPicker = false

    @State private var showSaveAlert = false

    private let columns = Array(repeating: GridItem(.flexible()), count: 4)

    private var currentPreference: PreferencesModel? {
        preferences.first
    }

    var onSave: () -> Void

    init(isPresented: Binding<Bool>, modelContext: ModelContext, onSave: @escaping () -> Void) {
        self._isPresented = isPresented
        self.modelContext = modelContext
        self.onSave = onSave
    }

    var body: some View {
            VStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header
                        HStack {
                            Button(action: { isPresented = false }) {
                                Image(systemName: "chevron.left")
                                    .font(.title2)
                                    .foregroundColor(.primary)
                            }
                            Spacer()
                            Text("Edit Preferences")
                                .font(.headline)
                            Spacer()
                        }

                        VStack(alignment: .leading, spacing: 20) {
                            // Avg Time On Feet Section
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Avg Time On Feet (Required)")
                                    .font(.subheadline)
                                    .bold()
                                
                                // Modern time picker design
                                TimePickerButton(
                                    value: $avgTimeOnFeet,
                                    isShowingPicker: $showingAvgTimeOnFeetPicker,
                                    minValue: 5,
                                    maxValue: 120,
                                    step: 5,
                                    unit: "minutes",
                                    onValueChange: updatePreference
                                )
                            }

                            // Avg Pre Jog Duration Section
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Avg Pre Jog Duration")
                                    .font(.subheadline)
                                    .bold()
                                
                                TimePickerButton(
                                    value: $preJogDuration,
                                    isShowingPicker: $showingPreJogDurationPicker,
                                    minValue: 0,
                                    maxValue: 60,
                                    step: 5,
                                    unit: "minutes",
                                    onValueChange: updatePreference
                                )
                            }

                            // Avg Post Jog Duration Section
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Avg Post Jog Duration")
                                    .font(.subheadline)
                                    .bold()
                                
                                TimePickerButton(
                                    value: $postJogDuration,
                                    isShowingPicker: $showingPostJogDurationPicker,
                                    minValue: 0,
                                    maxValue: 60,
                                    step: 5,
                                    unit: "minutes",
                                    onValueChange: updatePreference
                                )
                            }
                            
                            // Times of Day Section
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Preferred Times of Day")
                                    .font(.subheadline)
                                    .bold()

                                LazyVGrid(columns: columns, spacing: 8) {
                                    ForEach(TimeOfDay.allCases) { time in
                                        TimeButton(
                                            title: time.rawValue,
                                            isSelected: selectedTimesOfDay.contains(time),
                                            action: { toggleTimeOfDay(time) }
                                        )
                                    }
                                }
                                .padding(.bottom, 5)
                            }
                            
                            // Days of Week Section
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Preferred Days of the Week")
                                    .font(.subheadline)
                                    .bold()

                                LazyVGrid(columns: columns, spacing: 8) {
                                    ForEach(DayOfWeek.allCases) { day in
                                        DayButton(
                                            title: day.name.prefix(3),
                                            isSelected: selectedDaysOfWeek.contains(day),
                                            action: { toggleDayOfWeek(day) }
                                        )
                                    }
                                }
                                .padding(.bottom, 5)
                            }
                        }

                        Button(action: {
                            showSaveAlert = true
                        }) {
                            Text("Save")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.top, 10)
                        .alert(isPresented: $showSaveAlert) {
                            Alert(
                                title: Text("Save Changes?"),
                                message: Text("Are you sure you want to save your preferences?"),
                                primaryButton: .default(Text("OK")) {
                                    updatePreference()
                                    onSave()
                                    isPresented = false
                                },
                                secondaryButton: .cancel()
                            )
                        }
                    }
                    .padding(20)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                .padding(.horizontal, 20)
                .frame(maxHeight: UIScreen.main.bounds.height * 0.75)
            }
            .frame(maxWidth: 700)
            .transition(.move(edge: .bottom))
            .onAppear {
                loadPreferenceData()
                if let prefs = currentPreference {
                    selectedTimesOfDay = Set(prefs.preferredTimesOfDay)
                    selectedDaysOfWeek = Set(prefs.preferredDaysOfWeek ?? [])
                    avgTimeOnFeet = prefs.jogDuration
                    preJogDuration = prefs.preJogDuration
                    postJogDuration = prefs.postJogDuration
                }
            }
    }

    private func loadPreferenceData() {
        guard let preference = currentPreference else { return }
        selectedTimesOfDay = Set(preference.preferredTimesOfDay)
        selectedDaysOfWeek = Set(preference.preferredDaysOfWeek ?? [])
        avgTimeOnFeet = preference.jogDuration
        preJogDuration = preference.preJogDuration
        postJogDuration = preference.postJogDuration
    }

    private func updatePreference() {
        guard let preference = currentPreference else { return }

        preference.preferredTimesOfDay = Array(selectedTimesOfDay)
        preference.preferredDaysOfWeek = Array(selectedDaysOfWeek)
        preference.jogDuration = avgTimeOnFeet
        preference.preJogDuration = preJogDuration
        preference.postJogDuration = postJogDuration

        do {
            try modelContext.save()
            print("✅ Preferences updated successfully")
        } catch {
            print("❌ Failed to save preferences: \(error)")
        }
    }

    private func toggleTimeOfDay(_ time: TimeOfDay) {
        if selectedTimesOfDay.contains(time) {
            selectedTimesOfDay.remove(time)
        } else {
            selectedTimesOfDay.insert(time)
        }
        updatePreference()
    }

    private func toggleDayOfWeek(_ day: DayOfWeek) {
        if selectedDaysOfWeek.contains(day) {
            selectedDaysOfWeek.remove(day)
        } else {
            selectedDaysOfWeek.insert(day)
        }
        updatePreference()
    }
}

// MARK: - Time Picker Components

struct TimePickerButton: View {
    @Binding var value: Int
    @Binding var isShowingPicker: Bool
    let minValue: Int
    let maxValue: Int
    let step: Int
    let unit: String
    let onValueChange: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation {
                    isShowingPicker.toggle()
                }
            }) {
                HStack {
                    Text("\(value) \(unit)")
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
                TimePickerView(
                    value: $value,
                    minValue: minValue,
                    maxValue: maxValue,
                    step: step,
                    unit: unit,
                    onValueChange: onValueChange
                )
                .padding(.top, 8)
                .transition(.opacity)
            }
        }
    }
}

struct TimePickerView: View {
    @Binding var value: Int
    let minValue: Int
    let maxValue: Int
    let step: Int
    let unit: String
    let onValueChange: () -> Void
    
    // Generate available values based on min, max and step
    private var availableValues: [Int] {
        stride(from: minValue, through: maxValue, by: step).map { $0 }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Slider
            HStack {
                Text("\(minValue)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Slider(
                    value: Binding(
                        get: {
                            Double(availableValues.firstIndex(of: value) ?? 0)
                        },
                        set: { newPosition in
                            if let newIndex = Int(exactly: newPosition),
                               newIndex >= 0 && newIndex < availableValues.count {
                                value = availableValues[newIndex]
                                onValueChange()
                            }
                        }
                    ),
                    in: 0...Double(availableValues.count - 1),
                    step: 1
                )
                .accentColor(.accentColor)
                
                Text("\(maxValue)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Value selection buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(availableValues, id: \.self) { timeValue in
                        Button(action: {
                            value = timeValue
                            onValueChange()
                        }) {
                            Text("\(timeValue)")
                                .font(.system(size: 15, weight: .medium))
                                .frame(width: 44, height: 44)
                                .background(value == timeValue ? Color.accentColor : Color(UIColor.tertiarySystemBackground))
                                .foregroundColor(value == timeValue ? .white : .primary)
                                .cornerRadius(22)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
}

// MARK: - Original Buttons (Unchanged)

struct TimeButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13))
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.primary : Color.clear)
                .foregroundColor(isSelected ? Color(UIColor.systemBackground) : Color.primary)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.primary, lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DayButton: View {
    let title: String.SubSequence
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13))
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.primary : Color.clear)
                .foregroundColor(isSelected ? Color(UIColor.systemBackground) : Color.primary)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.primary, lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    let container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        do {
            let container = try ModelContainer(for: PreferencesModel.self, configurations: config)
            let samplePreference = PreferencesModel(
                timeOnFeet: 15,
                preJogDuration: 15,
                postJogDuration: 10,
                timeOfDay: [.morning, .evening],
                dayOfWeek: [.monday, .wednesday, .friday]
            )
            container.mainContext.insert(samplePreference)
            return container
        } catch {
            fatalError("Failed to create model container: \(error)")
        }
    }()

    return EditPreferencesModal(isPresented: .constant(true), modelContext: container.mainContext, onSave: {})
}
