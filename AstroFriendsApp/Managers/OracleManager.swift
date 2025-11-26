import Foundation
import CoreLocation

// MARK: - Oracle Manager
/// Orchestrates the full content generation flow:
/// 1. Fetch birth data from Contact (client-side, PII stays local)
/// 2. Call AstrologyAPI to get natal chart data
/// 3. Store derived astro profile in Supabase (no PII)
/// 4. Generate oracle content with Gemini
/// 5. Cache content in Supabase
@MainActor
class OracleManager: ObservableObject {
    static let shared = OracleManager()
    
    @Published var isLoading = false
    @Published var lastError: String?
    
    private let geocoder = CLGeocoder()
    
    // MARK: - Full Pipeline: Generate Oracle for Contact
    
    /// Complete flow: API → Supabase → Gemini → Supabase
    func generateOracleContent(for contact: Contact) async throws -> OracleContent {
        isLoading = true
        lastError = nil
        
        defer { isLoading = false }
        
        print("🔮 Generating oracle for: \(contact.name) (\(contact.id))")
        
        // 1. Check if we already have fresh content this week
        if let cached = try? await SupabaseService.shared.fetchOracleContent(contactId: contact.id) {
            print("✅ Found cached oracle for \(contact.name)")
            return cached
        }
        
        print("📝 No cache found, generating fresh oracle...")
        
        // 2. Get or create astro profile
        do {
            let profile = try await getOrCreateAstroProfile(for: contact)
            print("✅ Got astro profile: \(profile.sunSign)")
            
            // 3. Get weekly sky context
            let weeklySky = try? await getOrFetchWeeklySky()
            print("✅ Got weekly sky: \(weeklySky?.moonPhase ?? "none")")
            
            // 4. Generate content with Gemini
            print("🤖 Calling Gemini...")
            let generated = try await GeminiService.shared.generateWeeklyOracle(
                profile: profile,
                weeklySky: weeklySky,
                contactName: contact.name
            )
            print("✅ Gemini returned content: \(generated.reading.prefix(50))...")
            
            // 5. Create oracle content
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
            
            // Try to save to Supabase (but don't fail if it doesn't work)
            do {
                let saved = try await SupabaseService.shared.upsertOracleContent(oracleContent)
                print("✅ Saved to Supabase")
                return saved
            } catch {
                print("⚠️ Failed to save to Supabase: \(error.localizedDescription)")
                // Return the content anyway - it works, just won't be cached
                return oracleContent
            }
        } catch {
            print("❌ Oracle generation failed: \(error)")
            throw error
        }
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
        return try await createBasicProfile(for: contact, birthday: birthday)
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
    
    private func createBasicProfile(for contact: Contact, birthday: Date) async throws -> AstroProfile {
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
        
        // Fetch from API
        let moonPhase = try await AstrologyAPIService.shared.fetchMoonPhase()
        let transits = try? await AstrologyAPIService.shared.fetchWeeklyTransits()
        
        let sky = WeeklySky(
            weekStart: getWeekStart(from: Date()),
            moonPhase: moonPhase.phaseName ?? moonPhase.moonPhase ?? "Unknown",
            moonSign: nil, // Would need additional API call
            transits: transits?.transits?.compactMap { transit in
                guard let planet = transit.transitingPlanet,
                      let aspect = transit.aspect else { return nil }
                return "\(planet) \(aspect)"
            }
        )
        
        return try await SupabaseService.shared.upsertWeeklySky(sky)
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

