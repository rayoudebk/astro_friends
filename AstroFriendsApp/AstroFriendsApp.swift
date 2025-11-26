import SwiftUI
import SwiftData
import Contacts
import MapKit
import CoreLocation

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
    @AppStorage("userBirthTime") private var userBirthTimeTimestamp: Double = 0
    @AppStorage("userBirthPlace") private var userBirthPlace: String = ""
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("userUUID") private var userUUID: String = UUID().uuidString // Stable user ID for oracle
    @State private var showingUserSettings = false
    @State private var isReadingExpanded = false
    @State private var showingHoroscopeDetail = false
    
    // Tier 2 weekly horoscope state
    @State private var weeklyHoroscope: WeeklyHoroscope?
    @State private var isLoadingHoroscope = false
    
    // Tier 3 personal oracle state (for user)
    @State private var personalOracle: OracleContent?
    @State private var isLoadingPersonalOracle = false
    @State private var personalOracleError: String?
    
    var userSign: ZodiacSign {
        ZodiacSign(rawValue: savedUserSign) ?? .aries
    }
    
    // Fallback to static if Tier 2 not loaded
    var staticHoroscope: Horoscope {
        Horoscope.getWeeklyHoroscope(for: userSign)
    }
    
    // Display values: Tier 2 → Tier 1 fallback
    var displayReading: String {
        weeklyHoroscope?.weeklyReading ?? staticHoroscope.weeklyReading
    }
    
    var displayMood: String {
        weeklyHoroscope?.mood ?? staticHoroscope.mood
    }
    
    var isAIGenerated: Bool {
        weeklyHoroscope?.isAIGenerated ?? false
    }
    
    // Check if user has enough data for Tier 3
    var canAccessTier3: Bool {
        userBirthdayTimestamp > 0 // At minimum needs birthday
    }
    
    var hasFullBirthData: Bool {
        userBirthdayTimestamp > 0 && userBirthTimeTimestamp > 0 && !userBirthPlace.isEmpty
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
    
    // MARK: - State for expandable sections
    @State private var showFullReading = false
    @State private var showFullOracle = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Greeting Header
                    headerView
                    
                    // 🌙 Celestial Hero Card
                    celestialHeroCard
                    
                    // ⚡ Quick Stats (Horizontal Scroll)
                    quickStatsStrip
                    
                    // 📊 Energy Meters
                    energyMetersCard
                    
                    // 📖 Weekly Reading (Collapsible)
                    collapsibleReadingCard
                    
                    // ✨ Personal Oracle (if available)
                    if canAccessTier3 {
                        collapsibleOracleCard
                    }
                    
                    // 🌟 Daily Affirmation
                    dailyAffirmationCard
                    
                    // 💕 Top Compatibilities
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
            .task {
                await loadWeeklyHoroscope()
                if canAccessTier3 {
                    await loadPersonalOracle()
                }
            }
            .onChange(of: savedUserSign) { _, _ in
                Task {
                    await loadWeeklyHoroscope()
                    if canAccessTier3 {
                        await loadPersonalOracle()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Load Tier 2 Weekly Horoscope
    private func loadWeeklyHoroscope() async {
        isLoadingHoroscope = true
        weeklyHoroscope = await ContentService.shared.getWeeklyHoroscope(for: userSign)
        isLoadingHoroscope = false
    }
    
    // MARK: - Load Tier 3 Personal Oracle
    
    // Helper to create a stable user Contact for oracle generation
    private func createUserContact() -> Contact {
        let contact = Contact(
            name: userName.isEmpty ? "You" : userName,
            zodiacSign: userSign,
            birthday: userBirthdayTimestamp > 0 ? Date(timeIntervalSince1970: userBirthdayTimestamp) : nil,
            birthTime: userBirthTimeTimestamp > 0 ? Date(timeIntervalSince1970: userBirthTimeTimestamp) : nil,
            birthPlace: userBirthPlace.isEmpty ? nil : userBirthPlace
        )
        // Use stable UUID so caching works
        if let stableId = UUID(uuidString: userUUID) {
            contact.id = stableId
        }
        return contact
    }
    
    private func loadPersonalOracle() async {
        guard canAccessTier3 else { return }
        
        isLoadingPersonalOracle = true
        personalOracleError = nil
        
        let userContact = createUserContact()
        
        // Check for cached content first
        do {
            if let cached = try await SupabaseService.shared.fetchOracleContent(contactId: userContact.id) {
                personalOracle = cached
            } else {
                // Generate fresh
                personalOracle = try await OracleManager.shared.generateOracleContent(for: userContact)
            }
        } catch let decodingError as DecodingError {
            // Provide detailed decoding error info
            switch decodingError {
            case .typeMismatch(let type, let context):
                personalOracleError = "Type mismatch: \(type) at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
            case .valueNotFound(let type, let context):
                personalOracleError = "Value not found: \(type) at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
            case .keyNotFound(let key, _):
                personalOracleError = "Key not found: \(key.stringValue)"
            case .dataCorrupted(let context):
                personalOracleError = "Data corrupted: \(context.debugDescription)"
            @unknown default:
                personalOracleError = "Decoding error: \(decodingError.localizedDescription)"
            }
            print("❌ Oracle decoding error: \(personalOracleError ?? "")")
        } catch {
            personalOracleError = error.localizedDescription
            print("❌ Oracle error: \(error)")
        }
        
        isLoadingPersonalOracle = false
    }
    
    private func refreshPersonalOracle() async {
        guard canAccessTier3 else { return }
        
        isLoadingPersonalOracle = true
        personalOracleError = nil
        
        let userContact = createUserContact()
        
        do {
            personalOracle = try await OracleManager.shared.generateOracleContent(for: userContact)
        } catch {
            personalOracleError = error.localizedDescription
        }
        
        isLoadingPersonalOracle = false
    }
    
    
    private var headerView: some View {
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
            
            // User's sign badge
            Text(userSign.emoji)
                .font(.largeTitle)
        }
        .padding(.top, 8)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }
    
    // MARK: - 🌙 Celestial Hero Card
    private var celestialHeroCard: some View {
        VStack(spacing: 16) {
            // Big Moon Phase Visual
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.purple.opacity(0.3), .indigo.opacity(0.1), .clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Text(Horoscope.currentMoonPhase.emoji)
                    .font(.system(size: 60))
            }
            
            // Moon Phase Name
            Text(Horoscope.currentMoonPhase.rawValue)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            // Moon Sign
            HStack(spacing: 4) {
                Text("Moon in")
                    .foregroundColor(.white.opacity(0.6))
                Text(Horoscope.currentMoonSign.rawValue)
                    .fontWeight(.medium)
                    .foregroundColor(.purple)
            }
            .font(.subheadline)
            
            // Today's Vibe - One Word
            Text(displayMood)
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        colors: [.purple, .indigo],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(20)
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color.purple.opacity(0.15), Color.indigo.opacity(0.1)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(24)
    }
    
    // MARK: - ⚡ Quick Stats Strip
    private var quickStatsStrip: some View {
        let horoscope = Horoscope.getWeeklyHoroscope(for: userSign)
        
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Lucky Number
                QuickStatBadge(
                    icon: "🔢",
                    value: "\(weeklyHoroscope?.luckyNumber ?? horoscope.luckyNumber)",
                    label: "Lucky #",
                    color: .yellow
                )
                
                // Lucky Color
                QuickStatBadge(
                    icon: "🎨",
                    value: weeklyHoroscope?.luckyColor ?? horoscope.luckyColor,
                    label: "Color",
                    color: .purple
                )
                
                // Best Match (from local Horoscope which has compatibility)
                QuickStatBadge(
                    icon: horoscope.compatibility.emoji,
                    value: horoscope.compatibility.rawValue,
                    label: "Match",
                    color: .pink
                )
                
                // Element
                QuickStatBadge(
                    icon: userSign.elementEmoji,
                    value: userSign.element,
                    label: "Element",
                    color: .cyan
                )
            }
            .padding(.horizontal, 4)
        }
    }
    
    // MARK: - 📊 Energy Meters Card
    private var energyMetersCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("This Week's Energy")
                .font(.headline)
                .foregroundColor(.white)
            
            // Love Meter
            EnergyMeter(
                icon: "💕",
                label: "Love",
                value: loveEnergy,
                color: .pink
            )
            
            // Career Meter
            EnergyMeter(
                icon: "💼",
                label: "Career",
                value: careerEnergy,
                color: .orange
            )
            
            // Wellness Meter
            EnergyMeter(
                icon: "🧘",
                label: "Wellness",
                value: wellnessEnergy,
                color: .green
            )
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(20)
    }
    
    // Energy values based on horoscope mood
    private var loveEnergy: Double {
        let mood = displayMood.lowercased()
        if mood.contains("romantic") || mood.contains("passionate") { return 0.9 }
        if mood.contains("harmoni") || mood.contains("balanced") { return 0.75 }
        if mood.contains("introspect") || mood.contains("reflective") { return 0.5 }
        return 0.65
    }
    
    private var careerEnergy: Double {
        let mood = displayMood.lowercased()
        if mood.contains("ambitious") || mood.contains("determined") { return 0.9 }
        if mood.contains("creative") || mood.contains("inspired") { return 0.8 }
        if mood.contains("reflective") || mood.contains("contemplative") { return 0.5 }
        return 0.7
    }
    
    private var wellnessEnergy: Double {
        let mood = displayMood.lowercased()
        if mood.contains("peaceful") || mood.contains("calm") || mood.contains("balanced") { return 0.9 }
        if mood.contains("energetic") || mood.contains("vibrant") { return 0.85 }
        if mood.contains("intense") || mood.contains("turbulent") { return 0.5 }
        return 0.75
    }
    
    // MARK: - 📖 Collapsible Reading Card
    private var collapsibleReadingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    showFullReading.toggle()
                }
            } label: {
                HStack {
                    Text(userSign.emoji)
                        .font(.title2)
                    
                    Text("Weekly Reading")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: showFullReading ? "chevron.up" : "chevron.down")
                        .foregroundColor(.purple)
                        .font(.caption)
                }
            }
            .buttonStyle(.plain)
            
            // Preview or Full Text
            Text(displayReading)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(showFullReading ? nil : 2)
                .multilineTextAlignment(.leading)
            
            if !showFullReading {
                Button {
                    withAnimation { showFullReading = true }
                } label: {
                    Text("Read more...")
                        .font(.caption)
                        .foregroundColor(.purple)
                }
            } else {
                // Show detail button when expanded
                Button {
                    showingHoroscopeDetail = true
                } label: {
                    HStack {
                        Text("See full horoscope")
                        Image(systemName: "arrow.right")
                    }
                    .font(.caption)
                    .foregroundColor(.purple)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    // MARK: - ✨ Collapsible Oracle Card
    private var collapsibleOracleCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    showFullOracle.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Your Personal Oracle")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        if isLoadingPersonalOracle {
                            Text("Consulting the stars...")
                                .font(.caption)
                                .foregroundColor(.yellow.opacity(0.7))
                        }
                    }
                    
                    Spacer()
                    
                    if isLoadingPersonalOracle {
                        ProgressView()
                            .tint(.yellow)
                            .scaleEffect(0.7)
                    } else {
                        Image(systemName: showFullOracle ? "chevron.up" : "chevron.down")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                }
            }
            .buttonStyle(.plain)
            
            if let oracle = personalOracle {
                Text(oracle.weeklyReading)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(showFullOracle ? nil : 2)
                
                if showFullOracle {
                    // Oracle Details
                    HStack(spacing: 16) {
                        if let lucky = oracle.luckyNumber {
                            VStack(spacing: 2) {
                                Text("\(lucky)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.yellow)
                                Text("Lucky")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                        
                        if let color = oracle.luckyColor {
                            VStack(spacing: 2) {
                                Circle()
                                    .fill(colorFromName(color))
                                    .frame(width: 24, height: 24)
                                Text(color)
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                        
                        if let mood = oracle.mood {
                            VStack(spacing: 2) {
                                Text(moodEmoji(for: mood))
                                    .font(.title2)
                                Text(mood)
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.top, 8)
                    
                    if let insight = oracle.celestialInsight {
                        Text("✨ \(insight)")
                            .font(.caption)
                            .italic()
                            .foregroundColor(.yellow.opacity(0.8))
                            .padding(.top, 4)
                    }
                }
            } else if let error = personalOracleError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red.opacity(0.8))
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.yellow.opacity(0.1), Color.orange.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
    }
    
    // Helper functions for oracle card
    private func colorFromName(_ name: String) -> Color {
        switch name.lowercased() {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "purple": return .purple
        case "pink": return .pink
        case "orange": return .orange
        case "yellow": return .yellow
        case "gold": return .yellow
        case "silver": return .gray
        case "white": return .white
        default: return .purple
        }
    }
    
    private func moodEmoji(for mood: String) -> String {
        switch mood.lowercased() {
        case "romantic", "passionate": return "💕"
        case "calm", "peaceful": return "🧘"
        case "energetic", "vibrant": return "⚡"
        case "reflective", "introspective": return "🔮"
        case "creative", "inspired": return "🎨"
        case "harmonious", "balanced": return "☯️"
        default: return "✨"
        }
    }
    
    // MARK: - 🌟 Daily Affirmation Card
    private var dailyAffirmationCard: some View {
        VStack(spacing: 12) {
            Text("✨ Today's Affirmation ✨")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
            
            Text(dailyAffirmation)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .italic()
            
            Button {
                shareAffirmation()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share")
                }
                .font(.caption)
                .foregroundColor(.purple)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color.purple.opacity(0.1), Color.pink.opacity(0.1)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(16)
    }
    
    private var dailyAffirmation: String {
        let affirmations: [ZodiacSign: String] = [
            .aries: "I embrace my courage and lead with passion.",
            .taurus: "I am grounded, patient, and abundant.",
            .gemini: "My curiosity opens doors to endless possibilities.",
            .cancer: "I nurture myself and others with compassion.",
            .leo: "I shine my authentic light for all to see.",
            .virgo: "My attention to detail creates perfection.",
            .libra: "I create harmony and beauty wherever I go.",
            .scorpio: "My transformation leads to profound growth.",
            .sagittarius: "My optimism attracts amazing adventures.",
            .capricorn: "I build my dreams with discipline and patience.",
            .aquarius: "My unique vision changes the world.",
            .pisces: "I trust my intuition to guide my path."
        ]
        return affirmations[userSign] ?? "The stars align in my favor today."
    }
    
    private func shareAffirmation() {
        // Share functionality placeholder
    }
    
    // MARK: - Old Weekly Reading Card (kept for reference, can be removed)
    private var weeklyReadingCard: some View {
        EmptyView() // Replaced by collapsibleReadingCard
    }
    
    // MARK: - Tier 3 Personal Oracle Card
    private var personalOracleCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Your Personal Oracle")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("TIER 3")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.yellow.opacity(0.2))
                            .cornerRadius(4)
                    }
                    
                    if hasFullBirthData {
                        Text("Full natal chart reading")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    } else {
                        Text("Add birth time & place for deeper insights")
                            .font(.caption)
                            .foregroundColor(.orange.opacity(0.8))
                    }
                }
                
                Spacer()
                
                if personalOracle != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            
            // Content
            if isLoadingPersonalOracle && personalOracle == nil {
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(.yellow.opacity(0.8))
                        .scaleEffect(0.8)
                    Text("Consulting the celestial oracle...")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .italic()
                }
                .padding(.vertical, 8)
            } else if let oracle = personalOracle {
                Text(oracle.weeklyReading)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
                
                // Personal details row
                HStack(spacing: 16) {
                    if let lucky = oracle.luckyNumber {
                        VStack(spacing: 2) {
                            Text("\(lucky)")
                                .font(.headline)
                                .foregroundColor(.yellow)
                            Text("Lucky #")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    
                    if let color = oracle.luckyColor {
                        VStack(spacing: 2) {
                            Text(color)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.purple)
                            Text("Color")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    
                    if let mood = oracle.mood {
                        VStack(spacing: 2) {
                            Text(mood)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.cyan)
                            Text("Vibe")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    
                    Spacer()
                }
                .padding(.top, 4)
                
                // Celestial insight
                if let insight = oracle.celestialInsight {
                    Text("✨ \(insight)")
                        .font(.caption)
                        .italic()
                        .foregroundColor(.white.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 6)
                }
            } else if let error = personalOracleError {
                VStack(spacing: 8) {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red.opacity(0.8))
                    
                    Button {
                        Task { await refreshPersonalOracle() }
                    } label: {
                        Text("Retry")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }
            } else {
                // Generate button
                Button {
                    Task { await loadPersonalOracle() }
                } label: {
                    HStack {
                        Image(systemName: "wand.and.stars")
                        Text("Generate Your Oracle Reading")
                    }
                    .font(.subheadline)
                    .foregroundColor(.yellow)
                    .padding(.vertical, 8)
                }
            }
            
            // Refresh button
            if personalOracle != nil && !isLoadingPersonalOracle {
                Button {
                    Task { await refreshPersonalOracle() }
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh Oracle")
                    }
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.yellow.opacity(0.15), Color.orange.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
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
    @AppStorage("userBirthTime") private var userBirthTimeTimestamp: Double = 0
    @AppStorage("userBirthPlace") private var savedBirthPlace: String = ""
    @AppStorage("userName") private var userName: String = ""
    
    @State private var selectedSign: ZodiacSign = .aries
    @State private var hasBirthday = false
    @State private var birthday = Date()
    @State private var hasBirthTime = false
    @State private var birthTime = Date()
    @State private var birthPlace = ""
    @State private var coordinates: CLLocationCoordinate2D? = nil
    @State private var name = ""
    @State private var showingContactPicker = false
    @State private var showingLocationSearch = false
    
    @StateObject private var locationCompleter = LocationSearchCompleter()
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
                
                Section {
                    Toggle("I know my birthday", isOn: $hasBirthday)
                    if hasBirthday {
                        DatePicker("Birthday", selection: $birthday, displayedComponents: .date)
                            .onChange(of: birthday) { _, newDate in
                                selectedSign = ZodiacSign.from(birthday: newDate)
                            }
                    }
                } header: {
                    Text("Birthday")
                }
                
                Section {
                    Toggle("I know my birth time", isOn: $hasBirthTime)
                    if hasBirthTime {
                        DatePicker("Birth Time", selection: $birthTime, displayedComponents: .hourAndMinute)
                    }
                    
                    // Birth Place with search
                    Button {
                        showingLocationSearch = true
                    } label: {
                        HStack {
                            Text("Birth City")
                                .foregroundColor(.primary)
                            Spacer()
                            if birthPlace.isEmpty {
                                Text("Search...")
                                    .foregroundColor(.secondary)
                            } else {
                                Text(birthPlace)
                                    .foregroundColor(.purple)
                                    .lineLimit(1)
                            }
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    if let coords = coordinates {
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(.purple)
                                .font(.caption)
                            Text(formatCoordinates(coords))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            if !birthPlace.isEmpty {
                                Button {
                                    birthPlace = ""
                                    coordinates = nil
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                } header: {
                    Text("Advanced (Optional)")
                } footer: {
                    Text("Adding birth time and place enables Moon & Rising sign for deeper readings.")
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
                        userBirthTimeTimestamp = hasBirthTime ? birthTime.timeIntervalSince1970 : 0
                        savedBirthPlace = birthPlace
                        userName = name
                        dismiss()
                    }
                }
            }
            .onAppear {
                selectedSign = userSign
                name = userName
                birthPlace = savedBirthPlace
                if userBirthdayTimestamp > 0 {
                    hasBirthday = true
                    birthday = Date(timeIntervalSince1970: userBirthdayTimestamp)
                }
                if userBirthTimeTimestamp > 0 {
                    hasBirthTime = true
                    birthTime = Date(timeIntervalSince1970: userBirthTimeTimestamp)
                }
                if !birthPlace.isEmpty {
                    geocodeExistingPlace(birthPlace)
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
            .sheet(isPresented: $showingLocationSearch) {
                LocationSearchView(
                    selectedPlace: $birthPlace,
                    coordinates: $coordinates,
                    completer: locationCompleter
                )
            }
        }
    }
    
    private func geocodeExistingPlace(_ place: String) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(place) { placemarks, _ in
            if let location = placemarks?.first?.location {
                self.coordinates = location.coordinate
            }
        }
    }
    
    private func formatCoordinates(_ coord: CLLocationCoordinate2D) -> String {
        let latDirection = coord.latitude >= 0 ? "N" : "S"
        let lonDirection = coord.longitude >= 0 ? "E" : "W"
        return String(format: "%.4f° %@, %.4f° %@",
                      abs(coord.latitude), latDirection,
                      abs(coord.longitude), lonDirection)
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
    @AppStorage("userZodiacSign") private var savedUserSign: String = "Aries"
    @State private var messageText = ""
    @State private var messages: [ChatMessage] = []
    @State private var isTyping = false
    @State private var currentTopic: AstrologyTopic = .general
    @State private var showFollowUps = false
    @FocusState private var isTextFieldFocused: Bool
    
    // Topic categories for follow-up suggestions
    enum AstrologyTopic {
        case general, compatibility, horoscope, planets, signs, houses, transits
        
        var followUpQuestions: [String] {
            switch self {
            case .general:
                return [
                    "What's my horoscope for today?",
                    "Tell me about my zodiac sign",
                    "What moon phase are we in?"
                ]
            case .compatibility:
                return [
                    "What signs am I most compatible with?",
                    "How do our moon signs affect compatibility?",
                    "What makes a good zodiac match?"
                ]
            case .horoscope:
                return [
                    "What about my love life this week?",
                    "How's my career looking?",
                    "What should I focus on today?"
                ]
            case .planets:
                return [
                    "What does Venus represent?",
                    "How does Mars affect my energy?",
                    "What is Saturn return?"
                ]
            case .signs:
                return [
                    "What are the fire signs like?",
                    "Tell me about water sign emotions",
                    "What makes earth signs grounded?"
                ]
            case .houses:
                return [
                    "What does my 7th house represent?",
                    "Which house rules career?",
                    "What is the 12th house about?"
                ]
            case .transits:
                return [
                    "When is the next Mercury retrograde?",
                    "How do full moons affect me?",
                    "What transits are happening now?"
                ]
            }
        }
    }
    
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
                            
                            // Follow-up suggestions after AI response
                            if showFollowUps && !messages.isEmpty && !isTyping {
                                followUpSuggestions
                                    .transition(.opacity.combined(with: .move(edge: .bottom)))
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
                        Button {
                            withAnimation {
                                messages.removeAll()
                                currentTopic = .general
                                showFollowUps = false
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.bubble")
                                Text("New")
                                    .font(.caption)
                            }
                            .foregroundColor(.purple)
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
            
            // Categorized suggestions
            VStack(alignment: .leading, spacing: 16) {
                suggestionCategory("🔮 Your Horoscope", questions: [
                    "What does my horoscope say today?",
                    "What's in store for me this week?"
                ])
                
                suggestionCategory("💕 Compatibility", questions: [
                    "Am I compatible with a Leo?",
                    "What signs match with \(savedUserSign)?"
                ])
                
                suggestionCategory("🌙 Moon & Planets", questions: [
                    "What moon phase are we in?",
                    "What does Mercury retrograde mean?"
                ])
                
                suggestionCategory("⭐ Birth Chart", questions: [
                    "Explain my rising sign",
                    "What does my sun sign mean?"
                ])
            }
        }
    }
    
    private func suggestionCategory(_ title: String, questions: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
                .padding(.leading, 4)
            
            ForEach(questions, id: \.self) { question in
                searchSuggestionButton(question)
            }
        }
    }
    
    private var followUpSuggestions: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Continue exploring:")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
                Spacer()
            }
            
            FlowLayout(spacing: 8) {
                ForEach(currentTopic.followUpQuestions, id: \.self) { question in
                    Button { sendMessage(question) } label: {
                        Text(question)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.purple.opacity(0.3))
                            .cornerRadius(16)
                    }
                }
            }
        }
        .padding(.top, 8)
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
    
    private func detectTopic(from query: String) -> AstrologyTopic {
        let lowercased = query.lowercased()
        
        if lowercased.contains("compatible") || lowercased.contains("match") || lowercased.contains("relationship") {
            return .compatibility
        } else if lowercased.contains("horoscope") || lowercased.contains("today") || lowercased.contains("week") || lowercased.contains("forecast") {
            return .horoscope
        } else if lowercased.contains("mercury") || lowercased.contains("venus") || lowercased.contains("mars") || lowercased.contains("saturn") || lowercased.contains("jupiter") || lowercased.contains("planet") {
            return .planets
        } else if lowercased.contains("sign") || lowercased.contains("aries") || lowercased.contains("taurus") || lowercased.contains("gemini") || lowercased.contains("cancer") || lowercased.contains("leo") || lowercased.contains("virgo") || lowercased.contains("libra") || lowercased.contains("scorpio") || lowercased.contains("sagittarius") || lowercased.contains("capricorn") || lowercased.contains("aquarius") || lowercased.contains("pisces") {
            return .signs
        } else if lowercased.contains("house") || lowercased.contains("ascendant") || lowercased.contains("rising") {
            return .houses
        } else if lowercased.contains("retrograde") || lowercased.contains("transit") || lowercased.contains("moon phase") || lowercased.contains("full moon") || lowercased.contains("new moon") {
            return .transits
        }
        return .general
    }
    
    private func sendMessage(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = ChatMessage(content: text, isUser: true)
        messages.append(userMessage)
        messageText = ""
        isTextFieldFocused = false
        showFollowUps = false
        
        // Detect topic for follow-up suggestions
        currentTopic = detectTopic(from: text)
        
        isTyping = true
        
        // Use Gemini AI for dynamic responses
        Task {
            let response = await generateAIResponse(for: text)
            await MainActor.run {
                isTyping = false
                let aiMessage = ChatMessage(content: response, isUser: false)
                messages.append(aiMessage)
                
                // Show follow-up suggestions after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        showFollowUps = true
                    }
                }
            }
        }
    }
    
    private func generateAIResponse(for query: String) async -> String {
        // Build context with user's sign and current celestial info
        let userSign = ZodiacSign(rawValue: savedUserSign) ?? .aries
        let moonPhase = MoonPhase.current()
        let moonSign = MoonSign.current()
        
        let prompt = """
        You are "The Oracle of Stars", a wise, warm, and poetic astrologer.
        
        IMPORTANT RULES:
        - ONLY answer questions about astrology, zodiac signs, horoscopes, planets, birth charts, compatibility, moon phases, and celestial events.
        - If the question is NOT about astrology, kindly redirect: "I specialize in the celestial arts. Ask me about your horoscope, zodiac compatibility, planets, or birth chart!"
        - Keep responses concise (2-3 paragraphs max).
        - Be mystical yet accessible, warm and insightful.
        - Reference the current celestial context when relevant.
        
        Current celestial context:
        - Moon Phase: \(moonPhase.rawValue) \(moonPhase.emoji)
        - Moon Sign: \(moonSign.rawValue) - \(moonSign.emotionalFlavor)
        - User's Sun Sign: \(userSign.rawValue) \(userSign.emoji)
        
        User's question: \(query)
        
        Respond with astrological wisdom and practical guidance.
        """
        
        do {
            let response = try await GeminiService.shared.askQuestion(prompt: prompt)
            return response
        } catch {
            print("❌ Gemini Ask error: \(error)")
            // Fallback to local response
            return generateLocalResponse(for: query)
        }
    }
    
    private func generateLocalResponse(for query: String) -> String {
        let lowercased = query.lowercased()
        let moonPhase = MoonPhase.current()
        let moonSign = MoonSign.current()
        
        if lowercased.contains("horoscope") || lowercased.contains("today") {
            return "Based on the current celestial alignments, today is a wonderful day for reflection and connection. The Moon in \(moonSign.rawValue) brings \(moonSign.emotionalFlavor) energy. \(moonPhase.guidance)"
        } else if lowercased.contains("compatible") || lowercased.contains("compatibility") {
            return "Compatibility in astrology goes beyond just sun signs! For a complete picture, we look at Moon signs for emotional compatibility, Venus for love styles, and Mars for passion. Would you like to learn more about any specific pairing?"
        } else if lowercased.contains("mercury retrograde") {
            return "Mercury retrograde is when Mercury appears to move backward in the sky. It's associated with communication mishaps, technology glitches, and revisiting the past. It's actually a great time for reflection, reviewing plans, and reconnecting with old friends—just be extra careful with contracts and travel plans!"
        } else if lowercased.contains("rising") || lowercased.contains("ascendant") {
            return "Your Rising sign (or Ascendant) represents how you appear to others and your outward personality. It's determined by the zodiac sign that was rising on the eastern horizon at your exact time of birth."
        } else if lowercased.contains("moon sign") {
            return "Your Moon sign represents your emotional nature, inner self, and subconscious patterns. It reveals how you process feelings, what makes you feel secure, and your instinctive reactions."
        } else if lowercased.contains("love") || lowercased.contains("relationship") {
            return "Love and relationships are deeply influenced by Venus and Mars in your chart. The current \(moonPhase.rawValue) is a beautiful time for \(moonPhase.emotionalTone) connections. Trust your heart's wisdom."
        } else {
            return "The stars whisper their secrets to those who listen. With the Moon in \(moonSign.rawValue) and the \(moonPhase.rawValue) illuminating our path, this is a powerful time for insight. What specifically draws your curiosity?"
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

// MARK: - Flow Layout for Follow-up Suggestions
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return CGSize(width: proposal.width ?? 0, height: result.height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            let point = result.positions[index]
            subview.place(at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var positions: [CGPoint] = []
        var height: CGFloat = 0
        
        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > width && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }
            
            height = y + rowHeight
        }
    }
}

// MARK: - Quick Stat Badge Component
struct QuickStatBadge: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Text(icon)
                .font(.title2)
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
                .lineLimit(1)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(width: 75, height: 85)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
}

// MARK: - Energy Meter Component
struct EnergyMeter: View {
    let icon: String
    let label: String
    let value: Double // 0.0 to 1.0
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.title3)
            
            Text(label)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 60, alignment: .leading)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)
                    
                    // Filled portion
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.6)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * value, height: 8)
                }
            }
            .frame(height: 8)
            
            Text("\(Int(value * 100))%")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
                .frame(width: 40, alignment: .trailing)
        }
    }
}

// MARK: - ZodiacSign Element Emoji Extension
extension ZodiacSign {
    var elementEmoji: String {
        switch element {
        case "Fire": return "🔥"
        case "Earth": return "🌍"
        case "Air": return "💨"
        case "Water": return "💧"
        default: return "✨"
        }
    }
}
