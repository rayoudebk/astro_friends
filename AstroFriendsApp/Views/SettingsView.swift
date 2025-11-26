import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var contacts: [Contact]
    @Query private var checkIns: [CheckIn]
    
    @State private var showingExportSuccess = false
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        Form {
            Section("About") {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.indigo)
                    Text("Astro Friends")
                    Spacer()
                    Text("1.0")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.indigo)
                    Text("Total Contacts")
                    Spacer()
                    Text("\(contacts.count)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.indigo)
                    Text("Total Check-ins")
                    Spacer()
                    Text("\(checkIns.count)")
                        .foregroundColor(.secondary)
                }
            }
            
            Section("Zodiac Stats") {
                ForEach(ZodiacSign.allCases, id: \.self) { sign in
                    let count = contacts.filter { $0.zodiacSign == sign }.count
                    if count > 0 {
                        HStack {
                            Text(sign.emoji)
                            Text(sign.rawValue)
                            Spacer()
                            Text("\(count)")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Section("Data") {
                Button {
                    exportData()
                } label: {
                    Label("Export Data", systemImage: "square.and.arrow.up")
                }
                
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Label("Delete All Data", systemImage: "trash")
                }
            }
            
            Section("Support") {
                Link(destination: URL(string: "https://github.com")!) {
                    Label("GitHub", systemImage: "link")
                }
                
                Link(destination: URL(string: "mailto:support@astrofriends.app")!) {
                    Label("Contact Support", systemImage: "envelope")
                }
            }
        }
        .navigationTitle("Settings")
        .alert("Export Successful", isPresented: $showingExportSuccess) {
            Button("OK") {}
        } message: {
            Text("Your data has been exported.")
        }
        .alert("Delete All Data?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteAllData()
            }
        } message: {
            Text("This will permanently delete all contacts and check-ins. This cannot be undone.")
        }
    }
    
    private func exportData() {
        // Create export data structure
        var exportDict: [[String: Any]] = []
        
        for contact in contacts {
            var contactDict: [String: Any] = [
                "name": contact.name,
                "zodiacSign": contact.zodiacSign.rawValue,
                "frequencyDays": contact.frequencyDays,
                "isFavorite": contact.isFavorite,
                "notes": contact.notes
            ]
            
            if let phone = contact.phoneNumber {
                contactDict["phoneNumber"] = phone
            }
            
            if let email = contact.email {
                contactDict["email"] = email
            }
            
            if let birthday = contact.birthday {
                contactDict["birthday"] = ISO8601DateFormatter().string(from: birthday)
            }
            
            if let lastCheckIn = contact.lastCheckInDate {
                contactDict["lastCheckIn"] = ISO8601DateFormatter().string(from: lastCheckIn)
            }
            
            exportDict.append(contactDict)
        }
        
        // Convert to JSON
        if let jsonData = try? JSONSerialization.data(withJSONObject: exportDict, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            // Copy to clipboard
            UIPasteboard.general.string = jsonString
            showingExportSuccess = true
        }
    }
    
    private func deleteAllData() {
        for contact in contacts {
            modelContext.delete(contact)
        }
        
        for checkIn in checkIns {
            modelContext.delete(checkIn)
        }
    }
}


