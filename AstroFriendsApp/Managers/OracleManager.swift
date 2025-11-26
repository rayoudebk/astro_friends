import Foundation
import CoreLocation

// MARK: - Oracle Manager
/// Orchestrates oracle content generation using Gemini AI
/// Falls back to local generation if APIs fail
@MainActor
class OracleManager: ObservableObject {
    static let shared = OracleManager()
    
    @Published var isLoading = false
    @Published var lastError: String?
    
    private let geocoder = CLGeocoder()
    
    // MARK: - Generate Oracle Content
    
    /// Main entry point - tries Gemini first, falls back to local if needed
    func generateOracleContent(for contact: Contact) async throws -> OracleContent {
        isLoading = true
        lastError = nil
        
        defer { isLoading = false }
        
        print("🔮 Generating oracle for: \(contact.name) (\(contact.id))")
        
        // Check cache first
        if let cached = try? await SupabaseService.shared.fetchOracleContent(contactId: contact.id) {
            print("✅ Found cached oracle")
            return cached
        }
        
        // Get zodiac sign
        let sign = contact.zodiacSign
        guard sign != .unknown else {
            throw OracleError.missingBirthData("Zodiac sign required")
        }
        
        // Build profile locally (no external API needed)
        let profile = buildLocalProfile(for: contact)
        print("✅ Built profile: \(profile.sunSign)")
        
        // Get weekly sky context locally
        let weeklySky = buildLocalWeeklySky()
        print("✅ Weekly sky: \(weeklySky.moonPhase)")
        
        // Try Gemini AI generation
        do {
            print("🤖 Calling Gemini...")
            let generated = try await GeminiService.shared.generateWeeklyOracle(
                profile: profile,
                weeklySky: weeklySky,
                contactName: contact.name
            )
            print("✅ Gemini returned content")
            
            let oracleContent = OracleContent(
                contactId: contact.id,
                weekStart: getWeekStart(from: Date()),
                weeklyReading: generated.reading,
                loveAdvice: generated.love,
                careerAdvice: generated.career,
                luckyNumber: generated.number,
                luckyColor: generated.color,
                mood: generated.mood,
                compatibilitySign: generated.bestMatch,
                celestialInsight: generated.insight
            )
            
            // Cache to Supabase (optional)
            if let saved = try? await SupabaseService.shared.upsertOracleContent(oracleContent) {
                return saved
            }
            return oracleContent
            
        } catch {
            print("⚠️ Gemini failed: \(error.localizedDescription)")
            print("📝 Falling back to local generation...")
            
            // Fallback to local generation
            return generateLocalOracle(for: contact, profile: profile, weeklySky: weeklySky)
        }
    }
    
    // MARK: - Build Local Profile (No API)
    
    private func buildLocalProfile(for contact: Contact) -> AstroProfile {
        let sunSign = contact.zodiacSign
        
        var moonSign: ZodiacSign? = nil
        var risingSign: ZodiacSign? = nil
        
        if let birthday = contact.birthday {
            let chart = NatalChart(
                birthDate: birthday,
                birthTime: contact.birthTime,
                birthPlace: contact.birthPlace
            )
            moonSign = chart.moonSign
            risingSign = chart.risingSign
        }
        
        return AstroProfile(
            contactId: contact.id,
            sunSign: sunSign,
            moonSign: moonSign,
            risingSign: risingSign,
            element: sunSign.element,
            modality: sunSign.modalityString
        )
    }
    
    // MARK: - Build Local Weekly Sky (No API)
    
    private func buildLocalWeeklySky() -> WeeklySky {
        let moonPhase = MoonPhase.current()
        let moonSign = MoonSign.current()
        
        return WeeklySky(
            weekStart: getWeekStart(from: Date()),
            moonPhase: moonPhase.rawValue,
            moonSign: moonSign.rawValue,
            transits: nil
        )
    }
    
    // MARK: - Local Oracle Fallback
    
    private func generateLocalOracle(
        for contact: Contact,
        profile: AstroProfile,
        weeklySky: WeeklySky
    ) -> OracleContent {
        let sign = contact.zodiacSign
        let horoscope = Horoscope.getWeeklyHoroscope(for: sign)
        let moonPhase = MoonPhase.current()
        let moonSign = MoonSign.current()
        
        // Build personalized reading
        var reading = horoscope.weeklyReading
        reading += "\n\nWith the \(moonPhase.rawValue) \(moonPhase.emoji) in the sky, you may feel \(moonPhase.emotionalTone). \(moonPhase.guidance)"
        reading += "\n\nThe Moon in \(moonSign.rawValue) adds \(moonSign.emotionalFlavor) to your emotional landscape."
        
        // Celestial insight
        let insight = "The \(moonPhase.rawValue) harmonizes with your \(sign.rawValue) energy, creating a powerful time for \(sign.element.lowercased()) sign activities."
        
        return OracleContent(
            contactId: contact.id,
            weekStart: getWeekStart(from: Date()),
            weeklyReading: reading,
            loveAdvice: horoscope.loveAdvice,
            careerAdvice: horoscope.careerAdvice,
            luckyNumber: horoscope.luckyNumber,
            luckyColor: horoscope.luckyColor,
            mood: horoscope.mood,
            compatibilitySign: horoscope.compatibility.rawValue,
            celestialInsight: insight
        )
    }
    
    // MARK: - Get or Create Astro Profile
    
    /// Fetches from Supabase or creates new from AstrologyAPI
    func getOrCreateAstroProfile(for contact: Contact) async throws -> AstroProfile {
        // Check cache first
        if let cached = try? await SupabaseService.shared.fetchAstroProfile(contactId: contact.id) {
            return cached
        }
        
        // Need to create - requires birth data
        guard let birthday = contact.birthday else {
            throw OracleError.missingBirthData("Birthday required")
        }
        
        // If we have full birth data, use AstrologyAPI
        if let birthPlace = contact.birthPlace, !birthPlace.isEmpty {
            return try await fetchFromAstrologyAPI(contact: contact, birthday: birthday, birthPlace: birthPlace)
        }
        
        // Otherwise, create basic profile from local calculation
        return await createBasicProfile(for: contact, birthday: birthday)
    }
    
    // MARK: - AstrologyAPI Flow (Full Chart)
    
    private func fetchFromAstrologyAPI(
        contact: Contact,
        birthday: Date,
        birthPlace: String
    ) async throws -> AstroProfile {
        // Geocode birth place
        let (latitude, longitude, timezone) = try await geocodeBirthPlace(birthPlace)
        
        // Fetch natal planets
        let planets = try await AstrologyAPIService.shared.fetchNatalPlanets(
            birthDate: birthday,
            birthTime: contact.birthTime,
            latitude: latitude,
            longitude: longitude,
            timezone: timezone
        )
        
        // Fetch house cusps for rising sign
        var risingSign: ZodiacSign? = nil
        if contact.birthTime != nil {
            let cusps = try? await AstrologyAPIService.shared.fetchHouseCusps(
                birthDate: birthday,
                birthTime: contact.birthTime,
                latitude: latitude,
                longitude: longitude,
                timezone: timezone
            )
            risingSign = cusps?.risingSign
        }
        
        // Create profile with API data
        let sunSign = planets.sunSign ?? contact.zodiacSign
        let moonSign = planets.moonSign
        
        let profile = AstroProfile(
            contactId: contact.id,
            sunSign: sunSign,
            moonSign: moonSign,
            risingSign: risingSign,
            element: sunSign.element,
            modality: sunSign.modalityString
        )
        
        // Try to save to Supabase (but don't fail if it doesn't work)
        do {
            return try await SupabaseService.shared.upsertAstroProfile(profile)
        } catch {
            print("⚠️ Failed to save profile to Supabase: \(error.localizedDescription)")
            return profile
        }
    }
    
    // MARK: - Basic Profile (Local Calculation)
    
    private func createBasicProfile(for contact: Contact, birthday: Date) async -> AstroProfile {
        let sunSign = ZodiacSign.from(birthday: birthday)
        
        // Use local NatalChart for moon calculation
        let natalChart = NatalChart(
            birthDate: birthday,
            birthTime: contact.birthTime,
            birthPlace: contact.birthPlace
        )
        
        let profile = AstroProfile(
            contactId: contact.id,
            sunSign: sunSign,
            moonSign: natalChart.moonSign,
            risingSign: natalChart.risingSign,
            element: sunSign.element,
            modality: sunSign.modalityString
        )
        
        print("✅ Created local profile: \(sunSign.rawValue), moon: \(natalChart.moonSign.rawValue)")
        
        // Try to save to Supabase (but don't fail if it doesn't work)
        do {
            return try await SupabaseService.shared.upsertAstroProfile(profile)
        } catch {
            print("⚠️ Failed to save profile to Supabase: \(error.localizedDescription)")
            return profile
        }
    }
    
    // MARK: - Weekly Sky
    
    func getOrFetchWeeklySky() async throws -> WeeklySky {
        // Check cache
        if let cached = try? await SupabaseService.shared.fetchCurrentWeeklySky() {
            return cached
        }
        
        // Try to fetch from AstrologyAPI, but fall back to local calculation
        var moonPhaseName = "Waxing Crescent" // Default
        var transitsArray: [String]? = nil
        
        do {
            let moonPhase = try await AstrologyAPIService.shared.fetchMoonPhase()
            moonPhaseName = moonPhase.phaseName ?? moonPhase.moonPhase ?? "Waxing Crescent"
            print("✅ Got moon phase from API: \(moonPhaseName)")
        } catch {
            // Use local calculation as fallback
            let currentPhase = MoonPhase.current()
            moonPhaseName = currentPhase.rawValue
            print("⚠️ AstrologyAPI failed, using local moon phase: \(moonPhaseName)")
        }
        
        // Try to get transits (optional)
        if let transits = try? await AstrologyAPIService.shared.fetchWeeklyTransits() {
            transitsArray = transits.transits?.compactMap { transit in
                guard let planet = transit.transitingPlanet,
                      let aspect = transit.aspect else { return nil }
                return "\(planet) \(aspect)"
            }
        }
        
        let sky = WeeklySky(
            weekStart: getWeekStart(from: Date()),
            moonPhase: moonPhaseName,
            moonSign: nil,
            transits: transitsArray
        )
        
        // Try to save to Supabase, but don't fail if it doesn't work
        do {
            return try await SupabaseService.shared.upsertWeeklySky(sky)
        } catch {
            print("⚠️ Failed to save weekly sky to Supabase: \(error.localizedDescription)")
            return sky
        }
    }
    
    // MARK: - Compatibility
    
    /// Generate compatibility between two contacts
    func generateCompatibility(
        contactA: Contact,
        contactB: Contact
    ) async throws -> CompatibilityCache {
        // Check cache
        if let cached = try? await SupabaseService.shared.fetchCompatibility(
            contactA: contactA.id,
            contactB: contactB.id
        ) {
            return cached
        }
        
        // Get profiles
        let profileA = try await getOrCreateAstroProfile(for: contactA)
        let profileB = try await getOrCreateAstroProfile(for: contactB)
        
        // Get base zodiac compatibility from API
        let zodiacCompat = try await AstrologyAPIService.shared.fetchZodiacCompatibility(
            sign1: profileA.sunZodiac,
            sign2: profileB.sunZodiac
        )
        
        // Generate with Gemini
        let generated = try await GeminiService.shared.generateCompatibilityReading(
            profileA: profileA,
            profileB: profileB,
            zodiacScore: zodiacCompat.compatibilityScore,
            nameA: contactA.name,
            nameB: contactB.name
        )
        
        // Create cache entry
        let compat = CompatibilityCache(
            contactA: contactA.id,
            contactB: contactB.id,
            baseScore: zodiacCompat.compatibilityScore,
            synastryHighlights: generated.strengths,
            aiOutput: generated.summary,
            weekStart: getWeekStart(from: Date())
        )
        
        return try await SupabaseService.shared.upsertCompatibility(compat)
    }
    
    // MARK: - "This Week" Compatibility
    
    /// Generate weekly compatibility that factors in current sky and moods
    func generateWeeklyCompatibility(
        contactA: Contact,
        contactB: Contact,
        oracleA: OracleContent?,
        oracleB: OracleContent?
    ) async throws -> CompatibilityCache {
        isLoading = true
        defer { isLoading = false }
        
        print("🔮 Generating weekly compatibility: \(contactA.name) + \(contactB.name)")
        
        // Get profiles
        let profileA = try await getOrCreateAstroProfile(for: contactA)
        let profileB = try await getOrCreateAstroProfile(for: contactB)
        print("✅ Got profiles: \(profileA.sunSign) + \(profileB.sunSign)")
        
        // Get weekly sky context
        let weeklySky = try? await getOrFetchWeeklySky()
        print("✅ Weekly sky: \(weeklySky?.moonPhase ?? "none")")
        
        // Get base score from static calculation
        let baseScore = AstralCompatibility(
            person1Sign: contactA.zodiacSign,
            person2Sign: contactB.zodiacSign
        ).harmonyScore
        print("✅ Base score: \(baseScore)")
        
        // Generate "This Week" compatibility with Gemini
        print("🤖 Calling Gemini for weekly compatibility...")
        let weeklyGenerated = try await GeminiService.shared.generateWeeklyCompatibility(
            profileA: profileA,
            profileB: profileB,
            oracleA: oracleA,
            oracleB: oracleB,
            weeklySky: weeklySky,
            baseScore: baseScore,
            nameA: contactA.name,
            nameB: contactB.name
        )
        print("✅ Gemini returned: score=\(weeklyGenerated.score), vibe=\(weeklyGenerated.vibe ?? "nil")")
        
        // Create cache entry with weekly data
        let compat = CompatibilityCache(
            contactA: contactA.id,
            contactB: contactB.id,
            baseScore: baseScore,
            weekStart: getWeekStart(from: Date()),
            thisWeekScore: weeklyGenerated.score,
            loveCompatibility: weeklyGenerated.love,
            communicationCompatibility: weeklyGenerated.communication,
            weeklyVibe: weeklyGenerated.vibe,
            weeklyReading: weeklyGenerated.reading,
            growthAdvice: weeklyGenerated.advice,
            celestialInfluence: weeklyGenerated.influence
        )
        
        // Try to save to Supabase
        do {
            return try await SupabaseService.shared.upsertCompatibility(compat)
        } catch {
            print("⚠️ Failed to save weekly compatibility: \(error.localizedDescription)")
            return compat
        }
    }
    
    // MARK: - Batch Operations
    
    /// Refresh oracle content for all contacts
    func refreshAllOracles(contacts: [Contact]) async {
        isLoading = true
        
        for contact in contacts {
            do {
                _ = try await generateOracleContent(for: contact)
            } catch {
                print("Failed to generate oracle for \(contact.name): \(error)")
            }
        }
        
        isLoading = false
    }
    
    // MARK: - Helpers
    
    private func geocodeBirthPlace(_ place: String) async throws -> (lat: Double, lon: Double, timezone: Double) {
        return try await withCheckedThrowingContinuation { continuation in
            geocoder.geocodeAddressString(place) { placemarks, error in
                if let error = error {
                    continuation.resume(throwing: OracleError.geocodingFailed(error.localizedDescription))
                    return
                }
                
                guard let placemark = placemarks?.first,
                      let location = placemark.location else {
                    continuation.resume(throwing: OracleError.geocodingFailed("No location found"))
                    return
                }
                
                // Estimate timezone from longitude (rough approximation)
                let timezone = location.coordinate.longitude / 15.0
                
                continuation.resume(returning: (
                    lat: location.coordinate.latitude,
                    lon: location.coordinate.longitude,
                    timezone: timezone.rounded()
                ))
            }
        }
    }
    
    private func getWeekStart(from date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components) ?? date
    }
}

// MARK: - Errors
enum OracleError: Error, LocalizedError {
    case missingBirthData(String)
    case geocodingFailed(String)
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .missingBirthData(let msg):
            return "Missing birth data: \(msg)"
        case .geocodingFailed(let msg):
            return "Geocoding failed: \(msg)"
        case .apiError(let msg):
            return "API error: \(msg)"
        }
    }
}

