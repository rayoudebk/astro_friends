import Foundation

// MARK: - Supabase Service
/// Handles all Supabase database operations
/// Only stores derived astro data - NO PII (GDPR compliant)
actor SupabaseService {
    static let shared = SupabaseService()
    
    private let projectURL = Secrets.Supabase.projectURL
    private let anonKey = Secrets.Supabase.anonKey
    
    private var restURL: String { "\(projectURL)/rest/v1" }
    
    private var headers: [String: String] {
        [
            "apikey": anonKey,
            "Authorization": "Bearer \(anonKey)",
            "Content-Type": "application/json",
            "Prefer": "return=representation"
        ]
    }
    
    // MARK: - Astro Profile Operations
    
    /// Save or update a user's astro profile (derived data only)
    func upsertAstroProfile(_ profile: AstroProfile) async throws -> AstroProfile {
        let endpoint = "\(restURL)/user_astro_profile"
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let body = try encoder.encode(profile)
        
        return try await upsert(endpoint: endpoint, body: body, onConflict: "contact_id")
    }
    
    /// Fetch astro profile for a contact
    func fetchAstroProfile(contactId: UUID) async throws -> AstroProfile? {
        let endpoint = "\(restURL)/user_astro_profile?contact_id=eq.\(contactId.uuidString)"
        
        let profiles: [AstroProfile] = try await get(endpoint: endpoint)
        return profiles.first
    }
    
    /// Fetch all astro profiles
    func fetchAllAstroProfiles() async throws -> [AstroProfile] {
        let endpoint = "\(restURL)/user_astro_profile"
        return try await get(endpoint: endpoint)
    }
    
    // MARK: - Weekly Sky Operations
    
    /// Save weekly sky data (moon phase + transits)
    func upsertWeeklySky(_ sky: WeeklySky) async throws -> WeeklySky {
        let endpoint = "\(restURL)/weekly_sky"
        
        // Build JSON manually to handle DATE format for week_start
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        var dict: [String: Any] = [
            "week_start": dateFormatter.string(from: sky.weekStart),
            "moon_phase": sky.moonPhase
        ]
        
        if let id = sky.id { dict["id"] = id.uuidString }
        if let moonSign = sky.moonSign { dict["moon_sign"] = moonSign }
        if let transits = sky.transits { dict["transits"] = transits }
        
        let body = try JSONSerialization.data(withJSONObject: dict)
        
        return try await upsert(endpoint: endpoint, body: body, onConflict: "week_start")
    }
    
    /// Fetch current week's sky data
    func fetchCurrentWeeklySky() async throws -> WeeklySky? {
        let weekStart = getWeekStart(from: Date())
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: weekStart)
        let endpoint = "\(restURL)/weekly_sky?week_start=eq.\(dateString)"
        
        let results: [WeeklySky] = try await get(endpoint: endpoint)
        return results.first
    }
    
    // MARK: - Oracle Content Operations
    
    /// Save oracle content for a contact
    func upsertOracleContent(_ content: OracleContent) async throws -> OracleContent {
        let endpoint = "\(restURL)/oracle_content"
        
        // Build JSON manually to handle DATE format for week_start
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        var dict: [String: Any] = [
            "contact_id": content.contactId.uuidString,
            "week_start": dateFormatter.string(from: content.weekStart),
            "weekly_reading": content.weeklyReading
        ]
        
        if let id = content.id { dict["id"] = id.uuidString }
        if let loveAdvice = content.loveAdvice { dict["love_advice"] = loveAdvice }
        if let careerAdvice = content.careerAdvice { dict["career_advice"] = careerAdvice }
        if let luckyNumber = content.luckyNumber { dict["lucky_number"] = luckyNumber }
        if let luckyColor = content.luckyColor { dict["lucky_color"] = luckyColor }
        if let mood = content.mood { dict["mood"] = mood }
        if let compatibilitySign = content.compatibilitySign { dict["compatibility_sign"] = compatibilitySign }
        if let celestialInsight = content.celestialInsight { dict["celestial_insight"] = celestialInsight }
        
        let body = try JSONSerialization.data(withJSONObject: dict)
        
        return try await upsert(endpoint: endpoint, body: body, onConflict: "contact_id,week_start")
    }
    
    /// Fetch oracle content for a contact
    func fetchOracleContent(contactId: UUID, weekStart: Date? = nil) async throws -> OracleContent? {
        let week = weekStart ?? getWeekStart(from: Date())
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: week)
        let endpoint = "\(restURL)/oracle_content?contact_id=eq.\(contactId.uuidString)&week_start=eq.\(dateString)"
        
        let results: [OracleContent] = try await get(endpoint: endpoint)
        return results.first
    }
    
    /// Fetch all oracle content for current week
    func fetchAllOracleContent() async throws -> [OracleContent] {
        let weekStart = getWeekStart(from: Date())
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: weekStart)
        let endpoint = "\(restURL)/oracle_content?week_start=eq.\(dateString)"
        
        return try await get(endpoint: endpoint)
    }
    
    // MARK: - Compatibility Cache Operations
    
    /// Save compatibility result between two contacts
    func upsertCompatibility(_ compat: CompatibilityCache) async throws -> CompatibilityCache {
        let endpoint = "\(restURL)/compatibility_cache"
        
        // Build JSON manually to handle DATE format for week_start
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        var dict: [String: Any] = [
            "contact_a": compat.contactA.uuidString,
            "contact_b": compat.contactB.uuidString,
            "base_score": compat.baseScore
        ]
        
        if let id = compat.id { dict["id"] = id.uuidString }
        if let synastry = compat.synastryHighlights { dict["synastry_highlights"] = synastry }
        if let aiOutput = compat.aiOutput { dict["ai_output"] = aiOutput }
        if let weekStart = compat.weekStart { dict["week_start"] = dateFormatter.string(from: weekStart) }
        if let thisWeekScore = compat.thisWeekScore { dict["this_week_score"] = thisWeekScore }
        if let loveCompat = compat.loveCompatibility { dict["love_compatibility"] = loveCompat }
        if let commCompat = compat.communicationCompatibility { dict["communication_compatibility"] = commCompat }
        if let weeklyVibe = compat.weeklyVibe { dict["weekly_vibe"] = weeklyVibe }
        if let weeklyReading = compat.weeklyReading { dict["weekly_reading"] = weeklyReading }
        if let growthAdvice = compat.growthAdvice { dict["growth_advice"] = growthAdvice }
        if let celestialInfluence = compat.celestialInfluence { dict["celestial_influence"] = celestialInfluence }
        if let liveScore = compat.liveScore { dict["live_score"] = liveScore }
        if let liveVibe = compat.liveVibe { dict["live_vibe"] = liveVibe }
        // liveUpdatedAt uses TIMESTAMPTZ so ISO8601 is fine
        if let liveUpdatedAt = compat.liveUpdatedAt { dict["live_updated_at"] = ISO8601DateFormatter().string(from: liveUpdatedAt) }
        
        let body = try JSONSerialization.data(withJSONObject: dict)
        
        return try await upsert(endpoint: endpoint, body: body, onConflict: "contact_a,contact_b")
    }
    
    /// Fetch compatibility between two contacts
    func fetchCompatibility(contactA: UUID, contactB: UUID) async throws -> CompatibilityCache? {
        // Check both orderings
        let endpoint1 = "\(restURL)/compatibility_cache?contact_a=eq.\(contactA.uuidString)&contact_b=eq.\(contactB.uuidString)"
        let endpoint2 = "\(restURL)/compatibility_cache?contact_a=eq.\(contactB.uuidString)&contact_b=eq.\(contactA.uuidString)"
        
        var results: [CompatibilityCache] = try await get(endpoint: endpoint1)
        if results.isEmpty {
            results = try await get(endpoint: endpoint2)
        }
        return results.first
    }
    
    // MARK: - Private Helpers
    
    private func getWeekStart(from date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components) ?? date
    }
    
    private func post<T: Decodable>(endpoint: String, body: Data) async throws -> T {
        guard let url = URL(string: endpoint) else {
            throw SupabaseError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw SupabaseError.httpError(statusCode: httpResponse.statusCode, message: errorBody)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        
        // Supabase returns array, get first item
        let results = try decoder.decode([T].self, from: data)
        guard let first = results.first else {
            throw SupabaseError.noData
        }
        return first
    }
    
    private func upsert<T: Decodable>(endpoint: String, body: Data, onConflict: String) async throws -> T {
        guard let url = URL(string: "\(endpoint)?on_conflict=\(onConflict)") else {
            throw SupabaseError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        // Key headers for upsert: merge duplicates AND return the result
        request.setValue("resolution=merge-duplicates,return=representation", forHTTPHeaderField: "Prefer")
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("⚠️ Supabase error (\(httpResponse.statusCode)): \(errorBody)")
            throw SupabaseError.httpError(statusCode: httpResponse.statusCode, message: errorBody)
        }
        
        // Debug: Print raw response
        let rawResponse = String(data: data, encoding: .utf8) ?? "nil"
        print("📦 Supabase upsert response: \(rawResponse.prefix(500))")
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        // Use flexible date decoding for Supabase responses
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Try ISO8601 with fractional seconds (Supabase timestamptz format)
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoFormatter.date(from: dateString) {
                return date
            }
            // Try ISO8601 without fractional seconds
            if let date = ISO8601DateFormatter().date(from: dateString) {
                return date
            }
            // Try date-only format (YYYY-MM-DD)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            if let date = dateFormatter.date(from: dateString) {
                return date
            }
            print("❌ Cannot decode date: \(dateString)")
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(dateString)")
        }
        
        do {
            let results = try decoder.decode([T].self, from: data)
            guard let first = results.first else {
                throw SupabaseError.noData
            }
            return first
        } catch {
            print("❌ Supabase decode error: \(error)")
            throw error
        }
    }
    
    private func get<T: Decodable>(endpoint: String) async throws -> [T] {
        guard let url = URL(string: endpoint) else {
            throw SupabaseError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        
        print("🔍 Supabase GET: \(endpoint)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }
        
        // Debug: Print raw response
        let rawResponse = String(data: data, encoding: .utf8) ?? "nil"
        print("📦 Supabase GET response (\(httpResponse.statusCode)): \(rawResponse.prefix(500))")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw SupabaseError.httpError(statusCode: httpResponse.statusCode, message: errorBody)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Try ISO8601 with fractional seconds (Supabase timestamptz)
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoFormatter.date(from: dateString) {
                return date
            }
            // Try ISO8601 without fractional seconds
            if let date = ISO8601DateFormatter().date(from: dateString) {
                return date
            }
            // Try date-only format (YYYY-MM-DD)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            if let date = dateFormatter.date(from: dateString) {
                return date
            }
            print("❌ Cannot decode date: \(dateString)")
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(dateString)")
        }
        
        do {
            return try decoder.decode([T].self, from: data)
        } catch {
            print("❌ Supabase GET decode error: \(error)")
            throw error
        }
    }
}

// MARK: - Errors
enum SupabaseError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, message: String)
    case noData
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid Supabase URL"
        case .invalidResponse:
            return "Invalid response from Supabase"
        case .httpError(let code, let message):
            return "HTTP \(code): \(message)"
        case .noData:
            return "No data returned"
        }
    }
}

// MARK: - Supabase Data Models (GDPR-safe, no PII)

struct AstroProfile: Codable, Identifiable {
    var id: UUID?
    let contactId: UUID
    let sunSign: String
    let moonSign: String?
    let risingSign: String?
    let element: String
    let modality: String
    var createdAt: Date?
    
    init(
        contactId: UUID,
        sunSign: ZodiacSign,
        moonSign: ZodiacSign?,
        risingSign: ZodiacSign?,
        element: String,
        modality: String
    ) {
        self.contactId = contactId
        self.sunSign = sunSign.rawValue.lowercased()
        self.moonSign = moonSign?.rawValue.lowercased()
        self.risingSign = risingSign?.rawValue.lowercased()
        self.element = element.lowercased()
        self.modality = modality.lowercased()
    }
    
    // Computed ZodiacSign helpers
    var sunZodiac: ZodiacSign {
        ZodiacSign(rawValue: sunSign.capitalized) ?? .unknown
    }
    
    var moonZodiac: ZodiacSign? {
        guard let moon = moonSign else { return nil }
        return ZodiacSign(rawValue: moon.capitalized)
    }
    
    var risingZodiac: ZodiacSign? {
        guard let rising = risingSign else { return nil }
        return ZodiacSign(rawValue: rising.capitalized)
    }
}

struct WeeklySky: Codable, Identifiable {
    var id: UUID?
    let weekStart: Date
    let moonPhase: String
    let moonSign: String?
    let transits: [String]? // Simplified transit descriptions
    var createdAt: Date?
}

struct OracleContent: Codable, Identifiable {
    var id: UUID?
    let contactId: UUID
    let weekStart: Date
    let weeklyReading: String
    let loveAdvice: String?
    let careerAdvice: String?
    let luckyNumber: Int?
    let luckyColor: String?
    let mood: String?
    let compatibilitySign: String? // Best match this week
    let celestialInsight: String?
    var createdAt: Date?
}

struct CompatibilityCache: Codable, Identifiable {
    var id: UUID?
    let contactA: UUID
    let contactB: UUID
    
    // Layer 1: Overall (static)
    let baseScore: Int
    let synastryHighlights: [String]?
    let aiOutput: String? // Gemini-generated compatibility text
    
    // Layer 2: This Week (dynamic, AI-generated)
    let thisWeekScore: Int?
    let loveCompatibility: String?
    let communicationCompatibility: String?
    let weeklyVibe: String?
    let weeklyReading: String?
    let growthAdvice: String?
    let celestialInfluence: String?
    
    // Layer 3: Live (future - daily or event-based)
    let liveScore: Int?
    let liveVibe: String?
    let liveUpdatedAt: Date?
    
    let weekStart: Date?
    var createdAt: Date?
    
    init(
        contactA: UUID,
        contactB: UUID,
        baseScore: Int,
        synastryHighlights: [String]? = nil,
        aiOutput: String? = nil,
        weekStart: Date? = nil,
        thisWeekScore: Int? = nil,
        loveCompatibility: String? = nil,
        communicationCompatibility: String? = nil,
        weeklyVibe: String? = nil,
        weeklyReading: String? = nil,
        growthAdvice: String? = nil,
        celestialInfluence: String? = nil,
        liveScore: Int? = nil,
        liveVibe: String? = nil,
        liveUpdatedAt: Date? = nil
    ) {
        self.contactA = contactA
        self.contactB = contactB
        self.baseScore = baseScore
        self.synastryHighlights = synastryHighlights
        self.aiOutput = aiOutput
        self.weekStart = weekStart
        self.thisWeekScore = thisWeekScore
        self.loveCompatibility = loveCompatibility
        self.communicationCompatibility = communicationCompatibility
        self.weeklyVibe = weeklyVibe
        self.weeklyReading = weeklyReading
        self.growthAdvice = growthAdvice
        self.celestialInfluence = celestialInfluence
        self.liveScore = liveScore
        self.liveVibe = liveVibe
        self.liveUpdatedAt = liveUpdatedAt
    }
    
    // MARK: - Live Compatibility Status
    var liveStatus: LiveCompatibilityStatus {
        if liveScore != nil {
            return .available
        }
        return .notAvailable
    }
}

// MARK: - Live Compatibility Status (Layer 3 placeholder)
enum LiveCompatibilityStatus: String, Codable {
    case notAvailable = "Not Available"
    case loading = "Loading"
    case available = "Available"
    case locked = "Locked"       // Requires Full profile
    case stale = "Stale"         // Needs refresh due to transit
    
    var icon: String {
        switch self {
        case .notAvailable: return "moon.zzz"
        case .loading: return "arrow.triangle.2.circlepath"
        case .available: return "waveform.path.ecg"
        case .locked: return "lock.fill"
        case .stale: return "exclamationmark.triangle"
        }
    }
    
    var description: String {
        switch self {
        case .notAvailable: return "Live compatibility not yet available"
        case .loading: return "Checking today's cosmic alignment..."
        case .available: return "Today's connection vibe"
        case .locked: return "Add full birth data to unlock"
        case .stale: return "Major transit detected - refresh recommended"
        }
    }
}

// MARK: - Element & Modality Helpers
extension ZodiacSign {
    var modalityString: String {
        modality.rawValue.capitalized
    }
}

