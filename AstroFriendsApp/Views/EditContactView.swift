import SwiftUI
import SwiftData

struct EditContactView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var contact: Contact
    
    @State private var name: String = ""
    @State private var phoneNumber: String = ""
    @State private var email: String = ""
    @State private var notes: String = ""
    @State private var zodiacSign: ZodiacSign = .aries
    @State private var frequencyDays: Int = 30
    @State private var isFavorite: Bool = false
    
    // Birth data for natal chart
    @State private var hasBirthday: Bool = false
    @State private var birthday: Date = Date()
    @State private var hasBirthTime: Bool = false
    @State private var birthTime: Date = Date()
    @State private var birthPlace: String = ""
    
    let frequencyOptions = [7, 14, 30, 60, 90, 180, 365]
    
    // Computed natal chart preview (safer than inline)
    private var previewChart: NatalChart? {
        guard hasBirthday else { return nil }
        return NatalChart(
            birthDate: birthday,
            birthTime: hasBirthTime ? birthTime : nil,
            birthPlace: birthPlace.isEmpty ? nil : birthPlace
        )
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Name", text: $name)
                    TextField("Phone", text: $phoneNumber)
                        .keyboardType(.phonePad)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                
                // Birth Data Section
                Section {
                    Toggle("Birthday Known", isOn: $hasBirthday)
                    
                    if hasBirthday {
                        DatePicker("Birthday", selection: $birthday, displayedComponents: .date)
                            .onChange(of: birthday) { _, newDate in
                                zodiacSign = ZodiacSign.from(birthday: newDate)
                            }
                    }
                    
                    Toggle("Birth Time Known", isOn: $hasBirthTime)
                    
                    if hasBirthTime {
                        DatePicker("Birth Time", selection: $birthTime, displayedComponents: .hourAndMinute)
                    }
                    
                    TextField("Birth Place (City, Country)", text: $birthPlace)
                } header: {
                    Text("Birth Data")
                } footer: {
                    Text("Add birth time and place for more accurate Moon and Rising sign calculations in compatibility readings.")
                        .font(.caption)
                }
                
                // Natal Chart Preview
                if let chart = previewChart {
                    Section("Natal Chart") {
                        HStack {
                            Label("Sun", systemImage: "sun.max.fill")
                                .foregroundColor(.orange)
                            Spacer()
                            Text("\(chart.sunSign.emoji) \(chart.sunSign.rawValue)")
                        }
                        
                        HStack {
                            Label("Moon", systemImage: "moon.fill")
                                .foregroundColor(.indigo)
                            Spacer()
                            Text("\(chart.moonSign.emoji) \(chart.moonSign.rawValue)")
                            if !hasBirthTime {
                                Text("(approx)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if let rising = chart.risingSign {
                            HStack {
                                Label("Rising", systemImage: "arrow.up.circle.fill")
                                    .foregroundColor(.purple)
                                Spacer()
                                Text("\(rising.emoji) \(rising.rawValue)")
                            }
                        } else {
                            HStack {
                                Label("Rising", systemImage: "arrow.up.circle")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("Add birth time")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Chart completeness indicator
                        HStack {
                            Text(chart.chartCompleteness.emoji)
                            Text(chart.chartCompleteness.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("Zodiac Sign (Sun)") {
                    Picker("Sign", selection: $zodiacSign) {
                        ForEach(ZodiacSign.allCases, id: \.self) { sign in
                            HStack {
                                Text(sign.emoji)
                                Text(sign.rawValue)
                            }
                            .tag(sign)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 150)
                    
                    HStack {
                        Text("Element")
                        Spacer()
                        Text(zodiacSign.element)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Date Range")
                        Spacer()
                        Text(zodiacSign.dateRange)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Check-in Frequency") {
                    Picker("Frequency", selection: $frequencyDays) {
                        Text("Weekly").tag(7)
                        Text("Every 2 Weeks").tag(14)
                        Text("Monthly").tag(30)
                        Text("Every 2 Months").tag(60)
                        Text("Quarterly").tag(90)
                        Text("Every 6 Months").tag(180)
                        Text("Yearly").tag(365)
                    }
                }
                
                Section {
                    Toggle("Favorite", isOn: $isFavorite)
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Edit Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                loadContactData()
            }
        }
    }
    
    private func loadContactData() {
        name = contact.name
        phoneNumber = contact.phoneNumber ?? ""
        email = contact.email ?? ""
        notes = contact.notes
        zodiacSign = contact.zodiacSign
        frequencyDays = contact.frequencyDays
        isFavorite = contact.isFavorite
        
        // Load birth data
        if let bday = contact.birthday {
            hasBirthday = true
            birthday = bday
        }
        if let btime = contact.birthTime {
            hasBirthTime = true
            birthTime = btime
        }
        birthPlace = contact.birthPlace ?? ""
    }
    
    private func saveChanges() {
        contact.name = name
        contact.phoneNumber = phoneNumber.isEmpty ? nil : phoneNumber
        contact.email = email.isEmpty ? nil : email
        contact.notes = notes
        contact.zodiacSign = zodiacSign
        contact.frequencyDays = frequencyDays
        contact.isFavorite = isFavorite
        
        // Save birth data
        contact.birthday = hasBirthday ? birthday : nil
        contact.birthTime = hasBirthTime ? birthTime : nil
        contact.birthPlace = birthPlace.isEmpty ? nil : birthPlace
    }
}

