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
    
    let frequencyOptions = [7, 14, 30, 60, 90, 180, 365]
    
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
                
                Section("Zodiac Sign") {
                    Picker("Sign", selection: $zodiacSign) {
                        ForEach(ZodiacSign.allCases, id: \.self) { sign in
                            HStack {
                                Text(sign.emoji)
                                Text(sign.rawValue)
                            }
                            .tag(sign)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    
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
    }
    
    private func saveChanges() {
        contact.name = name
        contact.phoneNumber = phoneNumber.isEmpty ? nil : phoneNumber
        contact.email = email.isEmpty ? nil : email
        contact.notes = notes
        contact.zodiacSign = zodiacSign
        contact.frequencyDays = frequencyDays
        contact.isFavorite = isFavorite
    }
}

