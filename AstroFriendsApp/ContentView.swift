import SwiftUI
import SwiftData

// ContactsView is the same as ContentView (for tab bar)
typealias ContactsView = ContentView

// MARK: - Cosmic Theme Colors
struct CosmicTheme {
    static let background = LinearGradient(
        colors: [Color(red: 0.05, green: 0.05, blue: 0.12), Color(red: 0.08, green: 0.04, blue: 0.18)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let cardBackground = Color.white.opacity(0.08)
    static let cardBackgroundSolid = Color(red: 0.12, green: 0.1, blue: 0.2)
    
    static let accent = Color(red: 0.6, green: 0.4, blue: 1.0) // Purple
    static let accentOrange = Color(red: 1.0, green: 0.5, blue: 0.3)
    
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)
    static let textMuted = Color.white.opacity(0.5)
}

// MARK: - Scroll Offset Preference Key
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Contact.name) private var contacts: [Contact]
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("zodiacOrder") private var zodiacOrderData: Data = Data()
    
    @State private var showingAddContact = false
    @State private var searchText = ""
    @State private var isSearchActive = false
    @State private var selectedZodiacSign: ZodiacSign? = nil
    @State private var showingOnboarding = false
    @State private var isAddingFromOnboarding = false
    @State private var showingHoroscopeDetail = false
    @State private var selectedHoroscopeSign: ZodiacSign = .aries
    @State private var showingZodiacReorder = false
    @State private var scrollOffset: CGFloat = 0
    @State private var initialScrollOffset: CGFloat? = nil
    @State private var headerVisible: Bool = true
    @State private var hasScrolledAway: Bool = false
    
    // Get ordered zodiac signs (user can reorder)
    var orderedZodiacSigns: [ZodiacSign] {
        if let decoded = try? JSONDecoder().decode([ZodiacSign].self, from: zodiacOrderData), !decoded.isEmpty {
            return decoded.filter { !$0.isMissingInfo }
        }
        return ZodiacSign.realSigns
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
    
    // Header height - fully collapse to 0 when hidden
    private var headerHeight: CGFloat {
        headerVisible ? 44 : 0
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Cosmic background
                CosmicTheme.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Collapsible Header with icons
                    if headerVisible {
                        HStack(spacing: 14) {
                            Spacer()
                            
                            NavigationLink(destination: SettingsView()) {
                                Image(systemName: "gearshape")
                                    .font(.system(size: 18))
                                    .foregroundColor(CosmicTheme.textSecondary)
                            }
                            
                            Button {
                                isSearchActive.toggle()
                            } label: {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 18))
                                    .foregroundColor(isSearchActive ? CosmicTheme.accent : CosmicTheme.textSecondary)
                            }
                            
                            Button {
                                isAddingFromOnboarding = false
                                showingAddContact = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(CosmicTheme.accent)
                            }
                        }
                        .padding(.horizontal)
                        .frame(height: 44)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    ScrollView {
                        VStack(spacing: 0) {
                            // Invisible scroll tracker
                            Color.clear
                                .frame(height: 1)
                                .overlay(
                                    GeometryReader { geo in
                                        Color.clear
                                            .onChange(of: geo.frame(in: .global).minY) { _, newValue in
                                                if initialScrollOffset == nil {
                                                    initialScrollOffset = newValue
                                                }
                                                let offset = newValue - (initialScrollOffset ?? 0)
                                                scrollOffset = offset
                                                
                                                // Hide when scrolling down past threshold
                                                if offset < -30 && !hasScrolledAway {
                                                    withAnimation(.easeOut(duration: 0.25)) {
                                                        hasScrolledAway = true
                                                        headerVisible = false
                                                    }
                                                }
                                                
                                                // Show only when at top AND pulling down (overscroll)
                                                if offset > 15 && hasScrolledAway {
                                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                                        hasScrolledAway = false
                                                        headerVisible = true
                                                    }
                                                }
                                            }
                                            .onAppear {
                                                initialScrollOffset = geo.frame(in: .global).minY
                                            }
                                    }
                                )
                            
                            // Horoscope Card - Large featured card
                            HoroscopeCardView(
                                selectedSign: selectedZodiacSign,
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
                                    HStack(spacing: 8) {
                                        ZodiacFilterButton(
                                            title: "All",
                                            isSelected: selectedZodiacSign == nil,
                                            count: contacts.count
                                        ) {
                                            selectedZodiacSign = nil
                                        }
                                        
                                        ForEach(orderedZodiacSigns, id: \.self) { sign in
                                            ZodiacFilterButton(
                                                title: sign.rawValue,
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
                                        .foregroundColor(CosmicTheme.textMuted)
                                        .padding(8)
                                        .background(CosmicTheme.cardBackground)
                                        .clipShape(Circle())
                                }
                                .padding(.trailing)
                            }
                            .padding(.bottom, 8)
                            
                            // Contacts List
                            if filteredContacts.isEmpty {
                                EmptyStateView(hasContacts: !contacts.isEmpty)
                                    .padding(.top, 40)
                            } else {
                                LazyVStack(spacing: 8) {
                                    ForEach(filteredContacts) { contact in
                                        NavigationLink(destination: ContactDetailView(contact: contact)) {
                                            ContactRowView(contact: contact)
                                        }
                                        .buttonStyle(.plain)
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                withAnimation {
                                                    modelContext.delete(contact)
                                                }
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("")
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingAddContact) {
                AddContactView(isFromOnboarding: isAddingFromOnboarding)
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
        .preferredColorScheme(.dark)
    }
}

// MARK: - Horoscope Card View
struct HoroscopeCardView: View {
    let selectedSign: ZodiacSign?
    let onSignTap: (ZodiacSign) -> Void
    @State private var currentSignIndex = 0
    
    private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    
    var isCarouselMode: Bool {
        selectedSign == nil
    }
    
    var displayedSign: ZodiacSign {
        if let selected = selectedSign {
            return selected
        }
        return ZodiacSign.realSigns[currentSignIndex % ZodiacSign.realSigns.count]
    }
    
    var horoscope: Horoscope {
        Horoscope.getWeeklyHoroscope(for: displayedSign)
    }
    
    var moonPhase: MoonPhase {
        Horoscope.currentMoonPhase
    }
    
    var moonSign: MoonSign {
        Horoscope.currentMoonSign
    }
    
    var body: some View {
        Button {
            onSignTap(displayedSign)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                // Header with Moon Phase
                HStack {
                    Text("Weekly Horoscope")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    // Moon phase indicator
                    HStack(spacing: 4) {
                        Text(moonPhase.emoji)
                            .font(.caption)
                        Text(moonPhase.rawValue)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(8)
                }
                
                // Sign info
                HStack(alignment: .center, spacing: 12) {
                    Text(displayedSign.emoji)
                        .font(.system(size: 44))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(displayedSign.rawValue)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(displayedSign.dateRange)
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
                
                // Celestial context line
                Text("Moon in \(moonSign.rawValue) · \(moonSign.emotionalFlavor.capitalized)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                
                // Reading preview
                Text(horoscope.weeklyReading)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Footer
                HStack {
                    // Sign indicator dots (only in carousel mode)
                    if isCarouselMode {
                        HStack(spacing: 4) {
                            ForEach(0..<12, id: \.self) { index in
                                Circle()
                                    .fill(index == currentSignIndex ? Color.white : Color.white.opacity(0.3))
                                    .frame(width: 5, height: 5)
                            }
                        }
                    }
                    
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
                    colors: [Color(red: 0.4, green: 0.2, blue: 0.6), Color(red: 0.6, green: 0.3, blue: 0.5)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(20)
            .shadow(color: Color.purple.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(PlainButtonStyle())
        .onReceive(timer) { _ in
            if isCarouselMode {
                withAnimation(.easeInOut(duration: 0.5)) {
                    currentSignIndex = (currentSignIndex + 1) % ZodiacSign.realSigns.count
                }
            }
        }
        .onChange(of: selectedSign) { _, newValue in
            if let sign = newValue, let index = ZodiacSign.realSigns.firstIndex(of: sign) {
                currentSignIndex = index
            }
        }
    }
}

// MARK: - Horoscope Detail View
struct HoroscopeDetailView: View {
    let sign: ZodiacSign
    @Environment(\.dismiss) private var dismiss
    @State private var showingCompatibilitySign: ZodiacSign? = nil
    
    var horoscope: Horoscope {
        Horoscope.getWeeklyHoroscope(for: sign)
    }
    
    var moonPhase: MoonPhase {
        Horoscope.currentMoonPhase
    }
    
    var moonSign: MoonSign {
        Horoscope.currentMoonSign
    }
    
    var transits: [PlanetaryTransit] {
        Horoscope.currentTransits
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
                                .foregroundColor(.white)
                            
                            Text(sign.dateRange)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                            
                            HStack(spacing: 8) {
                                Label(sign.element, systemImage: sign.icon)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(elementColor(for: sign).opacity(0.3))
                                    .foregroundColor(elementColor(for: sign))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.bottom, 8)
                    
                    // Celestial Overview Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Celestial Influences")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                            Text(moonPhase.emoji)
                                .font(.title2)
                        }
                        
                        // Moon Phase & Sign
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Moon Phase")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                                Text(moonPhase.rawValue)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Moon in")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                                Text(moonSign.rawValue)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        Divider().background(Color.white.opacity(0.2))
                        
                        // Emotional Tone
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Emotional Tone")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                            Text("You may feel \(moonSign.emotionalFlavor) and \(moonPhase.emotionalTone).")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        
                        Divider().background(Color.white.opacity(0.2))
                        
                        // Celestial Insight
                        Text(Horoscope.celestialMessage(for: sign))
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                            .italic()
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        LinearGradient(
                            colors: [Color.indigo.opacity(0.3), Color.purple.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
                    
                    // Planetary Transits
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Planetary Transits")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        ForEach(transits.indices, id: \.self) { index in
                            let transit = transits[index]
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(transit.emoji)
                                        .font(.title3)
                                    Text("\(transit.planet) \(transit.aspect)")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                }
                                
                                Text(transit.description)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                                
                                Text("💡 \(transit.advice)")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.9))
                                    .padding(.top, 2)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(16)
                    
                    // Weekly Reading
                    VStack(alignment: .leading, spacing: 8) {
                        Text("This Week's Reading")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(horoscope.weeklyReading)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                        
                        if !horoscope.celestialInsight.isEmpty {
                            Divider()
                                .background(Color.white.opacity(0.2))
                                .padding(.vertical, 4)
                            
                            HStack(alignment: .top, spacing: 8) {
                                Text("✨")
                                Text(horoscope.celestialInsight)
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.9))
                                    .italic()
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(16)
                    
                    // Love & Career
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Love", systemImage: "heart.fill")
                                .font(.headline)
                                .foregroundColor(.pink)
                            
                            Text(horoscope.loveAdvice)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.pink.opacity(0.15))
                        .cornerRadius(16)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Career", systemImage: "briefcase.fill")
                                .font(.headline)
                                .foregroundColor(.cyan)
                            
                            Text(horoscope.careerAdvice)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.cyan.opacity(0.15))
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
                            .foregroundColor(.white)
                        
                        Button {
                            showingCompatibilitySign = horoscope.compatibility
                        } label: {
                            HStack(spacing: 12) {
                                Text(horoscope.compatibility.emoji)
                                    .font(.title)
                                
                                VStack(alignment: .leading) {
                                    Text(horoscope.compatibility.rawValue)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                    
                                    Text(horoscope.compatibility.dateRange)
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
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
            .navigationTitle("Horoscope")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(item: $showingCompatibilitySign) { compatSign in
            HoroscopeDetailView(sign: compatSign)
        }
    }
    
    func elementColor(for sign: ZodiacSign) -> Color {
        switch sign.element {
        case "Fire": return .orange
        case "Earth": return .green
        case "Air": return .purple
        case "Water": return .cyan
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
                .foregroundColor(CosmicTheme.accent)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.08))
        .cornerRadius(12)
    }
}

// MARK: - Zodiac Filter Button (Pill style, no emoji)
struct ZodiacFilterButton: View {
    let title: String
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                
                Text("\(count)")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isSelected ? Color.white.opacity(0.2) : Color.white.opacity(0.1))
                    .cornerRadius(8)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? CosmicTheme.accent : Color.white.opacity(0.08))
            .foregroundColor(isSelected ? .white : CosmicTheme.textSecondary)
            .cornerRadius(20)
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
                    colors: [Color(red: 0.05, green: 0.05, blue: 0.12), Color(red: 0.1, green: 0.05, blue: 0.2)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        Text("✨ Astro Friends ✨")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("Discover the stars in your social circle")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.7))
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
                            .foregroundColor(.white.opacity(0.6))
                        
                        Button(action: onContinue) {
                            Text("Get started")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [Color.purple, Color.indigo],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(16)
                                .shadow(color: Color.purple.opacity(0.4), radius: 10, x: 0, y: 5)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func introCard(title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            Text(description)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.1))
        .cornerRadius(20)
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
                .foregroundColor(.purple)
                .frame(width: 36, height: 36)
                .background(Color.purple.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.08))
        .cornerRadius(18)
    }
}
