import Foundation

// MARK: - Content Service
/// Unified service for fetching all content tiers
/// - Tier 1: Static (local)
/// - Tier 2: Weekly Global (Supabase - same for all users of a sign)
/// - Tier 3: Personalized (Supabase - unique per contact)
@MainActor
class ContentService: ObservableObject {
    static let shared = ContentService()
    
    @Published var isLoading = false
    @Published var lastError: String?
    
    // Local cache for weekly data (expires after 7 days)
    private var weeklyHoroscopeCache: [String: CachedWeeklyHoroscope] = [:]
    private var weeklySkyCache: WeeklySky?
    private var weeklySkyFetchDate: Date?
    
    private let cacheExpirationDays: Double = 7
    
    // MARK: - Tier 2: Weekly Horoscope (Per Sign)
    
    /// Fetch weekly horoscope for a zodiac sign
    /// Priority: Supabase → Fallback to static
    func getWeeklyHoroscope(for sign: ZodiacSign) async -> WeeklyHoroscope {
        // Check local cache first
        let cacheKey = "\(sign.rawValue.lowercased())_\(currentWeekKey)"
        if let cached = weeklyHoroscopeCache[cacheKey], !cached.isExpired {
            return cached.horoscope
        }
        
        // Try fetching from Supabase
        do {
            if let fetched = try await fetchWeeklyHoroscopeFromSupabase(sign: sign) {
                let horoscope = WeeklyHoroscope(from: fetched)
                weeklyHoroscopeCache[cacheKey] = CachedWeeklyHoroscope(horoscope: horoscope)
                return horoscope
            }
        } catch {
            print("⚠️ Failed to fetch Tier 2 horoscope for \(sign): \(error.localizedDescription)")
        }
        
        // Fallback to static Tier 1 content
        return WeeklyHoroscope.staticFallback(for: sign)
    }
    
    /// Fetch all 12 weekly horoscopes (for batch operations)
    func getAllWeeklyHoroscopes() async -> [ZodiacSign: WeeklyHoroscope] {
        var results: [ZodiacSign: WeeklyHoroscope] = [:]
        
        // Fetch all in parallel
        await withTaskGroup(of: (ZodiacSign, WeeklyHoroscope).self) { group in
            for sign in ZodiacSign.realSigns {
                group.addTask {
                    let horoscope = await self.getWeeklyHoroscope(for: sign)
                    return (sign, horoscope)
                }
            }
            
            for await (sign, horoscope) in group {
                results[sign] = horoscope
            }
        }
        
        return results
    }
    
    // MARK: - Tier 2: Weekly Sky
    
    /// Fetch current week's celestial context
    func getWeeklySky() async -> WeeklySky? {
        // Check cache
        if let cached = weeklySkyCache,
           let fetchDate = weeklySkyFetchDate,
           Date().timeIntervalSince(fetchDate) < cacheExpirationDays * 24 * 60 * 60 {
            return cached
        }
        
        // Fetch from Supabase
        do {
            if let sky = try await SupabaseService.shared.fetchCurrentWeeklySky() {
                weeklySkyCache = sky
                weeklySkyFetchDate = Date()
                return sky
            }
        } catch {
            print("⚠️ Failed to fetch WeeklySky: \(error.localizedDescription)")
        }
        
        // Try to generate fresh from API
        do {
            let sky = try await OracleManager.shared.getOrFetchWeeklySky()
            weeklySkyCache = sky
            weeklySkyFetchDate = Date()
            return sky
        } catch {
            print("⚠️ Failed to generate WeeklySky: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    // MARK: - Tier 3: Personal Oracle Content
    
    /// Fetch personalized oracle content for a contact
    /// Priority: Cached Supabase → Generate fresh → nil
    func getOracleContent(for contact: Contact) async -> OracleContent? {
        guard contact.astroCompletionLevel != .none else { return nil }
        
        // Try cached first
        do {
            if let cached = try await SupabaseService.shared.fetchOracleContent(contactId: contact.id) {
                return cached
            }
        } catch {
            print("⚠️ Cache miss for oracle content: \(error.localizedDescription)")
        }
        
        // Generate fresh
        do {
            return try await OracleManager.shared.generateOracleContent(for: contact)
        } catch {
            print("⚠️ Failed to generate oracle: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Compatibility
    
    /// Get overall compatibility (static, Tier 1)
    func getOverallCompatibility(userSign: ZodiacSign, contactSign: ZodiacSign) -> AstralCompatibility {
        return AstralCompatibility(person1Sign: userSign, person2Sign: contactSign)
    }
    
    /// Get "This Week" compatibility (dynamic, requires Full profiles)
    func getThisWeekCompatibility(
        userContact: Contact,
        otherContact: Contact
    ) async -> CompatibilityCache? {
        // Check feature unlock
        guard FeatureUnlock.canAccess(.thisWeekCompatibility, for: userContact) &&
              FeatureUnlock.canAccess(.thisWeekCompatibility, for: otherContact) else {
            return nil
        }
        
        // Try cached first
        do {
            if let cached = try await SupabaseService.shared.fetchCompatibility(
                contactA: userContact.id,
                contactB: otherContact.id
            ) {
                return cached
            }
        } catch {
            print("⚠️ Cache miss for compatibility: \(error.localizedDescription)")
        }
        
        // Generate fresh
        do {
            let userOracle = try? await SupabaseService.shared.fetchOracleContent(contactId: userContact.id)
            let otherOracle = try? await SupabaseService.shared.fetchOracleContent(contactId: otherContact.id)
            
            return try await OracleManager.shared.generateWeeklyCompatibility(
                contactA: userContact,
                contactB: otherContact,
                oracleA: userOracle,
                oracleB: otherOracle
            )
        } catch {
            print("⚠️ Failed to generate weekly compatibility: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Cache Management
    
    /// Clear all caches (useful for refresh)
    func clearCache() {
        weeklyHoroscopeCache.removeAll()
        weeklySkyCache = nil
        weeklySkyFetchDate = nil
    }
    
    /// Force refresh weekly content
    func refreshWeeklyContent() async {
        clearCache()
        _ = await getWeeklySky()
        _ = await getAllWeeklyHoroscopes()
    }
    
    // MARK: - Private Helpers
    
    private var currentWeekKey: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        let weekStart = getWeekStart(from: Date())
        return formatter.string(from: weekStart)
    }
    
    private func getWeekStart(from date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components) ?? date
    }
    
    private func fetchWeeklyHoroscopeFromSupabase(sign: ZodiacSign) async throws -> WeeklyHoroscopeDB? {
        let weekStart = getWeekStart(from: Date())
        let dateString = ISO8601DateFormatter().string(from: weekStart)
        let signStr = sign.rawValue.lowercased()
        
        let endpoint = "\(Secrets.Supabase.projectURL)/rest/v1/weekly_horoscopes?sign=eq.\(signStr)&week_start=eq.\(dateString)"
        
        guard let url = URL(string: endpoint) else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(Secrets.Supabase.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(Secrets.Supabase.anonKey)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        
        let results = try decoder.decode([WeeklyHoroscopeDB].self, from: data)
        return results.first
    }
}

// MARK: - Weekly Horoscope Models

/// Supabase row for weekly_horoscopes table
struct WeeklyHoroscopeDB: Codable {
    let id: UUID?
    let sign: String
    let weekStart: Date
    let weeklyReading: String
    let mood: String
    let luckyNumber: Int?
    let luckyColor: String?
    let loveForecast: String?
    let careerForecast: String?
    let healthTip: String?
    let powerDay: String?
    let challengeDay: String?
    let affirmation: String?
}

/// App-facing weekly horoscope (unified Tier 1 + Tier 2)
struct WeeklyHoroscope {
    let sign: ZodiacSign
    let weeklyReading: String
    let mood: String
    let luckyNumber: Int
    let luckyColor: String
    let loveForecast: String?
    let careerForecast: String?
    let healthTip: String?
    let powerDay: String?
    let challengeDay: String?
    let affirmation: String?
    let isAIGenerated: Bool
    
    /// Memberwise initializer
    init(
        sign: ZodiacSign,
        weeklyReading: String,
        mood: String,
        luckyNumber: Int,
        luckyColor: String,
        loveForecast: String? = nil,
        careerForecast: String? = nil,
        healthTip: String? = nil,
        powerDay: String? = nil,
        challengeDay: String? = nil,
        affirmation: String? = nil,
        isAIGenerated: Bool
    ) {
        self.sign = sign
        self.weeklyReading = weeklyReading
        self.mood = mood
        self.luckyNumber = luckyNumber
        self.luckyColor = luckyColor
        self.loveForecast = loveForecast
        self.careerForecast = careerForecast
        self.healthTip = healthTip
        self.powerDay = powerDay
        self.challengeDay = challengeDay
        self.affirmation = affirmation
        self.isAIGenerated = isAIGenerated
    }
    
    /// Create from Supabase data (Tier 2)
    init(from db: WeeklyHoroscopeDB) {
        self.sign = ZodiacSign(rawValue: db.sign.capitalized) ?? .unknown
        self.weeklyReading = db.weeklyReading
        self.mood = db.mood
        self.luckyNumber = db.luckyNumber ?? Int.random(in: 1...99)
        self.luckyColor = db.luckyColor ?? "Purple"
        self.loveForecast = db.loveForecast
        self.careerForecast = db.careerForecast
        self.healthTip = db.healthTip
        self.powerDay = db.powerDay
        self.challengeDay = db.challengeDay
        self.affirmation = db.affirmation
        self.isAIGenerated = true
    }
    
    /// Static fallback (Tier 1)
    static func staticFallback(for sign: ZodiacSign) -> WeeklyHoroscope {
        let horoscope = Horoscope.getWeeklyHoroscope(for: sign)
        return WeeklyHoroscope(
            sign: sign,
            weeklyReading: horoscope.weeklyReading,
            mood: horoscope.mood,
            luckyNumber: horoscope.luckyNumber,
            luckyColor: horoscope.luckyColor,
            isAIGenerated: false
        )
    }
}

/// Local cache wrapper with expiration
struct CachedWeeklyHoroscope {
    let horoscope: WeeklyHoroscope
    let fetchDate: Date
    
    init(horoscope: WeeklyHoroscope) {
        self.horoscope = horoscope
        self.fetchDate = Date()
    }
    
    var isExpired: Bool {
        Date().timeIntervalSince(fetchDate) > 7 * 24 * 60 * 60
    }
}

// MARK: - Feature Unlock System

/// Defines which features are available at each completion level
enum AstroFeature: String, CaseIterable {
    case sunSignTraits = "Sun Sign Traits"
    case basicHoroscope = "Basic Horoscope"
    case overallCompatibility = "Overall Compatibility"
    case weeklyHoroscope = "Weekly Horoscope"
    case moonSignInsights = "Moon Sign Insights"
    case personalOracle = "Personal Oracle"
    case risingSign = "Rising Sign"
    case thisWeekCompatibility = "This Week Compatibility"
    case synastry = "Synastry Insights"
    case liveCompatibility = "Live Compatibility"
    
    /// Minimum completion level required
    var requiredLevel: AstroCompletionLevel {
        switch self {
        case .sunSignTraits, .basicHoroscope, .overallCompatibility, .weeklyHoroscope:
            return .basic
        case .moonSignInsights, .personalOracle:
            return .extended
        case .risingSign, .thisWeekCompatibility, .synastry, .liveCompatibility:
            return .full
        }
    }
    
    /// Data source for this feature
    var source: ContentSource {
        switch self {
        case .sunSignTraits, .overallCompatibility:
            return .local
        case .basicHoroscope, .weeklyHoroscope:
            return .tier2Supabase
        case .moonSignInsights, .personalOracle, .thisWeekCompatibility, .liveCompatibility:
            return .tier3Gemini
        case .risingSign, .synastry:
            return .astrologyAPI
        }
    }
    
    /// Icon for this feature
    var icon: String {
        switch self {
        case .sunSignTraits: return "sun.max.fill"
        case .basicHoroscope: return "book.fill"
        case .overallCompatibility: return "heart.fill"
        case .weeklyHoroscope: return "calendar"
        case .moonSignInsights: return "moon.fill"
        case .personalOracle: return "sparkles"
        case .risingSign: return "arrow.up.circle.fill"
        case .thisWeekCompatibility: return "calendar.badge.clock"
        case .synastry: return "link"
        case .liveCompatibility: return "waveform.path.ecg"
        }
    }
}

enum ContentSource: String {
    case local = "Local"
    case tier2Supabase = "Supabase (Tier 2)"
    case tier3Gemini = "Gemini AI (Tier 3)"
    case astrologyAPI = "AstrologyAPI"
}

/// Feature unlock logic
struct FeatureUnlock {
    
    /// Check if a feature is accessible for a contact
    static func canAccess(_ feature: AstroFeature, for contact: Contact) -> Bool {
        return contact.astroCompletionLevel.rawSortValue >= feature.requiredLevel.rawSortValue
    }
    
    /// Get all unlocked features for a contact
    static func unlockedFeatures(for contact: Contact) -> [AstroFeature] {
        AstroFeature.allCases.filter { canAccess($0, for: contact) }
    }
    
    /// Get all locked features for a contact
    static func lockedFeatures(for contact: Contact) -> [AstroFeature] {
        AstroFeature.allCases.filter { !canAccess($0, for: contact) }
    }
    
    /// Get the next unlock if user adds more data
    static func nextUnlocks(for contact: Contact) -> [(feature: AstroFeature, requirement: String)] {
        let level = contact.astroCompletionLevel
        var unlocks: [(AstroFeature, String)] = []
        
        switch level {
        case .none:
            unlocks.append((.sunSignTraits, "Add birthday"))
            unlocks.append((.basicHoroscope, "Add birthday"))
            unlocks.append((.overallCompatibility, "Add birthday"))
        case .basic:
            unlocks.append((.moonSignInsights, "Add birth time or place"))
            unlocks.append((.personalOracle, "Add birth time or place"))
        case .extended:
            unlocks.append((.risingSign, "Add both birth time and place"))
            unlocks.append((.thisWeekCompatibility, "Add both birth time and place"))
        case .full:
            break // All unlocked
        }
        
        return unlocks
    }
}

// MARK: - Completion Level Sort Value

extension AstroCompletionLevel {
    var rawSortValue: Int {
        switch self {
        case .none: return 0
        case .basic: return 1
        case .extended: return 2
        case .full: return 3
        }
    }
}

