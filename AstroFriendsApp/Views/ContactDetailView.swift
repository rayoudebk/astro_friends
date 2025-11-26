import SwiftUI
import SwiftData

struct ContactDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var contact: Contact
    @StateObject private var oracleManager = OracleManager.shared
    
    @State private var showingEditSheet = false
    @State private var showingHoroscope = false
    @State private var showingCompatibility = false
    @State private var oracleContent: OracleContent?
    @State private var isLoadingOracle = false
    @State private var oracleError: String?
    @AppStorage("userZodiacSign") private var userZodiacSign: String = "Aries"
    
    var userSign: ZodiacSign {
        ZodiacSign(rawValue: userZodiacSign) ?? .aries
    }
    
    var compatibility: AstralCompatibility {
        AstralCompatibility(person1Sign: userSign, person2Sign: contact.zodiacSign)
    }
    
    // Fallback to local horoscope if no oracle content
    var horoscope: Horoscope {
        Horoscope.getWeeklyHoroscope(for: contact.zodiacSign)
    }
    
    // Use oracle content if available, else fallback
    var displayReading: String {
        oracleContent?.weeklyReading ?? horoscope.weeklyReading
    }
    
    var displayMood: String {
        oracleContent?.mood ?? horoscope.mood
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Card
                contactHeaderCard
                
                // Zodiac & Horoscope Card
                zodiacCard
                
                // Compatibility Card
                compatibilityCard
                
                // Contact Info
                if contact.phoneNumber != nil || contact.email != nil || contact.birthday != nil || contact.birthTime != nil || contact.birthPlace != nil {
                    contactInfoSection
                }
                
                // Notes
                if !contact.notes.isEmpty {
                    notesSection
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
        .navigationTitle(contact.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button {
                        contact.isFavorite.toggle()
                    } label: {
                        Label(contact.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                              systemImage: contact.isFavorite ? "star.slash" : "star")
                    }
                    
                    Button(role: .destructive) {
                        modelContext.delete(contact)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.white)
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditContactView(contact: contact)
        }
        .sheet(isPresented: $showingHoroscope) {
            HoroscopeDetailView(sign: contact.zodiacSign, oracleContent: oracleContent)
        }
        .sheet(isPresented: $showingCompatibility) {
            CompatibilityView(contact: contact)
        }
        .preferredColorScheme(.dark)
        .task {
            await loadOracleContent()
        }
    }
    
    // MARK: - Oracle Loading
    
    private func loadOracleContent() async {
        guard !contact.zodiacSign.isMissingInfo else { return }
        
        isLoadingOracle = true
        oracleError = nil
        
        // Try to fetch cached content first
        if let cached = try? await SupabaseService.shared.fetchOracleContent(contactId: contact.id) {
            oracleContent = cached
            isLoadingOracle = false
            return
        }
        
        // No cached content - auto-generate
        do {
            oracleContent = try await OracleManager.shared.generateOracleContent(for: contact)
        } catch {
            oracleError = error.localizedDescription
        }
        
        isLoadingOracle = false
    }
    
    private func generateFreshOracle() async {
        isLoadingOracle = true
        oracleError = nil
        
        do {
            oracleContent = try await OracleManager.shared.generateOracleContent(for: contact)
        } catch {
            oracleError = error.localizedDescription
        }
        
        isLoadingOracle = false
    }
    
    private var contactHeaderCard: some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack {
                if let imageData = contact.profileImageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [elementColor(for: contact.zodiacSign), elementColor(for: contact.zodiacSign).opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 3
                                )
                        )
                } else {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [elementColor(for: contact.zodiacSign).opacity(0.4), elementColor(for: contact.zodiacSign).opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                    
                    Text(contact.name.prefix(1).uppercased())
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .foregroundColor(elementColor(for: contact.zodiacSign))
                }
            }
            
            // Name
            VStack(spacing: 8) {
                HStack {
                    Text(contact.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    if contact.isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                    }
                }
                
                // Zodiac badge
                HStack(spacing: 6) {
                    if contact.zodiacSign.isMissingInfo {
                        Image(systemName: "questionmark.circle")
                        Text("Missing Info")
                            .fontWeight(.medium)
                    } else {
                        Text(contact.zodiacSign.emoji)
                        Text(contact.zodiacSign.rawValue)
                            .fontWeight(.medium)
                        Text("•")
                            .foregroundColor(.white.opacity(0.4))
                        Text(contact.zodiacSign.element)
                            .foregroundColor(elementColor(for: contact.zodiacSign))
                    }
                }
                .font(.subheadline)
                .foregroundColor(contact.zodiacSign.isMissingInfo ? .orange : .white.opacity(0.8))
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.08))
        .cornerRadius(20)
    }
    
    private var zodiacCard: some View {
        Group {
            if contact.zodiacSign.isMissingInfo {
                // Show prompt to add birthday
                Button {
                    showingEditSheet = true
                } label: {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "questionmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.orange)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Birthday Missing")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Text("Add birthday to see horoscope")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Text("Add")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.orange.opacity(0.3))
                                    .foregroundColor(.orange)
                                    .cornerRadius(8)
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                        
                        Text("Add their birthday to unlock their zodiac sign, horoscope, and compatibility readings.")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(2)
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.15), Color.orange.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
                }
                .buttonStyle(.plain)
            } else {
                VStack(spacing: 12) {
                    Button {
                        showingHoroscope = true
                    } label: {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(contact.zodiacSign.emoji)
                                    .font(.title)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 6) {
                                        Text("Weekly Horoscope")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        
                                        if oracleContent != nil {
                                            Image(systemName: "sparkles")
                                                .font(.caption)
                                                .foregroundColor(.yellow)
                                        }
                                    }
                                    
                                    Text(contact.zodiacSign.dateRange)
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                
                                Spacer()
                                
                                HStack(spacing: 4) {
                                    if !isLoadingOracle || oracleContent != nil {
                                        Text(displayMood)
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(elementColor(for: contact.zodiacSign).opacity(0.3))
                                            .foregroundColor(elementColor(for: contact.zodiacSign))
                                            .cornerRadius(8)
                                    }
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }
                            
                            if isLoadingOracle && oracleContent == nil {
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .tint(.white.opacity(0.5))
                                        .scaleEffect(0.8)
                                    Text("Consulting the stars...")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.5))
                                        .italic()
                                }
                            } else {
                                Text(displayReading)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                                    .lineLimit(2)
                            }
                            
                            // Show oracle extras if available
                            if let oracle = oracleContent {
                                HStack(spacing: 12) {
                                    if let lucky = oracle.luckyNumber {
                                        Label("\(lucky)", systemImage: "number")
                                            .font(.caption2)
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                    if let color = oracle.luckyColor {
                                        Label(color, systemImage: "paintpalette")
                                            .font(.caption2)
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                }
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
                        .cornerRadius(16)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Refresh option (only show when content exists)
                    if oracleContent != nil && !isLoadingOracle {
                        Button {
                            Task {
                                await generateFreshOracle()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Refresh Oracle")
                            }
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    
                    // Error display with retry
                    if let error = oracleError {
                        VStack(spacing: 8) {
                            Text(error)
                                .font(.caption2)
                                .foregroundColor(.red.opacity(0.8))
                            
                            Button {
                                Task {
                                    await generateFreshOracle()
                                }
                            } label: {
                                Text("Retry")
                                    .font(.caption)
                                    .foregroundColor(.purple)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
    }
    
    private var compatibilityCard: some View {
        Group {
            if contact.zodiacSign.isMissingInfo {
                // Show disabled state for missing info
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        HStack(spacing: -8) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [elementColor(for: userSign), elementColor(for: userSign).opacity(0.5)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 36, height: 36)
                                Text(userSign.emoji)
                                    .font(.title3)
                            }
                            
                            ZStack {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "questionmark")
                                    .font(.title3)
                                    .foregroundColor(.orange)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Compatibility")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.5))
                            
                            Text("Add birthday to unlock")
                                .font(.caption)
                                .foregroundColor(.orange.opacity(0.8))
                        }
                        
                        Spacer()
                    }
                }
                .padding()
                .background(Color.white.opacity(0.03))
                .cornerRadius(16)
            } else {
                Button {
                    showingCompatibility = true
                } label: {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            // Your sign + their sign
                            HStack(spacing: -8) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [elementColor(for: userSign), elementColor(for: userSign).opacity(0.5)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 36, height: 36)
                                    Text(userSign.emoji)
                                        .font(.title3)
                                }
                                
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [elementColor(for: contact.zodiacSign), elementColor(for: contact.zodiacSign).opacity(0.5)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 36, height: 36)
                                    Text(contact.zodiacSign.emoji)
                                        .font(.title3)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Your Compatibility")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Text("\(userSign.rawValue) + \(contact.zodiacSign.rawValue)")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            
                            Spacer()
                            
                            // Harmony badge
                            HStack(spacing: 4) {
                                Text(compatibility.harmonyLevel.emoji)
                                    .font(.caption)
                                Text("\(compatibility.harmonyScore)%")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(harmonyBadgeColor.opacity(0.3))
                    .foregroundColor(harmonyBadgeColor)
                    .cornerRadius(10)
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
                
                // Poetic summary preview
                Text(compatibility.poeticSummary)
                    .font(.caption)
                    .italic()
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
                
                // Harmony level description
                HStack {
                    Text(compatibility.harmonyLevel.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(harmonyBadgeColor)
                    
                    Text("•")
                        .foregroundColor(.white.opacity(0.3))
                    
                    Text("Tap to explore")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
            }
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [harmonyBadgeColor.opacity(0.15), Color.white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var harmonyBadgeColor: Color {
        switch compatibility.harmonyLevel {
        case .soulmates: return .yellow
        case .deepConnection: return .purple
        case .harmoniousFlow: return .cyan
        case .growthPartners: return .green
        case .dynamicTension: return .orange
        }
    }
    
    private var contactInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Contact Info")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                if let phone = contact.phoneNumber {
                    HStack {
                        Image(systemName: "phone.fill")
                            .foregroundColor(.green)
                            .frame(width: 24)
                        Text(phone)
                            .foregroundColor(.white.opacity(0.9))
                        Spacer()
                        
                        Link(destination: URL(string: "tel:\(phone.replacingOccurrences(of: " ", with: ""))")!) {
                            Image(systemName: "phone.arrow.up.right")
                                .foregroundColor(.purple)
                        }
                        
                        Link(destination: URL(string: "sms:\(phone.replacingOccurrences(of: " ", with: ""))")!) {
                            Image(systemName: "message.fill")
                                .foregroundColor(.purple)
                        }
                    }
                }
                
                if let email = contact.email {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.cyan)
                            .frame(width: 24)
                        Text(email)
                            .foregroundColor(.white.opacity(0.9))
                        Spacer()
                        
                        Link(destination: URL(string: "mailto:\(email)")!) {
                            Image(systemName: "arrow.up.right")
                                .foregroundColor(.purple)
                        }
                    }
                }
                
                if let birthday = contact.birthday {
                    HStack {
                        Image(systemName: "gift.fill")
                            .foregroundColor(.pink)
                            .frame(width: 24)
                        Text(birthday, style: .date)
                            .foregroundColor(.white.opacity(0.9))
                        Spacer()
                    }
                }
                
                if let birthTime = contact.birthTime {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.orange)
                            .frame(width: 24)
                        Text(birthTime, format: .dateTime.hour().minute())
                            .foregroundColor(.white.opacity(0.9))
                        Spacer()
                    }
                }
                
                if let birthPlace = contact.birthPlace, !birthPlace.isEmpty {
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.red)
                            .frame(width: 24)
                        Text(birthPlace)
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(2)
                        Spacer()
                    }
                }
            }
            .padding()
            .background(Color.white.opacity(0.08))
            .cornerRadius(16)
        }
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(.headline)
                .foregroundColor(.white)
            
            Text(contact.notes)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.08))
                .cornerRadius(16)
        }
    }
    
    private func elementColor(for sign: ZodiacSign) -> Color {
        switch sign.element {
        case "Fire": return .orange
        case "Earth": return .green
        case "Air": return .purple
        case "Water": return .cyan
        default: return .gray
        }
    }
}
