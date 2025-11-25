import SwiftUI
import SwiftData
import Contacts
import ContactsUI
import Foundation

struct AddContactView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var existingContacts: [Contact]
    
    let isFromOnboarding: Bool
    
    @State private var searchText = ""
    @State private var allContacts: [CNContact] = []
    @State private var contactFrequencyMap: [String: Int] = [:]
    @State private var contactZodiacMap: [String: ZodiacSign] = [:]
    @State private var isLoadingContacts = false
    @State private var selectedFrequency: Int? = 7
    
    let frequencyOptions = [7, 30, 90, 365]
    
    var availableContacts: [CNContact] {
        let existingIdentifiers = Set(existingContacts.compactMap { $0.contactIdentifier })
        return allContacts.filter { !existingIdentifiers.contains($0.identifier) }
    }
    
    var filteredContacts: [CNContact] {
        let available = availableContacts
        
        let searchFiltered = searchText.isEmpty ? available : available.filter { contact in
            let name = contactDisplayName(contact)
            return name.localizedCaseInsensitiveContains(searchText)
        }
        
        return searchFiltered.filter { contact in
            if let assignedFrequency = contactFrequencyMap[contact.identifier] {
                return assignedFrequency == selectedFrequency
            }
            return true
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
        if hasBirthday { score += 10 } // Higher score for contacts with birthday
        if hasAddress { score += 3 }
        if totalWaysToReach >= 2 { score += 4 }
        
        if !hasFirstName && !hasLastName && !hasOrganization && !hasEmail && phoneCount == 1 {
            score -= 15
        }
        
        return score
    }
    
    var selectedContacts: [ContactSelection] {
        contactFrequencyMap.compactMap { (identifier, frequencyDays) in
            guard let cnContact = allContacts.first(where: { $0.identifier == identifier }) else { return nil }
            return ContactSelection(
                identifier: identifier,
                cnContact: cnContact,
                frequencyDays: frequencyDays,
                zodiacSign: contactZodiacMap[identifier]
            )
        }
    }
    
    func contactCount(for frequency: Int) -> Int {
        contactFrequencyMap.values.filter { $0 == frequency }.count
    }
    
    func frequencyLabel(for days: Int) -> String {
        switch days {
        case 7: return "Weekly"
        case 30: return "Monthly"
        case 90: return "Quarterly"
        case 365: return "Yearly"
        default: return "\(days) Days"
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                selectContactsStep
            }
            .navigationTitle("Add Contacts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        importContacts()
                    }
                    .disabled(selectedContacts.isEmpty)
                }
            }
            .onAppear {
                loadContacts()
            }
        }
    }
    
    private var selectContactsStep: some View {
        VStack(spacing: 0) {
            // Progress bar during onboarding
            if isFromOnboarding {
                VStack(spacing: 8) {
                    HStack {
                        Text("Add 5 contacts to get started")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(selectedContacts.count)/5")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(selectedContacts.count >= 5 ? .green : .indigo)
                    }
                    .padding(.horizontal)
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color(UIColor.secondarySystemBackground))
                                .frame(height: 8)
                                .cornerRadius(4)
                            
                            Rectangle()
                                .fill(selectedContacts.count >= 5 ? Color.green : Color.indigo)
                                .frame(width: min(CGFloat(selectedContacts.count) / 5.0 * geometry.size.width, geometry.size.width), height: 8)
                                .cornerRadius(4)
                                .animation(.spring(response: 0.3), value: selectedContacts.count)
                        }
                    }
                    .frame(height: 8)
                    .padding(.horizontal)
                }
                .padding(.vertical, 12)
                .background(Color(UIColor.systemBackground))
            }
            
            // Frequency selection
            VStack(spacing: 12) {
                HStack {
                    Text("Set how often you want to catch up")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding(.horizontal)
                
                HStack(spacing: 12) {
                    ForEach(frequencyOptions, id: \.self) { frequency in
                        FrequencyButton(
                            frequency: frequency,
                            label: frequencyLabel(for: frequency),
                            isSelected: selectedFrequency == frequency,
                            count: contactCount(for: frequency),
                            onTap: {
                                if selectedFrequency == frequency {
                                    selectedFrequency = nil
                                } else {
                                    selectedFrequency = frequency
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 16)
            .background(Color(UIColor.secondarySystemBackground))
            
            // Search bar
            SearchBar(text: $searchText)
                .padding(.horizontal)
                .padding(.vertical, 8)
            
            // Contact list
            if isLoadingContacts {
                ProgressView("Loading contacts...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if selectedFrequency == nil {
                VStack(spacing: 16) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("Select a frequency above to assign contacts")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    if !allContacts.isEmpty {
                        Text("\(allContacts.count) contacts ready to assign")
                            .font(.subheadline)
                            .foregroundColor(.indigo)
                            .padding(.top, 8)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredContacts.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.crop.circle.badge.questionmark")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("No contacts found")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Button("Reload Contacts") {
                        loadContacts()
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    if !suggestedContacts.isEmpty {
                        Section("Suggested contacts") {
                            ForEach(suggestedContacts, id: \.identifier) { cnContact in
                                ContactFrequencyRow(
                                    cnContact: cnContact,
                                    selectedFrequency: selectedFrequency!,
                                    isSelected: contactFrequencyMap[cnContact.identifier] == selectedFrequency,
                                    zodiacSign: contactZodiacMap[cnContact.identifier],
                                    onToggle: { isSelected in
                                        if isSelected {
                                            contactFrequencyMap[cnContact.identifier] = selectedFrequency!
                                            // Auto-detect zodiac from birthday
                                            if let birthday = cnContact.birthday?.date {
                                                contactZodiacMap[cnContact.identifier] = ZodiacSign.from(birthday: birthday)
                                            }
                                        } else {
                                            contactFrequencyMap.removeValue(forKey: cnContact.identifier)
                                            contactZodiacMap.removeValue(forKey: cnContact.identifier)
                                        }
                                    },
                                    onZodiacChange: { sign in
                                        contactZodiacMap[cnContact.identifier] = sign
                                    }
                                )
                            }
                        }
                    }
                    
                    if !otherContacts.isEmpty {
                        Section("Other contacts") {
                            ForEach(otherContacts, id: \.identifier) { cnContact in
                                ContactFrequencyRow(
                                    cnContact: cnContact,
                                    selectedFrequency: selectedFrequency!,
                                    isSelected: contactFrequencyMap[cnContact.identifier] == selectedFrequency,
                                    zodiacSign: contactZodiacMap[cnContact.identifier],
                                    onToggle: { isSelected in
                                        if isSelected {
                                            contactFrequencyMap[cnContact.identifier] = selectedFrequency!
                                            if let birthday = cnContact.birthday?.date {
                                                contactZodiacMap[cnContact.identifier] = ZodiacSign.from(birthday: birthday)
                                            }
                                        } else {
                                            contactFrequencyMap.removeValue(forKey: cnContact.identifier)
                                            contactZodiacMap.removeValue(forKey: cnContact.identifier)
                                        }
                                    },
                                    onZodiacChange: { sign in
                                        contactZodiacMap[cnContact.identifier] = sign
                                    }
                                )
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
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
        for selection in selectedContacts {
            let cnContact = selection.cnContact
            let name = "\(cnContact.givenName) \(cnContact.familyName)".trimmingCharacters(in: .whitespaces)
            let phoneNumber = cnContact.phoneNumbers.first?.value.stringValue
            let email = cnContact.emailAddresses.first?.value as String?
            let birthday = cnContact.birthday?.date
            let imageData: Data? = cnContact.imageData ?? cnContact.thumbnailImageData
            
            // Get zodiac from selection or auto-detect from birthday
            let zodiacSign: ZodiacSign
            if let selected = selection.zodiacSign {
                zodiacSign = selected
            } else if let bday = birthday {
                zodiacSign = ZodiacSign.from(birthday: bday)
            } else {
                zodiacSign = .aries // Default
            }
            
            let contact = Contact(
                name: name.isEmpty ? "Unknown" : name,
                phoneNumber: phoneNumber,
                email: email,
                zodiacSign: zodiacSign,
                frequencyDays: selection.frequencyDays,
                photosPersonLocalIdentifier: nil,
                birthday: birthday,
                profileImageData: imageData,
                contactIdentifier: cnContact.identifier
            )
            
            modelContext.insert(contact)
        }
        
        dismiss()
    }
}

// Helper struct
struct ContactSelection: Identifiable {
    let id = UUID()
    let identifier: String
    let cnContact: CNContact
    var frequencyDays: Int
    var zodiacSign: ZodiacSign?
}

// Frequency button
struct FrequencyButton: View {
    let frequency: Int
    let label: String
    let isSelected: Bool
    let count: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(label)
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text("\(count)")
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? Color.indigo : Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Contact row with zodiac picker
struct ContactFrequencyRow: View {
    let cnContact: CNContact
    let selectedFrequency: Int
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
                    .foregroundColor(isSelected ? .indigo : .secondary)
                    .font(.title3)
            }
            .buttonStyle(PlainButtonStyle())
            
            Text(contactName)
                .foregroundColor(.primary)
            
            Spacer()
            
            if isSelected {
                Button {
                    showingZodiacPicker = true
                } label: {
                    HStack(spacing: 4) {
                        if let sign = zodiacSign {
                            Text(sign.emoji)
                        } else {
                            Text("Set sign")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(UIColor.tertiarySystemBackground))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            } else if hasBirthday {
                Image(systemName: "gift.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
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
                ForEach(ZodiacSign.allCases, id: \.self) { sign in
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
                                    .foregroundColor(.indigo)
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
                .foregroundColor(.secondary)
            
            TextField("Search contacts", text: $text)
                .textFieldStyle(.plain)
            
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
}

extension DateComponents {
    var date: Date? {
        Calendar.current.date(from: self)
    }
}

