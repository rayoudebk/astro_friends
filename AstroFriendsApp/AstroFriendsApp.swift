import SwiftUI
import SwiftData
import Contacts

@main
struct AstroFriendsApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    
    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                MainTabView()
            } else {
                OnboardingContainerView()
            }
        }
        .modelContainer(for: [Contact.self])
    }
}

// Onboarding container to handle the flow
struct OnboardingContainerView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    
    var body: some View {
        OnboardingView(isFromOnboarding: true) {
            hasSeenOnboarding = true
        }
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            ContactsView()
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Contacts")
                }
                .tag(1)
            
            ReadingsView()
                .tabItem {
                    Image(systemName: "sparkles")
                    Text("Readings")
                }
                .tag(2)
            
            SearchView()
                .tabItem {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                    Text("Ask")
                }
                .tag(3)
        }
        .tint(.purple)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.12, alpha: 1)
            
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor.white.withAlphaComponent(0.4)
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white.withAlphaComponent(0.4)]
            
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(red: 0.7, green: 0.5, blue: 1.0, alpha: 1)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(red: 0.7, green: 0.5, blue: 1.0, alpha: 1)]
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

// MARK: - Home View
struct HomeView: View {
    @Query private var contacts: [Contact]
    @AppStorage("userZodiacSign") private var savedUserSign: String = "Aries"
    @AppStorage("userBirthday") private var userBirthdayTimestamp: Double = 0
    @AppStorage("userName") private var userName: String = ""
    @State private var showingUserSettings = false
    @State private var isReadingExpanded = false
    @State private var showingHoroscopeDetail = false
    
    var userSign: ZodiacSign {
        ZodiacSign(rawValue: savedUserSign) ?? .aries
    }
    
    var horoscope: Horoscope {
        Horoscope.getWeeklyHoroscope(for: userSign)
    }
    
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 {
            return "Good morning"
        } else if hour < 17 {
            return "Good afternoon"
        } else {
            return "Good evening"
        }
    }
    
    var displayName: String {
        if !userName.isEmpty {
            return userName.components(separatedBy: " ").first ?? userName
        }
        return ""
    }
    
    var contactCompatibilities: [(contact: Contact, score: Int)] {
        contacts
            .filter { !$0.zodiacSign.isMissingInfo }
            .map { contact in
                let compatibility = AstralCompatibility(person1Sign: userSign, person2Sign: contact.zodiacSign)
                return (contact: contact, score: compatibility.harmonyScore)
            }
            .sorted { $0.score > $1.score }
    }
    
    var topCompatibilities: [(contact: Contact, score: Int)] {
        Array(contactCompatibilities.prefix(5))
    }
    
    var worstCompatibilities: [(contact: Contact, score: Int)] {
        Array(contactCompatibilities.suffix(5).reversed())
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerView
                    weeklyReadingCard
                    
                    if !contacts.isEmpty {
                        compatibilitySection
                    } else {
                        emptyContactsPrompt
                    }
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [Color(red: 0.05, green: 0.05, blue: 0.12), Color(red: 0.08, green: 0.04, blue: 0.18)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text(userSign.emoji)
                        .font(.title2)
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Astro Friends")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingUserSettings = true
                    } label: {
                        Image(systemName: "person.circle")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .sheet(isPresented: $showingUserSettings) {
                UserProfileSheet(userSign: userSign)
            }
            .sheet(isPresented: $showingHoroscopeDetail) {
                HoroscopeDetailView(sign: userSign)
            }
        }
        .preferredColorScheme(.dark)
    }
    
    
    private var headerView: some View {
        VStack(spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(greeting)\(displayName.isEmpty ? "" : ", \(displayName)")")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(formattedDate)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                }
                Spacer()
            }
        }
        .padding(.top, 8)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }
    
    private var weeklyReadingCard: some View {
        Button {
            showingHoroscopeDetail = true
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(userSign.emoji)
                        .font(.title)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Weekly Horoscope")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(userSign.dateRange)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Text(horoscope.mood)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.purple.opacity(0.3))
                            .foregroundColor(.purple)
                            .cornerRadius(8)
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                
                Text(horoscope.weeklyReading)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                // Moon info row
                HStack {
                    HStack(spacing: 4) {
                        Text(Horoscope.currentMoonPhase.emoji)
                        Text(Horoscope.currentMoonPhase.rawValue)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    Text("Tap to read more")
                        .font(.caption)
                        .foregroundColor(.purple.opacity(0.8))
                }
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.purple.opacity(0.2), Color.indigo.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
    
    private var compatibilitySection: some View {
        VStack(spacing: 12) {
            // Section header
            HStack {
                Text("This Week's Connections")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            
            // Side by side cards
            HStack(spacing: 12) {
                // Best Matches
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("Best")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    
                    if topCompatibilities.isEmpty {
                        Text("Add contacts")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    } else {
                        ForEach(topCompatibilities.prefix(3), id: \.contact.id) { item in
                            miniCompatibilityRow(contact: item.contact, score: item.score, isTop: true)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.green.opacity(0.1))
                .cornerRadius(16)
                
                // Growth Opportunities
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "leaf.fill")
                            .foregroundColor(.orange)
                        Text("Growth")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    
                    if worstCompatibilities.isEmpty || contactCompatibilities.count <= 3 {
                        Text("Need more contacts")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    } else {
                        ForEach(worstCompatibilities.prefix(3), id: \.contact.id) { item in
                            miniCompatibilityRow(contact: item.contact, score: item.score, isTop: false)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(16)
            }
        }
    }
    
    private func miniCompatibilityRow(contact: Contact, score: Int, isTop: Bool) -> some View {
        HStack(spacing: 8) {
            if let imageData = contact.profileImageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 28, height: 28)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Text(contact.name.prefix(1).uppercased())
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    )
            }
            
            Text(contact.name.components(separatedBy: " ").first ?? contact.name)
                .font(.caption)
                .foregroundColor(.white)
                .lineLimit(1)
            
            Spacer()
            
            Text("\(score)%")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(isTop ? .green : .orange)
        }
    }
    
    private func compatibilityRow(contact: Contact, score: Int, isTop: Bool) -> some View {
        HStack {
            if let imageData = contact.profileImageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(contact.name.prefix(1).uppercased())
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.7))
                    )
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(contact.name)
                    .font(.subheadline)
                    .foregroundColor(.white)
                Text(contact.zodiacSign.rawValue)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                Text("\(score)%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isTop ? .green : .orange)
                Text(contact.zodiacSign.emoji)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var emptyContactsPrompt: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.2.fill")
                .font(.largeTitle)
                .foregroundColor(.white.opacity(0.3))
            Text("Add contacts to see compatibility")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
            Text("Go to Contacts tab to add friends")
                .font(.caption)
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
}

// MARK: - User Profile Sheet
struct UserProfileSheet: View {
    let userSign: ZodiacSign
    @AppStorage("userZodiacSign") private var savedUserSign: String = "Aries"
    @AppStorage("userBirthday") private var userBirthdayTimestamp: Double = 0
    @AppStorage("userName") private var userName: String = ""
    
    @State private var selectedSign: ZodiacSign = .aries
    @State private var hasBirthday = false
    @State private var birthday = Date()
    @State private var name = ""
    @State private var showingContactPicker = false
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button {
                        showingContactPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "person.crop.circle.fill")
                                .foregroundColor(.blue)
                            Text("Import from Contacts")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                } header: {
                    Text("Quick Import")
                } footer: {
                    Text("Import your name and birthday from your contact card")
                }
                
                Section("Your Name") {
                    TextField("First name", text: $name)
                }
                
                Section("Your Sign") {
                    Picker("Zodiac Sign", selection: $selectedSign) {
                        ForEach(ZodiacSign.realSigns, id: \.self) { sign in
                            HStack {
                                Text(sign.emoji)
                                Text(sign.rawValue)
                            }
                            .tag(sign)
                        }
                    }
                }
                
                Section("Birthday") {
                    Toggle("I know my birthday", isOn: $hasBirthday)
                    if hasBirthday {
                        DatePicker("Birthday", selection: $birthday, displayedComponents: .date)
                            .onChange(of: birthday) { _, newDate in
                                selectedSign = ZodiacSign.from(birthday: newDate)
                            }
                    }
                }
            }
            .navigationTitle("Your Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        savedUserSign = selectedSign.rawValue
                        userBirthdayTimestamp = hasBirthday ? birthday.timeIntervalSince1970 : 0
                        userName = name
                        dismiss()
                    }
                }
            }
            .onAppear {
                selectedSign = userSign
                name = userName
                if userBirthdayTimestamp > 0 {
                    hasBirthday = true
                    birthday = Date(timeIntervalSince1970: userBirthdayTimestamp)
                }
            }
            .sheet(isPresented: $showingContactPicker) {
                ContactBirthdayPicker { importedBirthday in
                    hasBirthday = true
                    birthday = importedBirthday
                    selectedSign = ZodiacSign.from(birthday: importedBirthday)
                } onNoBirthday: {
                    // No birthday found
                } onNameFound: { importedName in
                    name = importedName
                }
            }
        }
    }
}

// MARK: - Readings View
struct ReadingsView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.purple.opacity(0.3), .indigo.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: "sparkles")
                                .font(.system(size: 50))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.purple, .pink],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        }
                        
                        Text("Readings Marketplace")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Coming Soon")
                            .font(.headline)
                            .foregroundColor(.purple)
                        
                        Text("Connect with professional astrologers and tarot readers for personalized consultations")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.top, 60)
                    
                    VStack(spacing: 16) {
                        readingsFeatureCard(icon: "person.fill.questionmark", title: "Live Consultations", description: "Book video calls with certified astrologers", color: .cyan)
                        readingsFeatureCard(icon: "suit.diamond.fill", title: "Tarot Readings", description: "Get personalized tarot card readings", color: .pink)
                        readingsFeatureCard(icon: "chart.xyaxis.line", title: "Birth Chart Analysis", description: "Deep dive into your natal chart", color: .orange)
                        readingsFeatureCard(icon: "heart.circle.fill", title: "Relationship Synastry", description: "Detailed compatibility reports", color: .red)
                    }
                    .padding(.horizontal)
                    .padding(.top, 32)
                    
                    Button { } label: {
                        HStack {
                            Image(systemName: "bell.fill")
                            Text("Notify Me When Available")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(LinearGradient(colors: [.purple, .indigo], startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(16)
                    }
                    .padding(.horizontal)
                    .padding(.top, 24)
                    
                    Spacer(minLength: 100)
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Readings")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func readingsFeatureCard(icon: String, title: String, description: String, color: Color) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            Image(systemName: "lock.fill")
                .font(.caption)
                .foregroundColor(.white.opacity(0.3))
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
}

// MARK: - Search View
struct SearchView: View {
    @State private var messageText = ""
    @State private var messages: [ChatMessage] = []
    @State private var isTyping = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            if messages.isEmpty {
                                searchWelcomeView
                                    .padding(.top, 40)
                            }
                            
                            ForEach(messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                            
                            if isTyping {
                                HStack {
                                    TypingIndicator()
                                    Spacer()
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) { _, _ in
                        if let lastMessage = messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                searchInputBar
            }
            .background(
                LinearGradient(
                    colors: [Color(red: 0.05, green: 0.05, blue: 0.12), Color(red: 0.08, green: 0.04, blue: 0.18)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundColor(.purple)
                        Text("Ask the Stars")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                
                if !messages.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { messages.removeAll() } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private var searchWelcomeView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.purple.opacity(0.3), .indigo.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 100, height: 100)
                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundStyle(LinearGradient(colors: [.purple, .pink], startPoint: .top, endPoint: .bottom))
            }
            
            VStack(spacing: 8) {
                Text("Ask the Stars")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Text("Your cosmic guide awaits")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            VStack(spacing: 12) {
                searchSuggestionButton("What does my horoscope say today?")
                searchSuggestionButton("Am I compatible with a Leo?")
                searchSuggestionButton("What does Mercury retrograde mean?")
                searchSuggestionButton("Explain my rising sign")
            }
        }
    }
    
    private func searchSuggestionButton(_ text: String) -> some View {
        Button { sendMessage(text) } label: {
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.1))
                .cornerRadius(20)
        }
    }
    
    private var searchInputBar: some View {
        HStack(spacing: 12) {
            TextField("Ask about astrology...", text: $messageText, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.1))
                .cornerRadius(24)
                .foregroundColor(.white)
                .focused($isTextFieldFocused)
                .lineLimit(1...5)
            
            Button { sendMessage(messageText) } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title)
                    .foregroundColor(messageText.isEmpty ? .white.opacity(0.3) : .purple)
            }
            .disabled(messageText.isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(red: 0.05, green: 0.05, blue: 0.12))
    }
    
    private func sendMessage(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = ChatMessage(content: text, isUser: true)
        messages.append(userMessage)
        messageText = ""
        isTextFieldFocused = false
        
        isTyping = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isTyping = false
            let response = generateResponse(for: text)
            let aiMessage = ChatMessage(content: response, isUser: false)
            messages.append(aiMessage)
        }
    }
    
    private func generateResponse(for query: String) -> String {
        let lowercased = query.lowercased()
        
        if lowercased.contains("horoscope") || lowercased.contains("today") {
            return "Based on the current celestial alignments, today is a wonderful day for reflection and connection. The Moon in \(Horoscope.currentMoonSign.rawValue) brings \(Horoscope.currentMoonSign.emotionalFlavor) energy. \(Horoscope.currentMoonPhase.guidance)"
        } else if lowercased.contains("compatible") || lowercased.contains("compatibility") {
            return "Compatibility in astrology goes beyond just sun signs! For a complete picture, we look at Moon signs for emotional compatibility, Venus for love styles, and Mars for passion. Would you like to learn more about any specific pairing?"
        } else if lowercased.contains("mercury retrograde") {
            return "Mercury retrograde is when Mercury appears to move backward in the sky. It's associated with communication mishaps, technology glitches, and revisiting the past. It's actually a great time for reflection, reviewing plans, and reconnecting with old friends—just be extra careful with contracts and travel plans!"
        } else if lowercased.contains("rising") || lowercased.contains("ascendant") {
            return "Your Rising sign (or Ascendant) represents how you appear to others and your outward personality. It's determined by the zodiac sign that was rising on the eastern horizon at your exact time of birth."
        } else if lowercased.contains("moon sign") {
            return "Your Moon sign represents your emotional nature, inner self, and subconscious patterns. It reveals how you process feelings, what makes you feel secure, and your instinctive reactions."
        } else {
            return "That's a great question about astrology! The cosmos is always speaking to us through planetary movements and celestial patterns. Each aspect of your birth chart tells a unique part of your story. What specific aspect would you like to explore deeper?"
        }
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp = Date()
}

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser { Spacer(minLength: 60) }
            
            Text(message.content)
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    message.isUser ?
                    LinearGradient(colors: [.purple, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing) :
                    LinearGradient(colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .cornerRadius(20)
            
            if !message.isUser { Spacer(minLength: 60) }
        }
    }
}

struct TypingIndicator: View {
    @State private var animationOffset = 0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 8, height: 8)
                    .offset(y: animationOffset == index ? -5 : 0)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(20)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.4).repeatForever()) {
                animationOffset = (animationOffset + 1) % 3
            }
        }
    }
}
