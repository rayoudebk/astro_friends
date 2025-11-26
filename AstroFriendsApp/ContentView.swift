import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Contact.name) private var contacts: [Contact]
    @Query private var checkIns: [CheckIn]
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("zodiacOrder") private var zodiacOrderData: Data = Data()
    
    @State private var showingAddContact = false
    @State private var searchText = ""
    @State private var isSearchActive = false
    @State private var selectedZodiacSign: ZodiacSign? = nil
    @State private var showingOnboarding = false
    @State private var isAddingFromOnboarding = false
    @State private var showingRecordCheckInSheet = false
    @State private var showingHoroscopeDetail = false
    @State private var selectedHoroscopeSign: ZodiacSign = .aries
    @State private var showingZodiacReorder = false
    
    // Get ordered zodiac signs (user can reorder)
    var orderedZodiacSigns: [ZodiacSign] {
        if let decoded = try? JSONDecoder().decode([ZodiacSign].self, from: zodiacOrderData), !decoded.isEmpty {
            return decoded
        }
        return ZodiacSign.allCases
    }
    
    func saveZodiacOrder(_ signs: [ZodiacSign]) {
        if let encoded = try? JSONEncoder().encode(signs) {
            zodiacOrderData = encoded
        }
    }
    
    var filteredContacts: [Contact] {
        var filtered = contacts
        
        // Filter by search
        if !searchText.isEmpty {
            filtered = filtered.filter { contact in
                contact.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filter by zodiac sign
        if let zodiac = selectedZodiacSign {
            filtered = filtered.filter { $0.zodiacSign == zodiac }
        }
        
        // Sort: Favorites first, then by name
        filtered.sort { (c1, c2) in
            if c1.isFavorite != c2.isFavorite {
                return c1.isFavorite
            }
            return c1.name < c2.name
        }
        
        return filtered
    }
    
    var greeting: String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        
        if hour < 12 {
            return "Good morning!"
        } else if hour < 17 {
            return "Good afternoon!"
        } else {
            return "Good evening!"
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom header with greeting and action buttons
                HStack {
                    Text(greeting)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        NavigationLink(destination: SettingsView()) {
                            Image(systemName: "gearshape")
                                .font(.title3)
                        }
                        
                        Menu {
                            Button {
                                isAddingFromOnboarding = false
                                showingAddContact = true
                            } label: {
                                Label("Add contact", systemImage: "person.badge.plus")
                            }
                            
                            Button {
                                showingRecordCheckInSheet = true
                            } label: {
                                Label("Record check-in", systemImage: "checkmark.circle")
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, isSearchActive ? 20 : -40)
                .padding(.bottom, 4)
                
                // Horoscope Card - Large featured card
                HoroscopeCardView(
                    onSignTap: { sign in
                        selectedHoroscopeSign = sign
                        showingHoroscopeDetail = true
                    }
                )
                .padding(.horizontal)
                .padding(.bottom, 12)
                
                // Zodiac Sign Filter with reorder button
                HStack {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ZodiacFilterButton(
                                title: "All",
                                emoji: "✨",
                                isSelected: selectedZodiacSign == nil,
                                count: contacts.count
                            ) {
                                selectedZodiacSign = nil
                            }
                            
                            ForEach(orderedZodiacSigns, id: \.self) { sign in
                                ZodiacFilterButton(
                                    title: sign.rawValue,
                                    emoji: sign.emoji,
                                    isSelected: selectedZodiacSign == sign,
                                    count: contacts.filter { $0.zodiacSign == sign }.count
                                ) {
                                    selectedZodiacSign = sign
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Button {
                        showingZodiacReorder = true
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(8)
                            .background(Color(UIColor.secondarySystemBackground))
                            .clipShape(Circle())
                    }
                    .padding(.trailing)
                }
                .padding(.bottom, 8)
                
                // Contacts List
                if filteredContacts.isEmpty {
                    EmptyStateView(hasContacts: !contacts.isEmpty)
                } else {
                    List {
                        ForEach(filteredContacts) { contact in
                            NavigationLink(destination: ContactDetailView(contact: contact)) {
                                ContactRowView(contact: contact)
                            }
                        }
                        .onDelete(perform: deleteContacts)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("")
            .toolbarBackground(.hidden, for: .navigationBar)
            .searchable(text: $searchText, isPresented: $isSearchActive, prompt: "Search contacts")
            .sheet(isPresented: $showingAddContact) {
                AddContactView(isFromOnboarding: isAddingFromOnboarding)
            }
            .sheet(isPresented: $showingRecordCheckInSheet) {
                RecordCheckInSheetView(contacts: contacts)
            }
            .sheet(isPresented: $showingHoroscopeDetail) {
                HoroscopeDetailView(sign: selectedHoroscopeSign)
            }
            .sheet(isPresented: $showingZodiacReorder) {
                ZodiacReorderView(orderedSigns: orderedZodiacSigns) { newOrder in
                    saveZodiacOrder(newOrder)
                }
            }
            .onAppear {
                if !hasSeenOnboarding {
                    showingOnboarding = true
                }
            }
            .fullScreenCover(isPresented: $showingOnboarding) {
                OnboardingView(isFromOnboarding: true) {
                    hasSeenOnboarding = true
                    showingOnboarding = false
                    isAddingFromOnboarding = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showingAddContact = true
                    }
                }
            }
        }
    }
    
    private func deleteContacts(at offsets: IndexSet) {
        for index in offsets {
            let contact = filteredContacts[index]
            modelContext.delete(contact)
        }
    }
}

// MARK: - Horoscope Card View
struct HoroscopeCardView: View {
    let onSignTap: (ZodiacSign) -> Void
    @State private var currentSignIndex = 0
    
    private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    
    var currentSign: ZodiacSign {
        ZodiacSign.allCases[currentSignIndex]
    }
    
    var horoscope: Horoscope {
        Horoscope.getWeeklyHoroscope(for: currentSign)
    }
    
    var body: some View {
        Button {
            onSignTap(currentSign)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Text("Weekly Horoscope")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    // Sign indicator dots
                    HStack(spacing: 4) {
                        ForEach(0..<12, id: \.self) { index in
                            Circle()
                                .fill(index == currentSignIndex ? Color.white : Color.white.opacity(0.3))
                                .frame(width: 6, height: 6)
                        }
                    }
                }
                
                // Sign info
                HStack(alignment: .center, spacing: 12) {
                    Text(currentSign.emoji)
                        .font(.system(size: 44))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(currentSign.rawValue)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(currentSign.dateRange)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(horoscope.mood)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(8)
                        
                        Text("Lucky: \(horoscope.luckyNumber)")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                // Reading preview
                Text(horoscope.weeklyReading)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                // Tap to read more
                HStack {
                    Spacer()
                    Text("Tap to read more")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding()
            .background(
                LinearGradient(
                    colors: gradientColors(for: currentSign),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(20)
            .shadow(color: gradientColors(for: currentSign)[0].opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(PlainButtonStyle())
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                currentSignIndex = (currentSignIndex + 1) % 12
            }
        }
    }
    
    func gradientColors(for sign: ZodiacSign) -> [Color] {
        switch sign.element {
        case "Fire": return [Color.red, Color.orange]
        case "Earth": return [Color.green.opacity(0.8), Color.brown.opacity(0.7)]
        case "Air": return [Color.purple, Color.indigo]
        case "Water": return [Color.blue, Color.cyan]
        default: return [Color.gray, Color.secondary]
        }
    }
}

// MARK: - Horoscope Detail View
struct HoroscopeDetailView: View {
    let sign: ZodiacSign
    @Environment(\.dismiss) private var dismiss
    
    var horoscope: Horoscope {
        Horoscope.getWeeklyHoroscope(for: sign)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    HStack(spacing: 16) {
                        Text(sign.emoji)
                            .font(.system(size: 60))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(sign.rawValue)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text(sign.dateRange)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 8) {
                                Label(sign.element, systemImage: sign.icon)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(elementColor(for: sign).opacity(0.2))
                                    .foregroundColor(elementColor(for: sign))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.bottom, 8)
                    
                    // Weekly Reading
                    VStack(alignment: .leading, spacing: 8) {
                        Text("This Week's Reading")
                            .font(.headline)
                        
                        Text(horoscope.weeklyReading)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(16)
                    
                    // Love & Career
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Love", systemImage: "heart.fill")
                                .font(.headline)
                                .foregroundColor(.pink)
                            
                            Text(horoscope.loveAdvice)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(16)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Career", systemImage: "briefcase.fill")
                                .font(.headline)
                                .foregroundColor(.blue)
                            
                            Text(horoscope.careerAdvice)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(16)
                    }
                    
                    // Lucky Info
                    HStack(spacing: 12) {
                        InfoCard(title: "Lucky Number", value: "\(horoscope.luckyNumber)", icon: "number")
                        InfoCard(title: "Lucky Color", value: horoscope.luckyColor, icon: "paintpalette.fill")
                        InfoCard(title: "Mood", value: horoscope.mood, icon: "face.smiling.fill")
                    }
                    
                    // Compatibility
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Best Match This Week")
                            .font(.headline)
                        
                        HStack(spacing: 12) {
                            Text(horoscope.compatibility.emoji)
                                .font(.title)
                            
                            VStack(alignment: .leading) {
                                Text(horoscope.compatibility.rawValue)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text(horoscope.compatibility.dateRange)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Horoscope")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    func elementColor(for sign: ZodiacSign) -> Color {
        switch sign.element {
        case "Fire": return .red
        case "Earth": return .green
        case "Air": return .purple
        case "Water": return .blue
        default: return .gray
        }
    }
}

struct InfoCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Zodiac Filter Button
struct ZodiacFilterButton: View {
    let title: String
    let emoji: String
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(emoji)
                    .font(.title2)
                
                Text(title)
                    .font(.caption2)
                    .fontWeight(isSelected ? .semibold : .regular)
                
                Text("\(count)")
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(UIColor.secondarySystemBackground))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Zodiac Reorder View
struct ZodiacReorderView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var signs: [ZodiacSign]
    let onSave: ([ZodiacSign]) -> Void
    
    init(orderedSigns: [ZodiacSign], onSave: @escaping ([ZodiacSign]) -> Void) {
        _signs = State(initialValue: orderedSigns)
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Drag to reorder zodiac signs in the filter bar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("Zodiac Signs") {
                    ForEach(signs, id: \.self) { sign in
                        HStack {
                            Text(sign.emoji)
                                .font(.title2)
                            Text(sign.rawValue)
                            Spacer()
                            Image(systemName: "line.3.horizontal")
                                .foregroundColor(.secondary)
                        }
                    }
                    .onMove { from, to in
                        signs.move(fromOffsets: from, toOffset: to)
                    }
                }
            }
            .navigationTitle("Reorder Signs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(signs)
                        dismiss()
                    }
                }
            }
            .environment(\.editMode, .constant(.active))
        }
    }
}

// MARK: - Onboarding View
struct OnboardingView: View {
    let isFromOnboarding: Bool
    let onContinue: () -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.indigo.opacity(0.2), Color.purple.opacity(0.15)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        Text("✨ Astro Friends ✨")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Discover the stars in your social circle")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                    .padding(.top, 32)
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            introCard(
                                title: "What is Astro Friends?",
                                description: "Connect your contacts with their zodiac signs, read weekly horoscopes for everyone in your life, and discover astrological compatibility with your friends!"
                            )
                            
                            OnboardingSection(
                                icon: "person.badge.plus",
                                title: "Import your contacts",
                                message: "Add friends and family, and assign their zodiac sign based on their birthday."
                            )
                            
                            OnboardingSection(
                                icon: "sparkles",
                                title: "Weekly horoscopes",
                                message: "Read personalized weekly readings for each zodiac sign in your friend circle."
                            )
                            
                            OnboardingSection(
                                icon: "heart.circle",
                                title: "Discover compatibility",
                                message: "Learn about cosmic connections between you and your friends."
                            )
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                    }
                    
                    VStack(spacing: 12) {
                        Text("Let's start by adding 5 contacts")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button(action: onContinue) {
                            Text("Get started")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.indigo)
                                .foregroundColor(.white)
                                .cornerRadius(16)
                                .shadow(color: Color.indigo.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
        }
    }
    
    private func introCard(title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.thinMaterial)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 6)
    }
}

private struct OnboardingSection: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.indigo)
                .frame(width: 36, height: 36)
                .background(Color.indigo.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
    }
}


