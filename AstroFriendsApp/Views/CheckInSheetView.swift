import SwiftUI
import SwiftData

struct CheckInSheetView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var contact: Contact
    
    @State private var checkInType: CheckInType = .general
    @State private var notes: String = ""
    @State private var checkInDate: Date = Date()
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        if let imageData = contact.profileImageData,
                           let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                        } else {
                            ZStack {
                                Circle()
                                    .fill(Color.indigo.opacity(0.2))
                                    .frame(width: 50, height: 50)
                                Text(contact.name.prefix(1).uppercased())
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.indigo)
                            }
                        }
                        
                        VStack(alignment: .leading) {
                            Text(contact.name)
                                .font(.headline)
                            
                            HStack {
                                Text(contact.zodiacSign.emoji)
                                Text(contact.zodiacSign.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section("Check-in Type") {
                    Picker("Type", selection: $checkInType) {
                        ForEach(CheckInType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
                
                Section("When") {
                    DatePicker("Date", selection: $checkInDate, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Record Check-in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveCheckIn()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func saveCheckIn() {
        let checkIn = CheckIn(
            date: checkInDate,
            type: checkInType,
            notes: notes
        )
        checkIn.contact = contact
        contact.lastCheckInDate = checkInDate
        
        modelContext.insert(checkIn)
    }
}

// Record check-in sheet for selecting from all contacts
struct RecordCheckInSheetView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let contacts: [Contact]
    
    @State private var selectedContact: Contact?
    @State private var checkInType: CheckInType = .general
    @State private var notes: String = ""
    @State private var checkInDate: Date = Date()
    @State private var searchText: String = ""
    
    var filteredContacts: [Contact] {
        if searchText.isEmpty {
            return contacts
        }
        return contacts.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationStack {
            if selectedContact == nil {
                // Contact selection
                VStack(spacing: 0) {
                    SearchBar(text: $searchText)
                        .padding()
                    
                    List(filteredContacts) { contact in
                        Button {
                            selectedContact = contact
                        } label: {
                            HStack {
                                if let imageData = contact.profileImageData,
                                   let uiImage = UIImage(data: imageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 40, height: 40)
                                        .clipShape(Circle())
                                } else {
                                    ZStack {
                                        Circle()
                                            .fill(Color.indigo.opacity(0.2))
                                            .frame(width: 40, height: 40)
                                        Text(contact.name.prefix(1).uppercased())
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.indigo)
                                    }
                                }
                                
                                VStack(alignment: .leading) {
                                    Text(contact.name)
                                        .foregroundColor(.primary)
                                    
                                    HStack {
                                        Text(contact.zodiacSign.emoji)
                                        Text(contact.zodiacSign.rawValue)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
                .navigationTitle("Select Contact")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            } else if let contact = selectedContact {
                // Check-in form
                Form {
                    Section {
                        HStack {
                            if let imageData = contact.profileImageData,
                               let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                            } else {
                                ZStack {
                                    Circle()
                                        .fill(Color.indigo.opacity(0.2))
                                        .frame(width: 50, height: 50)
                                    Text(contact.name.prefix(1).uppercased())
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.indigo)
                                }
                            }
                            
                            VStack(alignment: .leading) {
                                Text(contact.name)
                                    .font(.headline)
                                
                                HStack {
                                    Text(contact.zodiacSign.emoji)
                                    Text(contact.zodiacSign.rawValue)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Button {
                                selectedContact = nil
                            } label: {
                                Text("Change")
                                    .font(.caption)
                                    .foregroundColor(.indigo)
                            }
                        }
                    }
                    
                    Section("Check-in Type") {
                        Picker("Type", selection: $checkInType) {
                            ForEach(CheckInType.allCases, id: \.self) { type in
                                Label(type.rawValue, systemImage: type.icon)
                                    .tag(type)
                            }
                        }
                        .pickerStyle(.inline)
                        .labelsHidden()
                    }
                    
                    Section("When") {
                        DatePicker("Date", selection: $checkInDate, displayedComponents: [.date, .hourAndMinute])
                    }
                    
                    Section("Notes") {
                        TextEditor(text: $notes)
                            .frame(minHeight: 100)
                    }
                }
                .navigationTitle("Record Check-in")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            saveCheckIn(for: contact)
                            dismiss()
                        }
                    }
                }
            }
        }
    }
    
    private func saveCheckIn(for contact: Contact) {
        let checkIn = CheckIn(
            date: checkInDate,
            type: checkInType,
            notes: notes
        )
        checkIn.contact = contact
        contact.lastCheckInDate = checkInDate
        
        modelContext.insert(checkIn)
    }
}

