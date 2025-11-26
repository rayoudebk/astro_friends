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
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        let body = try encoder.encode(sky)
        
        return try await upsert(endpoint: endpoint, body: body, onConflict: "week_start")
    }
    
    /// Fetch current week's sky data
    func fetchCurrentWeeklySky() async throws -> WeeklySky? {
        let weekStart = getWeekStart(from: Date())
        let dateString = ISO8601DateFormatter().string(from: weekStart)
        let endpoint = "\(restURL)/weekly_sky?week_start=eq.\(dateString)"
        
        let results: [WeeklySky] = try await get(endpoint: endpoint)
        return results.first
    }
    
    // MARK: - Oracle Content Operations
    
    /// Save oracle content for a contact
    func upsertOracleContent(_ content: OracleContent) async throws -> OracleContent {
        let endpoint = "\(restURL)/oracle_content"
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        let body = try encoder.encode(content)
        
        return try await upsert(endpoint: endpoint, body: body, onConflict: "contact_id,week_start")
    }
    
    /// Fetch oracle content for a contact
    func fetchOracleContent(contactId: UUID, weekStart: Date? = nil) async throws -> OracleContent? {
        let week = weekStart ?? getWeekStart(from: Date())
        let dateString = ISO8601DateFormatter().string(from: week)
        let endpoint = "\(restURL)/oracle_content?contact_id=eq.\(contactId.uuidString)&week_start=eq.\(dateString)"
        
        let results: [OracleContent] = try await get(endpoint: endpoint)
        return results.first
    }
    
    /// Fetch all oracle content for current week
    func fetchAllOracleContent() async throws -> [OracleContent] {
        let weekStart = getWeekStart(from: Date())
        let dateString = ISO8601DateFormatter().string(from: weekStart)
        let endpoint = "\(restURL)/oracle_content?week_start=eq.\(dateString)"
        
        return try await get(endpoint: endpoint)
    }
    
    // MARK: - Compatibility Cache Operations
    
    /// Save compatibility result between two contacts
    func upsertCompatibility(_ compat: CompatibilityCache) async throws -> CompatibilityCache {
        let endpoint = "\(restURL)/compatibility_cache"
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        let body = try encoder.encode(compat)
        
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
        // Key header for upsert: merge duplicates instead of error
        request.setValue("resolution=merge-duplicates", forHTTPHeaderField: "Prefer")
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
        
        let results = try decoder.decode([T].self, from: data)
        guard let first = results.first else {
            throw SupabaseError.noData
        }
        return first
    }
    
    private func get<T: Decodable>(endpoint: String) async throws -> [T] {
        guard let url = URL(string: endpoint) else {
            throw SupabaseError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        
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
        
        return try decoder.decode([T].self, from: data)
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
    let baseScore: Int
    let synastryHighlights: [String]?
    let aiOutput: String? // Gemini-generated compatibility text
    let weekStart: Date?
    var createdAt: Date?
    
    // "This Week" compatibility fields
    let thisWeekScore: Int?
    let loveCompatibility: String?
    let communicationCompatibility: String?
    let weeklyVibe: String?
    let weeklyReading: String?
    let growthAdvice: String?
    let celestialInfluence: String?
    
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
        celestialInfluence: String? = nil
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
    }
}

// MARK: - Element & Modality Helpers
extension ZodiacSign {
    var modalityString: String {
        modality.rawValue.capitalized
    }
}

