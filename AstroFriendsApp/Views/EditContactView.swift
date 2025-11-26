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
    @State private var isFavorite: Bool = false
    @State private var birthday: Date = Date()
    @State private var hasBirthday: Bool = false
    
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
                
                Section("Birthday") {
                    Toggle("Has Birthday", isOn: $hasBirthday)
                    
                    if hasBirthday {
                        DatePicker("Birthday", selection: $birthday, displayedComponents: .date)
                            .onChange(of: birthday) { _, newDate in
                                zodiacSign = ZodiacSign.from(birthday: newDate)
                            }
                    }
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
        isFavorite = contact.isFavorite
        if let bday = contact.birthday {
            birthday = bday
            hasBirthday = true
        }
    }
    
    private func saveChanges() {
        contact.name = name
        contact.phoneNumber = phoneNumber.isEmpty ? nil : phoneNumber
        contact.email = email.isEmpty ? nil : email
        contact.notes = notes
        contact.zodiacSign = zodiacSign
        contact.isFavorite = isFavorite
        contact.birthday = hasBirthday ? birthday : nil
    }
}
