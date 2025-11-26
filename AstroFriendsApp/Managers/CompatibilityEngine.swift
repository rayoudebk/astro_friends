import Foundation

// MARK: - Compatibility Engine
/// Centralized static compatibility calculations (Tier 1)
/// All calculations are deterministic and never change
struct CompatibilityEngine {
    
    // MARK: - Main Compatibility Score
    
    /// Calculate overall compatibility score between two signs
    static func overallCompatibility(signA: ZodiacSign, signB: ZodiacSign) -> Int {
        var score = 50 // Base score
        
        // Same sign bonus
        if signA == signB {
            score += 25
        }
        
        // Element compatibility
        score += elementBonus(signA: signA, signB: signB)
        
        // Modality compatibility
        score += modalityBonus(signA: signA, signB: signB)
        
        // Traditional matches
        if isTraditionalMatch(signA, signB) {
            score += 15
        }
        
        // Opposite signs (magnetic attraction)
        if areOpposites(signA, signB) {
            score += 10
        }
        
        return min(100, max(0, score))
    }
    
    /// Calculate full compatibility with optional Moon/Rising data
    static func fullCompatibility(
        sunA: ZodiacSign, moonA: ZodiacSign?, risingA: ZodiacSign?,
        sunB: ZodiacSign, moonB: ZodiacSign?, risingB: ZodiacSign?
    ) -> FullCompatibilityResult {
        
        let sunScore = overallCompatibility(signA: sunA, signB: sunB)
        
        var moonScore: Int? = nil
        if let mA = moonA, let mB = moonB {
            moonScore = overallCompatibility(signA: mA, signB: mB)
        }
        
        var risingScore: Int? = nil
        if let rA = risingA, let rB = risingB {
            risingScore = overallCompatibility(signA: rA, signB: rB)
        }
        
        // Weighted average
        var totalScore = sunScore * 3 // Sun weighted most
        var divisor = 3
        
        if let moon = moonScore {
            totalScore += moon * 2
            divisor += 2
        }
        
        if let rising = risingScore {
            totalScore += rising
            divisor += 1
        }
        
        let finalScore = totalScore / divisor
        
        return FullCompatibilityResult(
            overallScore: min(100, max(0, finalScore)),
            sunCompatibility: sunScore,
            moonCompatibility: moonScore,
            risingCompatibility: risingScore,
            harmonyLevel: HarmonyLevel.from(score: finalScore),
            elementDynamic: elementDynamic(signA: sunA, signB: sunB),
            modalityDynamic: modalityDynamic(signA: sunA, signB: sunB)
        )
    }
    
    // MARK: - Element Compatibility
    
    static func elementBonus(signA: ZodiacSign, signB: ZodiacSign) -> Int {
        let dynamic = elementDynamic(signA: signA, signB: signB)
        return dynamic.scoreBonus
    }
    
    static func elementDynamic(signA: ZodiacSign, signB: ZodiacSign) -> ElementalDynamic {
        return ElementalDynamic.between(signA.element, and: signB.element)
    }
    
    static func elementHarmonyDescription(signA: ZodiacSign, signB: ZodiacSign) -> String {
        return elementDynamic(signA: signA, signB: signB).description
    }
    
    // MARK: - Modality Compatibility
    
    static func modalityBonus(signA: ZodiacSign, signB: ZodiacSign) -> Int {
        let dynamic = modalityDynamic(signA: signA, signB: signB)
        return dynamic.scoreBonus
    }
    
    static func modalityDynamic(signA: ZodiacSign, signB: ZodiacSign) -> ModalityDynamic {
        return ModalityDynamic.between(signA.modality, and: signB.modality)
    }
    
    static func modalityHarmonyDescription(signA: ZodiacSign, signB: ZodiacSign) -> String {
        return modalityDynamic(signA: signA, signB: signB).description
    }
    
    // MARK: - Moon Compatibility (Emotional Bond)
    
    static func moonCompatibility(moonA: ZodiacSign, moonB: ZodiacSign) -> MoonCompatibilityResult {
        let score = overallCompatibility(signA: moonA, signB: moonB)
        let dynamic = elementDynamic(signA: moonA, signB: moonB)
        
        return MoonCompatibilityResult(
            score: score,
            harmonyLevel: HarmonyLevel.from(score: score),
            emotionalDynamic: dynamic,
            reading: generateMoonReading(moonA: moonA, moonB: moonB, dynamic: dynamic)
        )
    }
    
    // MARK: - Rising Compatibility (First Impressions)
    
    static func risingCompatibility(risingA: ZodiacSign, risingB: ZodiacSign) -> RisingCompatibilityResult {
        let score = overallCompatibility(signA: risingA, signB: risingB)
        let dynamic = elementDynamic(signA: risingA, signB: risingB)
        
        return RisingCompatibilityResult(
            score: score,
            harmonyLevel: HarmonyLevel.from(score: score),
            lifestyleDynamic: dynamic,
            reading: generateRisingReading(risingA: risingA, risingB: risingB, dynamic: dynamic)
        )
    }
    
    // MARK: - Traditional Matches
    
    static func isTraditionalMatch(_ signA: ZodiacSign, _ signB: ZodiacSign) -> Bool {
        let traditionalPairs: [(ZodiacSign, ZodiacSign)] = [
            (.aries, .leo), (.aries, .sagittarius),
            (.taurus, .virgo), (.taurus, .capricorn),
            (.gemini, .libra), (.gemini, .aquarius),
            (.cancer, .scorpio), (.cancer, .pisces),
            (.leo, .sagittarius), (.virgo, .capricorn),
            (.libra, .aquarius), (.scorpio, .pisces)
        ]
        
        return traditionalPairs.contains { pair in
            (pair.0 == signA && pair.1 == signB) || (pair.0 == signB && pair.1 == signA)
        }
    }
    
    static func areOpposites(_ signA: ZodiacSign, _ signB: ZodiacSign) -> Bool {
        let opposites: [(ZodiacSign, ZodiacSign)] = [
            (.aries, .libra), (.taurus, .scorpio), (.gemini, .sagittarius),
            (.cancer, .capricorn), (.leo, .aquarius), (.virgo, .pisces)
        ]
        
        return opposites.contains { pair in
            (pair.0 == signA && pair.1 == signB) || (pair.0 == signB && pair.1 == signA)
        }
    }
    
    // MARK: - Poetic Content
    
    static func poeticSummary(signA: ZodiacSign, signB: ZodiacSign) -> String {
        let dynamic = elementDynamic(signA: signA, signB: signB)
        
        switch dynamic {
        case .sameElement:
            return "Two souls swimming in the same cosmic river, discovering new depths together."
        case .complementary:
            return "Like wind beneath wings, you lift each other toward unexplored horizons."
        case .challenging:
            return "In the space between your differences, transformation blooms."
        case .grounding:
            return "A dance of contrasts that creates its own beautiful rhythm."
        }
    }
    
    static func nurturingAdvice(signA: ZodiacSign, signB: ZodiacSign) -> String {
        let dynamic = elementDynamic(signA: signA, signB: signB)
        
        switch dynamic {
        case .sameElement:
            return "Nurture this bond by occasionally stepping outside your shared element—try activities that neither of you would naturally choose."
        case .complementary:
            return "Your natural harmony is a gift. Keep it vibrant by expressing gratitude often and creating rituals that celebrate your connection."
        case .challenging:
            return "When friction arises, pause before reacting. Ask yourself: 'What can I learn here?' Your differences are doorways to growth."
        case .grounding:
            return "Honor both your need for action and reflection. Schedule time for both adventure and quiet connection."
        }
    }
    
    // MARK: - Private Helpers
    
    private static func generateMoonReading(moonA: ZodiacSign, moonB: ZodiacSign, dynamic: ElementalDynamic) -> String {
        switch dynamic {
        case .sameElement:
            return "Your emotional worlds speak the same language. With both Moons in \(moonA.element) signs, you instinctively understand how each other processes feelings."
        case .complementary:
            return "Your emotional natures feed each other beautifully. \(moonA.rawValue) Moon blends harmoniously with \(moonB.rawValue) Moon, creating emotional alchemy."
        case .challenging:
            return "Your emotional languages differ, offering rich opportunities for growth. With patience, these differences become your greatest teachers."
        case .grounding:
            return "Your Moons create a stabilizing emotional balance, grounding emotional extremes and providing a steady foundation for intimacy."
        }
    }
    
    private static func generateRisingReading(risingA: ZodiacSign, risingB: ZodiacSign, dynamic: ElementalDynamic) -> String {
        switch dynamic {
        case .sameElement:
            return "You recognized something familiar in each other from the very first moment. Your approaches to life naturally align."
        case .complementary:
            return "Your first impressions sparked an exciting curiosity. Together, you present a dynamic duo to the world."
        case .challenging:
            return "Your initial meeting may have felt intriguing or puzzling. This tension creates magnetic attraction."
        case .grounding:
            return "You bring out different sides of each other in social situations, making you versatile partners in life."
        }
    }
}

// MARK: - Result Types

struct FullCompatibilityResult {
    let overallScore: Int
    let sunCompatibility: Int
    let moonCompatibility: Int?
    let risingCompatibility: Int?
    let harmonyLevel: HarmonyLevel
    let elementDynamic: ElementalDynamic
    let modalityDynamic: ModalityDynamic
    
    var hasDeepData: Bool {
        moonCompatibility != nil || risingCompatibility != nil
    }
}

struct MoonCompatibilityResult {
    let score: Int
    let harmonyLevel: HarmonyLevel
    let emotionalDynamic: ElementalDynamic
    let reading: String
}

struct RisingCompatibilityResult {
    let score: Int
    let harmonyLevel: HarmonyLevel
    let lifestyleDynamic: ElementalDynamic
    let reading: String
}

// MARK: - Quick Access Extensions

extension Contact {
    /// Quick compatibility score with another contact (sun signs only)
    func quickCompatibility(with other: Contact) -> Int {
        CompatibilityEngine.overallCompatibility(signA: zodiacSign, signB: other.zodiacSign)
    }
    
    /// Full compatibility with another contact (uses all available chart data)
    func fullCompatibility(with other: Contact) -> FullCompatibilityResult {
        CompatibilityEngine.fullCompatibility(
            sunA: zodiacSign,
            moonA: natalChart?.moonSign,
            risingA: natalChart?.risingSign,
            sunB: other.zodiacSign,
            moonB: other.natalChart?.moonSign,
            risingB: other.natalChart?.risingSign
        )
    }
}

