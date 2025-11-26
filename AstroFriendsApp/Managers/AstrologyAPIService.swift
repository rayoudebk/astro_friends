import Foundation

// MARK: - AstrologyAPI Service
/// Handles all calls to AstrologyAPI (Western Astrology endpoints)
/// All PII (birth data) stays client-side per GDPR compliance
actor AstrologyAPIService {
    static let shared = AstrologyAPIService()
    
    private let baseURL = Secrets.AstrologyAPI.baseURL
    private let userId = Secrets.AstrologyAPI.userId
    private let apiKey = Secrets.AstrologyAPI.apiKey
    
    private var authHeader: String {
        let credentials = "\(userId):\(apiKey)"
        let data = credentials.data(using: .utf8)!
        return "Basic \(data.base64EncodedString())"
    }
    
    // MARK: - Fetch Natal Planets (Sun, Moon, Rising positions)
    /// Endpoint: planets/tropical
    /// Returns planetary positions for a birth chart
    func fetchNatalPlanets(
        birthDate: Date,
        birthTime: Date?,
        latitude: Double,
        longitude: Double,
        timezone: Double
    ) async throws -> NatalPlanetsResponse {
        let endpoint = "\(baseURL)/planets/tropical"
        
        let body = buildBirthDataBody(
            birthDate: birthDate,
            birthTime: birthTime,
            latitude: latitude,
            longitude: longitude,
            timezone: timezone
        )
        
        return try await post(endpoint: endpoint, body: body)
    }
    
    // MARK: - Fetch House Cusps (for Rising sign)
    /// Endpoint: house_cusps/tropical
    func fetchHouseCusps(
        birthDate: Date,
        birthTime: Date?,
        latitude: Double,
        longitude: Double,
        timezone: Double
    ) async throws -> HouseCuspsResponse {
        let endpoint = "\(baseURL)/house_cusps/tropical"
        
        let body = buildBirthDataBody(
            birthDate: birthDate,
            birthTime: birthTime,
            latitude: latitude,
            longitude: longitude,
            timezone: timezone
        )
        
        return try await post(endpoint: endpoint, body: body)
    }
    
    // MARK: - Fetch Moon Phase
    /// Endpoint: moon_phase_report
    func fetchMoonPhase(for date: Date = Date()) async throws -> MoonPhaseResponse {
        let endpoint = "\(baseURL)/moon_phase_report"
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day, .month, .year], from: date)
        
        let body: [String: Any] = [
            "day": components.day ?? 1,
            "month": components.month ?? 1,
            "year": components.year ?? 2024
        ]
        
        return try await post(endpoint: endpoint, body: body)
    }
    
    // MARK: - Fetch Weekly Transits
    /// Endpoint: tropical_transits/weekly
    func fetchWeeklyTransits(for date: Date = Date()) async throws -> WeeklyTransitsResponse {
        let endpoint = "\(baseURL)/tropical_transits/weekly"
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day, .month, .year], from: date)
        
        let body: [String: Any] = [
            "day": components.day ?? 1,
            "month": components.month ?? 1,
            "year": components.year ?? 2024
        ]
        
        return try await post(endpoint: endpoint, body: body)
    }
    
    // MARK: - Fetch Zodiac Compatibility
    /// Endpoint: zodiac_compatibility/:signA/:signB
    /// This is safe (no PII) - can be called server-side too
    func fetchZodiacCompatibility(
        sign1: ZodiacSign,
        sign2: ZodiacSign
    ) async throws -> ZodiacCompatibilityResponse {
        let sign1Name = sign1.rawValue.lowercased()
        let sign2Name = sign2.rawValue.lowercased()
        let endpoint = "\(baseURL)/zodiac_compatibility/\(sign1Name)/\(sign2Name)"
        
        return try await get(endpoint: endpoint)
    }
    
    // MARK: - Private Helpers
    
    private func buildBirthDataBody(
        birthDate: Date,
        birthTime: Date?,
        latitude: Double,
        longitude: Double,
        timezone: Double
    ) -> [String: Any] {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.day, .month, .year], from: birthDate)
        
        var hour = 12 // Default to noon if no time
        var minute = 0
        
        if let time = birthTime {
            let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
            hour = timeComponents.hour ?? 12
            minute = timeComponents.minute ?? 0
        }
        
        return [
            "day": dateComponents.day ?? 1,
            "month": dateComponents.month ?? 1,
            "year": dateComponents.year ?? 2000,
            "hour": hour,
            "min": minute,
            "lat": latitude,
            "lon": longitude,
            "tzone": timezone
        ]
    }
    
    private func post<T: Decodable>(endpoint: String, body: [String: Any]) async throws -> T {
        guard let url = URL(string: endpoint) else {
            throw AstrologyAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AstrologyAPIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw AstrologyAPIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(T.self, from: data)
    }
    
    private func get<T: Decodable>(endpoint: String) async throws -> T {
        guard let url = URL(string: endpoint) else {
            throw AstrologyAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AstrologyAPIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw AstrologyAPIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(T.self, from: data)
    }
}

// MARK: - Errors
enum AstrologyAPIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        }
    }
}

// MARK: - API Response Models

struct NatalPlanetsResponse: Codable {
    let sun: PlanetPosition?
    let moon: PlanetPosition?
    let mercury: PlanetPosition?
    let venus: PlanetPosition?
    let mars: PlanetPosition?
    let jupiter: PlanetPosition?
    let saturn: PlanetPosition?
    let uranus: PlanetPosition?
    let neptune: PlanetPosition?
    let pluto: PlanetPosition?
    
    // Derived helpers
    var sunSign: ZodiacSign? {
        guard let sign = sun?.sign else { return nil }
        return ZodiacSign(rawValue: sign.capitalized)
    }
    
    var moonSign: ZodiacSign? {
        guard let sign = moon?.sign else { return nil }
        return ZodiacSign(rawValue: sign.capitalized)
    }
}

struct PlanetPosition: Codable {
    let name: String?
    let sign: String?
    let signLord: String?
    let degree: Double?
    let house: Int?
    let retro: Bool?
    
    enum CodingKeys: String, CodingKey {
        case name, sign, degree, house, retro
        case signLord = "sign_lord"
    }
}

struct HouseCuspsResponse: Codable {
    let houses: [HouseCusp]?
    let ascendant: Double?
    let midheaven: Double?
    
    // Rising sign is the sign of the 1st house cusp (Ascendant)
    var risingSign: ZodiacSign? {
        guard let asc = ascendant else { return nil }
        return zodiacFromDegree(asc)
    }
    
    private func zodiacFromDegree(_ degree: Double) -> ZodiacSign {
        let signIndex = Int(degree / 30) % 12
        let signs: [ZodiacSign] = [.aries, .taurus, .gemini, .cancer, .leo, .virgo,
                                    .libra, .scorpio, .sagittarius, .capricorn, .aquarius, .pisces]
        return signs[signIndex]
    }
}

struct HouseCusp: Codable {
    let house: Int?
    let sign: String?
    let degree: Double?
}

struct MoonPhaseResponse: Codable {
    let moonPhase: String?
    let phaseName: String?
    let illumination: Double?
    let age: Double?
    let distanceFromSun: Double?
    let distanceFromEarth: Double?
    
    enum CodingKeys: String, CodingKey {
        case moonPhase = "moon_phase"
        case phaseName = "phase_name"
        case illumination, age
        case distanceFromSun = "distance_from_sun"
        case distanceFromEarth = "distance_from_earth"
    }
}

struct WeeklyTransitsResponse: Codable {
    let transits: [TransitAspect]?
}

struct TransitAspect: Codable {
    let transitingPlanet: String?
    let natalPlanet: String?
    let aspect: String?
    let orb: Double?
    let isApplying: Bool?
    
    enum CodingKeys: String, CodingKey {
        case transitingPlanet = "transiting_planet"
        case natalPlanet = "natal_planet"
        case aspect, orb
        case isApplying = "is_applying"
    }
}

struct ZodiacCompatibilityResponse: Codable {
    let score: Int?
    let heading: String?
    let description: String?
    
    // Some API versions use different keys
    let compatibility: Int?
    let report: String?
    
    var compatibilityScore: Int {
        score ?? compatibility ?? 50
    }
    
    var compatibilityDescription: String {
        description ?? report ?? ""
    }
}

