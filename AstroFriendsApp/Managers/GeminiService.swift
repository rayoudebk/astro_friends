import Foundation

// MARK: - Gemini AI Service
/// Generates personalized oracle content using Gemini 1.5 Pro
/// Receives ONLY derived astro data - NO PII (GDPR compliant)
actor GeminiService {
    static let shared = GeminiService()
    
    private let apiKey = Secrets.Gemini.apiKey
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"
    
    // MARK: - Generate Weekly Oracle Content
    /// Creates personalized weekly horoscope content for a contact
    func generateWeeklyOracle(
        profile: AstroProfile,
        weeklySky: WeeklySky?,
        contactName: String? = nil // Optional, for personalization
    ) async throws -> GeneratedOracleContent {
        
        let prompt = buildWeeklyOraclePrompt(
            profile: profile,
            weeklySky: weeklySky,
            name: contactName
        )
        
        let response = try await callGemini(prompt: prompt)
        return try parseOracleResponse(response)
    }
    
    // MARK: - Generate Compatibility Reading
    /// Creates compatibility analysis between two people
    func generateCompatibilityReading(
        profileA: AstroProfile,
        profileB: AstroProfile,
        zodiacScore: Int,
        nameA: String? = nil,
        nameB: String? = nil
    ) async throws -> GeneratedCompatibility {
        
        let prompt = buildCompatibilityPrompt(
            profileA: profileA,
            profileB: profileB,
            baseScore: zodiacScore,
            nameA: nameA,
            nameB: nameB
        )
        
        let response = try await callGemini(prompt: prompt)
        return try parseCompatibilityResponse(response)
    }
    
    // MARK: - Generate "This Week" Compatibility
    /// Creates a weekly compatibility reading that factors in current sky conditions and moods
    func generateWeeklyCompatibility(
        profileA: AstroProfile,
        profileB: AstroProfile,
        oracleA: OracleContent?,
        oracleB: OracleContent?,
        weeklySky: WeeklySky?,
        baseScore: Int,
        nameA: String? = nil,
        nameB: String? = nil
    ) async throws -> GeneratedWeeklyCompatibility {
        
        let prompt = buildWeeklyCompatibilityPrompt(
            profileA: profileA,
            profileB: profileB,
            moodA: oracleA?.mood,
            moodB: oracleB?.mood,
            weeklySky: weeklySky,
            baseScore: baseScore,
            nameA: nameA,
            nameB: nameB
        )
        
        let response = try await callGemini(prompt: prompt)
        return try parseWeeklyCompatibilityResponse(response)
    }
    
    // MARK: - Prompt Builders
    
    private func buildWeeklyOraclePrompt(
        profile: AstroProfile,
        weeklySky: WeeklySky?,
        name: String?
    ) -> String {
        _ = name ?? "this person" // Reserved for future personalization
        let moonInfo = profile.moonSign ?? "unknown"
        let risingInfo = profile.risingSign ?? "unknown"
        
        var skyContext = ""
        if let sky = weeklySky {
            skyContext = """
            
            CURRENT CELESTIAL CONTEXT:
            - Moon Phase: \(sky.moonPhase)
            - Moon Sign: \(sky.moonSign ?? "unknown")
            - Notable Transits: \(sky.transits?.joined(separator: ", ") ?? "none specified")
            """
        }
        
        return """
        You are a mystical astrology oracle. Generate a weekly horoscope reading.
        
        NATAL CHART DATA:
        - Sun Sign: \(profile.sunSign)
        - Moon Sign: \(moonInfo)
        - Rising Sign: \(risingInfo)
        - Element: \(profile.element)
        - Modality: \(profile.modality)
        \(skyContext)
        
        Generate a JSON response with this EXACT structure (no markdown, just raw JSON):
        {
            "weeklyReading": "A 2-3 sentence personalized weekly reading that feels mystical and insightful. Reference their sun sign and any relevant transits.",
            "loveAdvice": "One sentence of love/relationship guidance for the week.",
            "careerAdvice": "One sentence of career/work guidance for the week.",
            "luckyNumber": <a number between 1-99>,
            "luckyColor": "<a color name>",
            "mood": "<one word describing the week's energy>",
            "compatibilitySign": "<the zodiac sign most compatible this week>",
            "celestialInsight": "A brief mystical insight about the current cosmic alignment affecting them."
        }
        
        Make the reading feel personal, mystical, and specific to their chart. Avoid generic advice.
        Use poetic but accessible language. Reference celestial bodies and cosmic energy.
        """
    }
    
    private func buildCompatibilityPrompt(
        profileA: AstroProfile,
        profileB: AstroProfile,
        baseScore: Int,
        nameA: String?,
        nameB: String?
    ) -> String {
        let personA = nameA ?? "Person A"
        let personB = nameB ?? "Person B"
        
        return """
        You are a mystical astrology oracle specializing in cosmic compatibility.
        
        PERSON A (\(personA)):
        - Sun: \(profileA.sunSign)
        - Moon: \(profileA.moonSign ?? "unknown")
        - Rising: \(profileA.risingSign ?? "unknown")
        - Element: \(profileA.element)
        
        PERSON B (\(personB)):
        - Sun: \(profileB.sunSign)
        - Moon: \(profileB.moonSign ?? "unknown")
        - Rising: \(profileB.risingSign ?? "unknown")
        - Element: \(profileB.element)
        
        BASE ZODIAC COMPATIBILITY SCORE: \(baseScore)%
        
        Generate a JSON response with this EXACT structure (no markdown, just raw JSON):
        {
            "overallScore": <adjusted score 0-100 based on full chart analysis>,
            "headline": "<a catchy 3-5 word title for this pairing>",
            "summary": "A 2-3 sentence overview of this cosmic connection.",
            "strengths": ["strength 1", "strength 2", "strength 3"],
            "challenges": ["challenge 1", "challenge 2"],
            "advice": "One sentence of wisdom for this pairing.",
            "elementalHarmony": "<describe how their elements interact>",
            "emotionalConnection": "How their moon signs relate emotionally."
        }
        
        Make the reading feel mystical and insightful. Be specific about their chart interactions.
        """
    }
    
    private func buildWeeklyCompatibilityPrompt(
        profileA: AstroProfile,
        profileB: AstroProfile,
        moodA: String?,
        moodB: String?,
        weeklySky: WeeklySky?,
        baseScore: Int,
        nameA: String?,
        nameB: String?
    ) -> String {
        let personA = nameA ?? "Person A"
        let personB = nameB ?? "Person B"
        
        var skyContext = ""
        if let sky = weeklySky {
            skyContext = """
            
            CURRENT CELESTIAL WEATHER:
            - Moon Phase: \(sky.moonPhase)
            - Moon Sign: \(sky.moonSign ?? "unknown")
            - Transits: \(sky.transits?.joined(separator: ", ") ?? "none specified")
            """
        }
        
        var moodsContext = ""
        if let mA = moodA, let mB = moodB {
            moodsContext = """
            
            THIS WEEK'S INDIVIDUAL MOODS:
            - \(personA)'s mood: \(mA)
            - \(personB)'s mood: \(mB)
            """
        }
        
        return """
        You are a mystical astrology oracle specializing in cosmic compatibility.
        Generate a "THIS WEEK" compatibility reading that factors in current celestial conditions.
        
        PERSON A (\(personA)):
        - Sun: \(profileA.sunSign)
        - Moon: \(profileA.moonSign ?? "unknown")
        - Element: \(profileA.element)
        
        PERSON B (\(personB)):
        - Sun: \(profileB.sunSign)
        - Moon: \(profileB.moonSign ?? "unknown")
        - Element: \(profileB.element)
        
        BASE COMPATIBILITY SCORE: \(baseScore)%
        \(skyContext)
        \(moodsContext)
        
        Generate a JSON response with this EXACT structure (no markdown, just raw JSON):
        {
            "thisWeekScore": <adjusted score 0-100 based on how the current sky affects their connection>,
            "loveCompatibility": "<High/Medium/Low>",
            "communicationCompatibility": "<High/Medium/Low>",
            "weeklyVibe": "<one word describing their energy together this week>",
            "summary": "A 2-3 sentence overview of how their connection feels THIS WEEK specifically.",
            "growthAdvice": "One sentence of advice for nurturing their connection this week.",
            "celestialInfluence": "Brief explanation of how current transits/moon phase affects them."
        }
        
        Factor in how the current moon phase and transits specifically affect this pairing.
        Make it feel timely and specific to THIS WEEK.
        """
    }
    
    // MARK: - API Call
    
    private func callGemini(prompt: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            throw GeminiError.invalidURL
        }
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.8,
                "topK": 40,
                "topP": 0.95,
                "maxOutputTokens": 4096
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw GeminiError.httpError(statusCode: httpResponse.statusCode, message: errorBody)
        }
        
        // Parse Gemini response structure
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw GeminiError.parsingError
        }
        
        return text
    }
    
    // MARK: - Response Parsers
    
    private func parseOracleResponse(_ response: String) throws -> GeneratedOracleContent {
        // Debug: print raw response
        print("🔮 Raw Gemini response:\n\(response)")
        
        // Clean up response (remove markdown code blocks if present)
        var cleanedResponse = response
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```JSON", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Try to extract JSON if there's extra text
        if let jsonStart = cleanedResponse.firstIndex(of: "{"),
           let jsonEnd = cleanedResponse.lastIndex(of: "}") {
            cleanedResponse = String(cleanedResponse[jsonStart...jsonEnd])
        }
        
        print("🔮 Cleaned response:\n\(cleanedResponse)")
        
        guard let data = cleanedResponse.data(using: .utf8) else {
            print("❌ Failed to convert to data")
            throw GeminiError.parsingError
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(GeneratedOracleContent.self, from: data)
        } catch {
            print("❌ JSON Decode error: \(error)")
            throw GeminiError.parsingError
        }
    }
    
    private func parseCompatibilityResponse(_ response: String) throws -> GeneratedCompatibility {
        let cleanedResponse = response
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let data = cleanedResponse.data(using: .utf8) else {
            throw GeminiError.parsingError
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(GeneratedCompatibility.self, from: data)
    }
    
    private func parseWeeklyCompatibilityResponse(_ response: String) throws -> GeneratedWeeklyCompatibility {
        var cleanedResponse = response
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```JSON", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Extract JSON if there's extra text
        if let jsonStart = cleanedResponse.firstIndex(of: "{"),
           let jsonEnd = cleanedResponse.lastIndex(of: "}") {
            cleanedResponse = String(cleanedResponse[jsonStart...jsonEnd])
        }
        
        guard let data = cleanedResponse.data(using: .utf8) else {
            throw GeminiError.parsingError
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(GeneratedWeeklyCompatibility.self, from: data)
    }
}

// MARK: - Errors
enum GeminiError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, message: String)
    case parsingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid Gemini API URL"
        case .invalidResponse:
            return "Invalid response from Gemini"
        case .httpError(let code, let message):
            return "HTTP \(code): \(message)"
        case .parsingError:
            return "Failed to parse Gemini response"
        }
    }
}

// MARK: - Generated Content Models

struct GeneratedOracleContent: Codable {
    let weeklyReading: String?
    let loveAdvice: String?
    let careerAdvice: String?
    let luckyNumber: Int?
    let luckyColor: String?
    let mood: String?
    let compatibilitySign: String?
    let celestialInsight: String?
    
    // Alternative key names Gemini might use
    let weekly_reading: String?
    let love_advice: String?
    let career_advice: String?
    let lucky_number: Int?
    let lucky_color: String?
    let compatibility_sign: String?
    let celestial_insight: String?
    
    // Computed properties to handle both cases
    var reading: String {
        weeklyReading ?? weekly_reading ?? "The stars are aligning for you this week."
    }
    
    var love: String? {
        loveAdvice ?? love_advice
    }
    
    var career: String? {
        careerAdvice ?? career_advice
    }
    
    var number: Int? {
        luckyNumber ?? lucky_number
    }
    
    var color: String? {
        luckyColor ?? lucky_color
    }
    
    var insight: String? {
        celestialInsight ?? celestial_insight
    }
    
    var bestMatch: String? {
        compatibilitySign ?? compatibility_sign
    }
}

struct GeneratedCompatibility: Codable {
    let overallScore: Int
    let headline: String
    let summary: String
    let strengths: [String]
    let challenges: [String]
    let advice: String
    let elementalHarmony: String?
    let emotionalConnection: String?
}

struct GeneratedWeeklyCompatibility: Codable {
    let thisWeekScore: Int?
    let loveCompatibility: String?
    let communicationCompatibility: String?
    let weeklyVibe: String?
    let summary: String?
    let growthAdvice: String?
    let celestialInfluence: String?
    
    // Snake case alternatives
    let this_week_score: Int?
    let love_compatibility: String?
    let communication_compatibility: String?
    let weekly_vibe: String?
    let growth_advice: String?
    let celestial_influence: String?
    
    // Computed properties
    var score: Int {
        thisWeekScore ?? this_week_score ?? 50
    }
    
    var love: String {
        loveCompatibility ?? love_compatibility ?? "Medium"
    }
    
    var communication: String {
        communicationCompatibility ?? communication_compatibility ?? "Medium"
    }
    
    var vibe: String {
        weeklyVibe ?? weekly_vibe ?? "Balanced"
    }
    
    var reading: String {
        summary ?? "The stars are aligning for connection this week."
    }
    
    var advice: String {
        growthAdvice ?? growth_advice ?? "Be open to each other's energy."
    }
    
    var influence: String? {
        celestialInfluence ?? celestial_influence
    }
}

