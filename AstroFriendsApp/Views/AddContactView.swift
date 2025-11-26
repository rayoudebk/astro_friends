import SwiftUI
import SwiftData
import Contacts
import ContactsUI
import Foundation

struct AddContactView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var existingContacts: [Contact]
    
    @State private var searchText = ""
    @State private var allContacts: [CNContact] = []
    @State private var selectedContactIds: Set<String> = []
    @State private var contactZodiacMap: [String: ZodiacSign] = [:]
    @State private var isLoadingContacts = false
    
    var availableContacts: [CNContact] {
        let existingIdentifiers = Set(existingContacts.compactMap { $0.contactIdentifier })
        return allContacts.filter { !existingIdentifiers.contains($0.identifier) }
    }
    
    var filteredContacts: [CNContact] {
        let available = availableContacts
        
        if searchText.isEmpty {
            return available
        }
        
        return available.filter { contact in
            let name = contactDisplayName(contact)
            return name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var suggestedContacts: [CNContact] {
        let scored = filteredContacts.map { contact in
            (contact: contact, score: calculateContactScore(contact))
        }
        .sorted { $0.score > $1.score }
        .filter { $0.score >= 20 }
        .prefix(100)
        .map { $0.contact }
        
        return Array(scored)
    }
    
    var otherContacts: [CNContact] {
        let suggestedIds = Set(suggestedContacts.map { $0.identifier })
        return filteredContacts.filter { !suggestedIds.contains($0.identifier) }
    }
    
    private func calculateContactScore(_ contact: CNContact) -> Int {
        var score = 0
        
        let hasFirstName = !contact.givenName.isEmpty
        let hasLastName = !contact.familyName.isEmpty
        let hasBothNames = hasFirstName && hasLastName
        let hasNickname = !contact.nickname.isEmpty
        let hasEmail = !contact.emailAddresses.isEmpty
        let hasOrganization = !contact.organizationName.isEmpty
        let hasBirthday = contact.birthday != nil
        let hasAddress = !contact.postalAddresses.isEmpty
        let phoneCount = contact.phoneNumbers.count
        let emailCount = contact.emailAddresses.count
        let totalWaysToReach = phoneCount + emailCount
        
        if hasFirstName { score += 10 }
        if hasLastName { score += 10 }
        if hasBothNames { score += 5 }
        if hasNickname { score += 3 }
        if hasEmail { score += 8 }
        if hasOrganization { score += 6 }
        if hasBirthday { score += 10 }
        if hasAddress { score += 3 }
        if totalWaysToReach >= 2 { score += 4 }
        
        if !hasFirstName && !hasLastName && !hasOrganization && !hasEmail && phoneCount == 1 {
            score -= 15
        }
        
        return score
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Instruction header
                VStack(spacing: 8) {
                    HStack {
                        Text("Select contacts to add")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(selectedContactIds.count) selected")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.horizontal)
                    
                    Text("Zodiac signs will be auto-detected from birthdays")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                }
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.05))
                
                // Search bar
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                
                // Contact list
                if isLoadingContacts {
                    VStack {
                        Spacer()
                        ProgressView("Loading contacts...")
                            .foregroundColor(.white)
                        Spacer()
                    }
                } else if filteredContacts.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.3))
                        Text("No contacts found")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Button("Reload Contacts") {
                            loadContacts()
                        }
                        .buttonStyle(.bordered)
                        Spacer()
                    }
                } else {
                    List {
                        if !suggestedContacts.isEmpty {
                            Section {
                                ForEach(suggestedContacts, id: \.identifier) { cnContact in
                                    ContactSelectionRow(
                                        cnContact: cnContact,
                                        isSelected: selectedContactIds.contains(cnContact.identifier),
                                        zodiacSign: contactZodiacMap[cnContact.identifier],
                                        onToggle: { isSelected in
                                            if isSelected {
                                                selectedContactIds.insert(cnContact.identifier)
                                                if let birthday = cnContact.birthday?.date {
                                                    contactZodiacMap[cnContact.identifier] = ZodiacSign.from(birthday: birthday)
                                                }
                                            } else {
                                                selectedContactIds.remove(cnContact.identifier)
                                                contactZodiacMap.removeValue(forKey: cnContact.identifier)
                                            }
                                        },
                                        onZodiacChange: { sign in
                                            contactZodiacMap[cnContact.identifier] = sign
                                        }
                                    )
                                }
                            } header: {
                                Text("Suggested")
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .listRowBackground(Color.white.opacity(0.05))
                        }
                        
                        if !otherContacts.isEmpty {
                            Section {
                                ForEach(otherContacts, id: \.identifier) { cnContact in
                                    ContactSelectionRow(
                                        cnContact: cnContact,
                                        isSelected: selectedContactIds.contains(cnContact.identifier),
                                        zodiacSign: contactZodiacMap[cnContact.identifier],
                                        onToggle: { isSelected in
                                            if isSelected {
                                                selectedContactIds.insert(cnContact.identifier)
                                                if let birthday = cnContact.birthday?.date {
                                                    contactZodiacMap[cnContact.identifier] = ZodiacSign.from(birthday: birthday)
                                                }
                                            } else {
                                                selectedContactIds.remove(cnContact.identifier)
                                                contactZodiacMap.removeValue(forKey: cnContact.identifier)
                                            }
                                        },
                                        onZodiacChange: { sign in
                                            contactZodiacMap[cnContact.identifier] = sign
                                        }
                                    )
                                }
                            } header: {
                                Text("All contacts")
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .listRowBackground(Color.white.opacity(0.05))
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(
                LinearGradient(
                    colors: [Color(red: 0.05, green: 0.05, blue: 0.12), Color(red: 0.08, green: 0.04, blue: 0.18)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Add Contacts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        importContacts()
                    }
                    .disabled(selectedContactIds.isEmpty)
                    .foregroundColor(selectedContactIds.isEmpty ? .white.opacity(0.3) : .purple)
                }
            }
            .onAppear {
                loadContacts()
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func loadContacts() {
        let store = CNContactStore()
        let authStatus = CNContactStore.authorizationStatus(for: .contacts)
        
        if authStatus == .authorized {
            isLoadingContacts = true
            loadContactsFromStore(store)
            return
        }
        
        if authStatus == .notDetermined {
            isLoadingContacts = true
            store.requestAccess(for: .contacts) { granted, error in
                guard granted else {
                    DispatchQueue.main.async {
                        self.isLoadingContacts = false
                    }
                    return
                }
                self.loadContactsFromStore(store)
            }
        } else {
            isLoadingContacts = false
        }
    }
    
    private func loadContactsFromStore(_ store: CNContactStore) {
        // Run contact enumeration on background thread to avoid UI blocking
        DispatchQueue.global(qos: .userInitiated).async {
            let keys = [
                CNContactGivenNameKey,
                CNContactFamilyNameKey,
                CNContactMiddleNameKey,
                CNContactNicknameKey,
                CNContactOrganizationNameKey,
                CNContactJobTitleKey,
                CNContactPhoneNumbersKey,
                CNContactEmailAddressesKey,
                CNContactBirthdayKey,
                CNContactPostalAddressesKey,
                CNContactImageDataKey,
                CNContactThumbnailImageDataKey
            ] as [CNKeyDescriptor]
            
            let request = CNContactFetchRequest(keysToFetch: keys)
            request.predicate = nil
            
            var contacts: [CNContact] = []
            
            do {
                try store.enumerateContacts(with: request) { contact, stop in
                    contacts.append(contact)
                }
                
                DispatchQueue.main.async {
                    self.allContacts = contacts.sorted { c1, c2 in
                        let name1 = self.contactDisplayName(c1)
                        let name2 = self.contactDisplayName(c2)
                        return name1 < name2
                    }
                    self.isLoadingContacts = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoadingContacts = false
                }
            }
        }
    }
    
    private func contactDisplayName(_ contact: CNContact) -> String {
        let fullName = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
        if !fullName.isEmpty {
            return fullName
        }
        if !contact.nickname.isEmpty {
            return contact.nickname
        }
        if !contact.organizationName.isEmpty {
            return contact.organizationName
        }
        return "Unknown"
    }
    
    private func importContacts() {
        var newContacts: [Contact] = []
        
        for identifier in selectedContactIds {
            guard let cnContact = allContacts.first(where: { $0.identifier == identifier }) else { continue }
            
            let name = "\(cnContact.givenName) \(cnContact.familyName)".trimmingCharacters(in: .whitespaces)
            let phoneNumber = cnContact.phoneNumbers.first?.value.stringValue
            let email = cnContact.emailAddresses.first?.value as String?
            let birthday = cnContact.birthday?.date
            let imageData: Data? = cnContact.imageData ?? cnContact.thumbnailImageData
            
            let zodiacSign: ZodiacSign
            if let selected = contactZodiacMap[identifier] {
                zodiacSign = selected
            } else if let bday = birthday {
                zodiacSign = ZodiacSign.from(birthday: bday)
            } else {
                zodiacSign = .unknown
            }
            
            let contact = Contact(
                name: name.isEmpty ? "Unknown" : name,
                phoneNumber: phoneNumber,
                email: email,
                zodiacSign: zodiacSign,
                birthday: birthday,
                profileImageData: imageData,
                contactIdentifier: cnContact.identifier
            )
            
            modelContext.insert(contact)
            newContacts.append(contact)
        }
        
        // Trigger oracle generation in background for contacts with birthdays
        let contactsToProcess = newContacts // Create immutable copy for Task
        Task {
            await generateOraclesForNewContacts(contactsToProcess)
        }
        
        dismiss()
    }
    
    private func generateOraclesForNewContacts(_ contacts: [Contact]) async {
        for contact in contacts {
            guard !contact.zodiacSign.isMissingInfo else { continue }
            
            do {
                _ = try await OracleManager.shared.generateOracleContent(for: contact)
                print("✨ Generated oracle for \(contact.name)")
            } catch {
                print("⚠️ Failed to generate oracle for \(contact.name): \(error.localizedDescription)")
            }
        }
    }
}

// Contact row for selection
struct ContactSelectionRow: View {
    let cnContact: CNContact
    let isSelected: Bool
    let zodiacSign: ZodiacSign?
    let onToggle: (Bool) -> Void
    let onZodiacChange: (ZodiacSign) -> Void
    
    @State private var showingZodiacPicker = false
    
    var contactName: String {
        let fullName = "\(cnContact.givenName) \(cnContact.familyName)".trimmingCharacters(in: .whitespaces)
        if !fullName.isEmpty {
            return fullName
        }
        if !cnContact.nickname.isEmpty {
            return cnContact.nickname
        }
        if !cnContact.organizationName.isEmpty {
            return cnContact.organizationName
        }
        return "Unknown"
    }
    
    var hasBirthday: Bool {
        cnContact.birthday != nil
    }
    
    var body: some View {
        HStack {
            Button {
                onToggle(!isSelected)
            } label: {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .purple : .white.opacity(0.4))
                    .font(.title3)
            }
            .buttonStyle(PlainButtonStyle())
            
            Text(contactName)
                .foregroundColor(.white)
            
            Spacer()
            
            if isSelected {
                Button {
                    showingZodiacPicker = true
                } label: {
                    HStack(spacing: 4) {
                        if let sign = zodiacSign, !sign.isMissingInfo {
                            Text(sign.emoji)
                            Text(sign.rawValue)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        } else {
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(.orange)
                            Text("Missing info")
                                .font(.caption)
                                .foregroundColor(.orange.opacity(0.8))
                        }
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            } else if hasBirthday {
                HStack(spacing: 4) {
                    Image(systemName: "gift.fill")
                        .font(.caption)
                        .foregroundColor(.pink.opacity(0.7))
                }
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle(!isSelected)
        }
        .sheet(isPresented: $showingZodiacPicker) {
            ZodiacPickerView(selectedSign: zodiacSign, onSelect: onZodiacChange)
        }
    }
}

// Zodiac picker view
struct ZodiacPickerView: View {
    let selectedSign: ZodiacSign?
    let onSelect: (ZodiacSign) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(ZodiacSign.realSigns, id: \.self) { sign in
                    Button {
                        onSelect(sign)
                        dismiss()
                    } label: {
                        HStack {
                            Text(sign.emoji)
                                .font(.title2)
                            
                            VStack(alignment: .leading) {
                                Text(sign.rawValue)
                                    .foregroundColor(.primary)
                                Text(sign.dateRange)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if selectedSign == sign {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.purple)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Zodiac Sign")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// Search bar
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.4))
            
            TextField("Search contacts", text: $text)
                .textFieldStyle(.plain)
                .foregroundColor(.white)
            
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.4))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

extension DateComponents {
    var date: Date? {
        Calendar.current.date(from: self)
    }
}
