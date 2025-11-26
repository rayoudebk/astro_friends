import Foundation

// MARK: - The Oracle of Harmony
// A wise and compassionate interpreter of energetic connections between two souls

struct AstralCompatibility {
    let person1Sign: ZodiacSign
    let person2Sign: ZodiacSign
    
    // Optional natal chart data for deeper compatibility
    var person1Moon: ZodiacSign?
    var person1Rising: ZodiacSign?
    var person2Moon: ZodiacSign?
    var person2Rising: ZodiacSign?
    
    // Initialize with just sun signs (basic compatibility)
    init(person1Sign: ZodiacSign, person2Sign: ZodiacSign) {
        self.person1Sign = person1Sign
        self.person2Sign = person2Sign
    }
    
    // Initialize with full natal charts (deep compatibility)
    init(person1Chart: NatalChart?, person2Chart: NatalChart?, person1SunFallback: ZodiacSign, person2SunFallback: ZodiacSign) {
        self.person1Sign = person1Chart?.sunSign ?? person1SunFallback
        self.person2Sign = person2Chart?.sunSign ?? person2SunFallback
        self.person1Moon = person1Chart?.moonSign
        self.person1Rising = person1Chart?.risingSign
        self.person2Moon = person2Chart?.moonSign
        self.person2Rising = person2Chart?.risingSign
    }
    
    // Check if we have deep chart data
    var hasDeepCompatibility: Bool {
        person1Moon != nil || person2Moon != nil
    }
    
    var hasRisingData: Bool {
        person1Rising != nil || person2Rising != nil
    }
    
    // MARK: - Computed Properties
    
    var harmonyScore: Int {
        var score = Self.calculateHarmonyScore(between: person1Sign, and: person2Sign)
        
        // Add Moon compatibility bonus (emotional connection)
        if let moon1 = person1Moon, let moon2 = person2Moon {
            let moonScore = Self.calculateHarmonyScore(between: moon1, and: moon2)
            score = (score * 2 + moonScore) / 3 // Weight sun more than moon
        }
        
        // Add Rising compatibility bonus (first impressions & lifestyle)
        if let rising1 = person1Rising, let rising2 = person2Rising {
            let risingScore = Self.calculateHarmonyScore(between: rising1, and: rising2)
            score = (score * 3 + risingScore) / 4 // Weight existing more than rising
        }
        
        return min(100, max(0, score))
    }
    
    var harmonyLevel: HarmonyLevel {
        HarmonyLevel.from(score: harmonyScore)
    }
    
    var elementalDynamic: ElementalDynamic {
        ElementalDynamic.between(person1Sign.element, and: person2Sign.element)
    }
    
    var modalityDynamic: ModalityDynamic {
        ModalityDynamic.between(person1Sign.modality, and: person2Sign.modality)
    }
    
    // MARK: - Moon Compatibility (Emotional Bond)
    
    var moonCompatibility: String? {
        guard let moon1 = person1Moon, let moon2 = person2Moon else { return nil }
        return Self.getMoonCompatibilityReading(moon1: moon1, moon2: moon2)
    }
    
    var moonHarmonyLevel: HarmonyLevel? {
        guard let moon1 = person1Moon, let moon2 = person2Moon else { return nil }
        let score = Self.calculateHarmonyScore(between: moon1, and: moon2)
        return HarmonyLevel.from(score: score)
    }
    
    // MARK: - Rising Compatibility (First Impressions & Lifestyle)
    
    var risingCompatibility: String? {
        guard let rising1 = person1Rising, let rising2 = person2Rising else { return nil }
        return Self.getRisingCompatibilityReading(rising1: rising1, rising2: rising2)
    }
    
    var risingHarmonyLevel: HarmonyLevel? {
        guard let rising1 = person1Rising, let rising2 = person2Rising else { return nil }
        let score = Self.calculateHarmonyScore(between: rising1, and: rising2)
        return HarmonyLevel.from(score: score)
    }
    
    // MARK: - Oracle Readings
    
    /// The main compatibility reading - warm, poetic, and growth-focused
    var oracleReading: String {
        Self.getOracleReading(for: person1Sign, and: person2Sign)
    }
    
    /// Core strengths of this pairing
    var strengths: [String] {
        Self.getStrengths(for: person1Sign, and: person2Sign)
    }
    
    /// Growth opportunities framed positively
    var growthOpportunities: [String] {
        Self.getGrowthOpportunities(for: person1Sign, and: person2Sign)
    }
    
    /// A short poetic summary
    var poeticSummary: String {
        Self.getPoeticSummary(for: person1Sign, and: person2Sign)
    }
    
    /// Advice for nurturing the connection
    var nurturingAdvice: String {
        Self.getNurturingAdvice(for: person1Sign, and: person2Sign)
    }
    
    // MARK: - Harmony Calculation
    
    private static func calculateHarmonyScore(between sign1: ZodiacSign, and sign2: ZodiacSign) -> Int {
        var score = 50 // Base score
        
        // Same sign: deep understanding
        if sign1 == sign2 {
            score += 25
        }
        
        // Element compatibility
        let elementBonus = ElementalDynamic.between(sign1.element, and: sign2.element).scoreBonus
        score += elementBonus
        
        // Modality compatibility
        let modalityBonus = ModalityDynamic.between(sign1.modality, and: sign2.modality).scoreBonus
        score += modalityBonus
        
        // Traditional compatibility pairs
        if isTraditionalMatch(sign1, sign2) {
            score += 15
        }
        
        // Opposite signs: magnetic attraction
        if areOpposites(sign1, sign2) {
            score += 10
        }
        
        return min(100, max(0, score))
    }
    
    private static func isTraditionalMatch(_ sign1: ZodiacSign, _ sign2: ZodiacSign) -> Bool {
        let traditionalPairs: [(ZodiacSign, ZodiacSign)] = [
            (.aries, .leo), (.aries, .sagittarius),
            (.taurus, .virgo), (.taurus, .capricorn),
            (.gemini, .libra), (.gemini, .aquarius),
            (.cancer, .scorpio), (.cancer, .pisces),
            (.leo, .sagittarius), (.virgo, .capricorn),
            (.libra, .aquarius), (.scorpio, .pisces)
        ]
        
        return traditionalPairs.contains { pair in
            (pair.0 == sign1 && pair.1 == sign2) || (pair.0 == sign2 && pair.1 == sign1)
        }
    }
    
    private static func areOpposites(_ sign1: ZodiacSign, _ sign2: ZodiacSign) -> Bool {
        let opposites: [(ZodiacSign, ZodiacSign)] = [
            (.aries, .libra), (.taurus, .scorpio), (.gemini, .sagittarius),
            (.cancer, .capricorn), (.leo, .aquarius), (.virgo, .pisces)
        ]
        
        return opposites.contains { pair in
            (pair.0 == sign1 && pair.1 == sign2) || (pair.0 == sign2 && pair.1 == sign1)
        }
    }
}

// MARK: - Harmony Level

enum HarmonyLevel: String {
    case soulmates = "Soul Resonance"
    case deepConnection = "Deep Connection"
    case harmoniousFlow = "Harmonious Flow"
    case growthPartners = "Growth Partners"
    case dynamicTension = "Dynamic Teachers"
    
    var emoji: String {
        switch self {
        case .soulmates: return "✨"
        case .deepConnection: return "💫"
        case .harmoniousFlow: return "🌊"
        case .growthPartners: return "🌱"
        case .dynamicTension: return "⚡"
        }
    }
    
    var description: String {
        switch self {
        case .soulmates:
            return "Your energies dance together in beautiful synchronicity"
        case .deepConnection:
            return "A profound understanding flows naturally between you"
        case .harmoniousFlow:
            return "Your connection carries an easy, supportive rhythm"
        case .growthPartners:
            return "Together, you inspire each other to evolve and expand"
        case .dynamicTension:
            return "Your differences spark growth and valuable lessons"
        }
    }
    
    static func from(score: Int) -> HarmonyLevel {
        switch score {
        case 85...100: return .soulmates
        case 70..<85: return .deepConnection
        case 55..<70: return .harmoniousFlow
        case 40..<55: return .growthPartners
        default: return .dynamicTension
        }
    }
}

// MARK: - Elemental Dynamic

enum ElementalDynamic {
    case sameElement
    case complementary // Fire-Air, Earth-Water
    case challenging // Fire-Water, Earth-Air
    case grounding // Fire-Earth, Air-Water
    
    var scoreBonus: Int {
        switch self {
        case .sameElement: return 20
        case .complementary: return 15
        case .grounding: return 5
        case .challenging: return 0
        }
    }
    
    var description: String {
        switch self {
        case .sameElement:
            return "You share the same elemental language, understanding each other intuitively"
        case .complementary:
            return "Your elements feed each other, creating natural synergy and excitement"
        case .grounding:
            return "Your different elements offer balance and perspective to one another"
        case .challenging:
            return "Your contrasting elements invite you both to grow beyond comfort zones"
        }
    }
    
    static func between(_ element1: String, and element2: String) -> ElementalDynamic {
        if element1 == element2 {
            return .sameElement
        }
        
        let complementaryPairs = [("Fire", "Air"), ("Earth", "Water")]
        let isComplementary = complementaryPairs.contains { pair in
            (pair.0 == element1 && pair.1 == element2) || (pair.0 == element2 && pair.1 == element1)
        }
        
        if isComplementary {
            return .complementary
        }
        
        let challengingPairs = [("Fire", "Water"), ("Earth", "Air")]
        let isChallenging = challengingPairs.contains { pair in
            (pair.0 == element1 && pair.1 == element2) || (pair.0 == element2 && pair.1 == element1)
        }
        
        if isChallenging {
            return .challenging
        }
        
        return .grounding
    }
}

// MARK: - Modality Dynamic

enum ModalityDynamic {
    case sameModality
    case complementary
    case mixed
    
    var scoreBonus: Int {
        switch self {
        case .sameModality: return 5
        case .complementary: return 10
        case .mixed: return 7
        }
    }
    
    var description: String {
        switch self {
        case .sameModality:
            return "You approach life with similar rhythms and timing"
        case .complementary:
            return "Your different approaches create a complete, balanced dynamic"
        case .mixed:
            return "You bring unique perspectives that enrich each other"
        }
    }
    
    static func between(_ modality1: Modality, and modality2: Modality) -> ModalityDynamic {
        if modality1 == modality2 {
            return .sameModality
        }
        
        // Cardinal + Fixed or Fixed + Mutable are considered complementary
        let complementaryPairs: [(Modality, Modality)] = [
            (.cardinal, .fixed), (.fixed, .mutable)
        ]
        
        let isComplementary = complementaryPairs.contains { pair in
            (pair.0 == modality1 && pair.1 == modality2) || (pair.0 == modality2 && pair.1 == modality1)
        }
        
        return isComplementary ? .complementary : .mixed
    }
}

// MARK: - Modality Extension for ZodiacSign

enum Modality: String, Codable {
    case cardinal = "Cardinal"
    case fixed = "Fixed"
    case mutable = "Mutable"
    
    var description: String {
        switch self {
        case .cardinal: return "Initiators and leaders"
        case .fixed: return "Stabilizers and persisters"
        case .mutable: return "Adapters and changers"
        }
    }
}

extension ZodiacSign {
    var modality: Modality {
        switch self {
        case .aries, .cancer, .libra, .capricorn:
            return .cardinal
        case .taurus, .leo, .scorpio, .aquarius:
            return .fixed
        case .gemini, .virgo, .sagittarius, .pisces:
            return .mutable
        }
    }
}

// MARK: - Oracle Readings Database

extension AstralCompatibility {
    
    static func getOracleReading(for sign1: ZodiacSign, and sign2: ZodiacSign) -> String {
        let key = pairKey(sign1, sign2)
        return oracleReadings[key] ?? generateGenericReading(for: sign1, and: sign2)
    }
    
    static func getStrengths(for sign1: ZodiacSign, and sign2: ZodiacSign) -> [String] {
        let key = pairKey(sign1, sign2)
        return strengthsDatabase[key] ?? generateGenericStrengths(for: sign1, and: sign2)
    }
    
    static func getGrowthOpportunities(for sign1: ZodiacSign, and sign2: ZodiacSign) -> [String] {
        let key = pairKey(sign1, sign2)
        return growthDatabase[key] ?? generateGenericGrowth(for: sign1, and: sign2)
    }
    
    static func getPoeticSummary(for sign1: ZodiacSign, and sign2: ZodiacSign) -> String {
        let key = pairKey(sign1, sign2)
        return poeticSummaries[key] ?? generateGenericPoetic(for: sign1, and: sign2)
    }
    
    static func getNurturingAdvice(for sign1: ZodiacSign, and sign2: ZodiacSign) -> String {
        let key = pairKey(sign1, sign2)
        return nurturingAdviceDatabase[key] ?? generateGenericAdvice(for: sign1, and: sign2)
    }
    
    private static func pairKey(_ sign1: ZodiacSign, _ sign2: ZodiacSign) -> String {
        let sorted = [sign1.rawValue, sign2.rawValue].sorted()
        return "\(sorted[0])-\(sorted[1])"
    }
    
    // MARK: - Generic Generators (for pairs not in database)
    
    private static func generateGenericReading(for sign1: ZodiacSign, and sign2: ZodiacSign) -> String {
        let dynamic = ElementalDynamic.between(sign1.element, and: sign2.element)
        
        switch dynamic {
        case .sameElement:
            return "When \(sign1.rawValue) meets \(sign2.rawValue), there's an instant recognition—like two instruments playing in the same key. Your shared \(sign1.element) nature creates a foundation of mutual understanding. You speak the same emotional language, though you each have your own unique dialect. This connection invites you to explore the depths of your shared element while celebrating what makes each of you beautifully distinct."
            
        case .complementary:
            return "The meeting of \(sign1.rawValue) and \(sign2.rawValue) creates a natural alchemy. Your \(sign1.element) energy finds a willing partner in their \(sign2.element) spirit—together, you can create something greater than either could alone. There's an ease to this connection, a sense that you naturally bring out hidden facets in each other. When you collaborate, magic often follows."
            
        case .challenging:
            return "\(sign1.rawValue) and \(sign2.rawValue) come together like different seasons meeting at dawn. Your \(sign1.element) nature and their \(sign2.element) essence may seem worlds apart, yet this very difference holds profound potential for growth. You each carry wisdom the other needs. With patience and openness, you become each other's greatest teachers, expanding in ways you never imagined possible."
            
        case .grounding:
            return "The connection between \(sign1.rawValue) and \(sign2.rawValue) offers a beautiful balance of energies. Where your \(sign1.element) nature flows, their \(sign2.element) presence provides a complementary rhythm. Together, you create a more complete picture of life's possibilities. This relationship invites both of you to appreciate perspectives beyond your natural inclinations."
        }
    }
    
    private static func generateGenericStrengths(for sign1: ZodiacSign, and sign2: ZodiacSign) -> [String] {
        var strengths: [String] = []
        
        let dynamic = ElementalDynamic.between(sign1.element, and: sign2.element)
        
        switch dynamic {
        case .sameElement:
            strengths.append("Deep intuitive understanding of each other's needs")
            strengths.append("Shared values and ways of processing emotions")
        case .complementary:
            strengths.append("Natural synergy that amplifies both your gifts")
            strengths.append("Easy communication and mutual inspiration")
        case .challenging:
            strengths.append("Powerful potential for personal transformation")
            strengths.append("Bringing unique perspectives that expand worldviews")
        case .grounding:
            strengths.append("Balancing energies that create stability")
            strengths.append("Learning from each other's different approaches")
        }
        
        // Add modality-based strengths
        if sign1.modality == sign2.modality {
            strengths.append("Similar pace and approach to life's challenges")
        } else {
            strengths.append("Complementary ways of initiating and sustaining projects")
        }
        
        return strengths
    }
    
    private static func generateGenericGrowth(for sign1: ZodiacSign, and sign2: ZodiacSign) -> [String] {
        var growth: [String] = []
        
        let dynamic = ElementalDynamic.between(sign1.element, and: sign2.element)
        
        switch dynamic {
        case .sameElement:
            growth.append("Exploring perspectives outside your shared comfort zone")
            growth.append("Avoiding echo chambers by seeking diverse experiences together")
        case .complementary:
            growth.append("Ensuring both partners feel equally heard and valued")
            growth.append("Balancing excitement with grounded planning")
        case .challenging:
            growth.append("Practicing patience when your approaches differ")
            growth.append("Finding the gift in each other's contrasting viewpoints")
        case .grounding:
            growth.append("Appreciating each other's unique contributions")
            growth.append("Creating space for both action and reflection")
        }
        
        return growth
    }
    
    private static func generateGenericPoetic(for sign1: ZodiacSign, and sign2: ZodiacSign) -> String {
        let dynamic = ElementalDynamic.between(sign1.element, and: sign2.element)
        
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
    
    private static func generateGenericAdvice(for sign1: ZodiacSign, and sign2: ZodiacSign) -> String {
        let dynamic = ElementalDynamic.between(sign1.element, and: sign2.element)
        
        switch dynamic {
        case .sameElement:
            return "Nurture this bond by occasionally stepping outside your shared element—try activities that neither of you would naturally choose. This keeps your connection fresh and growing."
        case .complementary:
            return "Your natural harmony is a gift. Keep it vibrant by expressing gratitude often and creating rituals that celebrate what makes your connection special."
        case .challenging:
            return "When friction arises, pause before reacting. Ask yourself: 'What can I learn here?' Your differences are doorways to growth, not walls to climb."
        case .grounding:
            return "Honor both your need for action and reflection. Schedule time for both adventure and quiet connection—your bond thrives on this balance."
        }
    }
    
    // MARK: - Curated Readings Database
    
    private static let oracleReadings: [String: String] = [
        "Aries-Aries": "When two Aries souls collide, the universe feels the spark! Your energy together is like a double flame—passionate, direct, and endlessly dynamic. You understand each other's need for independence and adventure without explanation. Together, you're unstoppable pioneers, though you may need to take turns leading. The key to your harmony lies in channeling your shared fire toward common goals rather than competing for the spotlight.",
        
        "Aries-Leo": "Fire meets fire in the most magnificent way! The Ram and the Lion create a connection that radiates warmth and vitality to everyone around you. Aries brings the spark of initiation while Leo sustains it with generous heart-fire. You inspire each other to be bolder, brighter versions of yourselves. Your energy together feels like a celebration of life itself.",
        
        "Aries-Libra": "Opposites on the zodiac wheel, yet magnetically drawn together. Aries brings courage and directness; Libra offers grace and perspective. Where Aries charges forward, Libra considers all angles. This dance of self and other creates a beautiful balance when you appreciate what each brings. Together, you learn that independence and partnership can coexist harmoniously.",
        
        "Taurus-Cancer": "Earth and Water blend into fertile ground for deep emotional security. The Bull offers steadfast presence while the Crab nurtures with intuitive care. Together, you create a sanctuary—a place where both of you feel truly safe to be yourselves. Your energy together feels like coming home after a long journey, warm and deeply nourishing.",
        
        "Taurus-Virgo": "Two Earth signs finding perfect rhythm together. There's a quiet understanding between you that doesn't need many words. Taurus brings sensual appreciation of life's pleasures; Virgo adds thoughtful attention to making things work beautifully. Your practical magic together can build lasting foundations for dreams to flourish.",
        
        "Gemini-Libra": "Air signs in delightful conversation! The Twins and the Scales create a connection filled with ideas, laughter, and social grace. You stimulate each other's minds endlessly, finding joy in exploring concepts and connecting with others. Your energy together feels like a sparkling salon where wisdom and wit dance freely.",
        
        "Gemini-Sagittarius": "Opposite signs with a shared love of learning and exploration! Gemini gathers fascinating details while Sagittarius seeks the bigger picture. Together, you're eternal students of life, inspiring each other to ask better questions and venture further. Your energy creates an endless adventure of the mind and spirit.",
        
        "Cancer-Scorpio": "Water meeting water in profound emotional depths. The Crab and the Scorpion share an intuitive language that goes beyond words. You feel each other's moods and needs almost psychically. Together, you create emotional intimacy that many only dream of. Your bond is a safe harbor in life's storms.",
        
        "Cancer-Pisces": "The gentlest, most nurturing of connections. Both Water signs, you flow together with remarkable ease. Cancer offers protective care while Pisces brings transcendent compassion. Your energy together feels like a warm embrace that heals old wounds. In each other, you find someone who truly understands the language of the heart.",
        
        "Leo-Sagittarius": "Fire signs celebrating life together! The Lion's creative warmth meets the Archer's adventurous spirit in a connection full of joy and optimism. You encourage each other's dreams and laugh together often. Your energy radiates such positivity that others are drawn to your light. Together, everything feels possible.",
        
        "Virgo-Capricorn": "Earth signs building something meaningful together. The Maiden's attention to detail complements the Goat's ambitious vision. You share practical values and a deep appreciation for effort and quality. Your energy together feels reliable and productive—you accomplish so much when you collaborate with shared purpose.",
        
        "Libra-Aquarius": "Air signs in harmonious intellectual connection. Libra's grace and diplomacy pairs beautifully with Aquarius's innovative vision. You share ideals about fairness and progress, inspiring each other toward making the world more beautiful and just. Your energy together feels like a meeting of minds with heart.",
        
        "Scorpio-Pisces": "The deepest waters of the zodiac meeting in profound connection. Scorpio's intensity finds a soft landing in Pisces' compassion, while Pisces discovers strength in Scorpio's unwavering loyalty. Together, you explore emotional and spiritual realms that few others can access. Your bond transcends the ordinary.",
        
        "Sagittarius-Aquarius": "Fire and Air creating expansive possibilities! The Archer's philosophical quest meets the Water Bearer's humanitarian vision. You share a love of freedom and ideas that push boundaries. Your energy together feels revolutionary—like two visionaries dreaming up a better future over endless conversations."
    ]
    
    private static let strengthsDatabase: [String: [String]] = [
        "Aries-Leo": [
            "Mutual admiration and genuine celebration of each other's wins",
            "Shared enthusiasm that makes every day feel like an adventure",
            "Natural leadership abilities that complement rather than compete",
            "A warm, generous connection that radiates joy to others"
        ],
        "Cancer-Scorpio": [
            "Profound emotional understanding without needing explanations",
            "Fierce loyalty and protective instincts for each other",
            "Intuitive communication that borders on the telepathic",
            "Creating deep security and trust that allows vulnerability"
        ],
        "Gemini-Libra": [
            "Endless fascinating conversations that never grow stale",
            "Shared social grace that makes you a beloved pair",
            "Intellectual stimulation that keeps you both sharp and curious",
            "A lightness and charm that makes difficult times easier"
        ],
        "Taurus-Virgo": [
            "Shared appreciation for quality, beauty, and craftsmanship",
            "Practical teamwork that accomplishes real-world goals",
            "Reliability and consistency that builds deep trust",
            "A grounded approach to life that feels stable and secure"
        ]
    ]
    
    private static let growthDatabase: [String: [String]] = [
        "Aries-Leo": [
            "Learning to share the spotlight graciously",
            "Developing patience when neither wants to compromise",
            "Balancing individual ambitions with shared goals"
        ],
        "Cancer-Scorpio": [
            "Allowing space for lighter moments amidst the intensity",
            "Processing emotions openly rather than holding onto hurts",
            "Trusting that vulnerability strengthens rather than weakens the bond"
        ],
        "Gemini-Libra": [
            "Moving from ideas to committed action together",
            "Addressing conflicts directly rather than keeping things light",
            "Grounding your mental connection with physical presence"
        ],
        "Taurus-Virgo": [
            "Embracing spontaneity and unexpected changes together",
            "Releasing perfectionism in favor of progress",
            "Adding more playfulness to your practical partnership"
        ]
    ]
    
    private static let poeticSummaries: [String: String] = [
        "Aries-Leo": "Two flames dancing together, creating light that warms all who witness it.",
        "Cancer-Scorpio": "Deep calls to deep—two souls who've found their sanctuary in each other.",
        "Gemini-Libra": "Minds in flight together, weaving words into wings of shared wonder.",
        "Taurus-Virgo": "Roots intertwined beneath the surface, growing stronger with each season.",
        "Aries-Libra": "The spark and the mirror, teaching each other the art of self and other.",
        "Taurus-Cancer": "A garden of comfort, where love blooms in safety and care.",
        "Leo-Sagittarius": "Adventurers of the heart, setting the world ablaze with joy.",
        "Scorpio-Pisces": "Ocean depths where two souls swim as one through mystery and magic."
    ]
    
    private static let nurturingAdviceDatabase: [String: String] = [
        "Aries-Leo": "Celebrate each other loudly and often. Plan adventures that let you both shine. When egos clash, remember that you're on the same team—redirect that fire toward a shared challenge.",
        
        "Cancer-Scorpio": "Create rituals of emotional check-ins where honesty flows freely. Your depth is your gift—honor it with quality time that allows real intimacy to unfold.",
        
        "Gemini-Libra": "Keep the conversation flowing but also create quiet moments of just being together. Your mental connection thrives when balanced with physical presence and touch.",
        
        "Taurus-Virgo": "Schedule regular 'appreciation sessions' where you acknowledge each other's efforts. Break routine occasionally with unexpected pleasures—you both deserve more play.",
        
        "Aries-Libra": "Practice the art of taking turns—sometimes leading, sometimes following. Your opposite natures are your greatest teachers when approached with curiosity instead of frustration."
    ]
    
    // MARK: - Moon Compatibility Readings (Emotional Bond)
    
    static func getMoonCompatibilityReading(moon1: ZodiacSign, moon2: ZodiacSign) -> String {
        let dynamic = ElementalDynamic.between(moon1.element, and: moon2.element)
        
        switch dynamic {
        case .sameElement:
            return "Your emotional worlds speak the same language. With both Moons in \(moon1.element) signs, you instinctively understand how each other processes feelings. \(moon1.rawValue) Moon meets \(moon2.rawValue) Moon creates a safe emotional harbor where vulnerability flows naturally. You may finish each other's emotional sentences."
            
        case .complementary:
            return "Your emotional natures feed each other beautifully. \(moon1.rawValue) Moon's \(moon1.moonTraits) blends harmoniously with \(moon2.rawValue) Moon's \(moon2.moonTraits). Together, you create an emotional alchemy that neither could achieve alone—inspiring and uplifting each other through life's tides."
            
        case .challenging:
            return "Your emotional languages differ, offering rich opportunities for growth. \(moon1.rawValue) Moon processes feelings through \(moon1.element.lowercased()) energy, while \(moon2.rawValue) Moon needs \(moon2.element.lowercased()) expression. With patience, these differences become your greatest teachers—each showing the other new ways to feel and heal."
            
        case .grounding:
            return "Your Moons create a stabilizing emotional balance. \(moon1.rawValue) Moon brings \(moon1.moonTraits), while \(moon2.rawValue) Moon offers \(moon2.moonTraits). This combination grounds emotional extremes and provides a steady foundation for deep, lasting intimacy."
        }
    }
    
    // MARK: - Rising Compatibility Readings (First Impressions & Lifestyle)
    
    static func getRisingCompatibilityReading(rising1: ZodiacSign, rising2: ZodiacSign) -> String {
        let dynamic = ElementalDynamic.between(rising1.element, and: rising2.element)
        
        switch dynamic {
        case .sameElement:
            return "You recognized something familiar in each other from the very first moment. With \(rising1.rawValue) Rising meeting \(rising2.rawValue) Rising, your approaches to life naturally align. You share similar lifestyles, social preferences, and ways of moving through the world. Others see you as a natural pair."
            
        case .complementary:
            return "Your first impressions sparked an exciting curiosity. \(rising1.rawValue) Rising \(rising1.risingTraits), while \(rising2.rawValue) Rising \(rising2.risingTraits). Together, you present a dynamic duo to the world—your combined energies creating something greater than either alone."
            
        case .challenging:
            return "Your initial meeting may have felt intriguing or even puzzling. \(rising1.rawValue) Rising's style contrasts with \(rising2.rawValue) Rising's approach to life. This tension creates magnetic attraction—you're drawn to qualities in each other that you're still developing in yourselves."
            
        case .grounding:
            return "You bring out different sides of each other in social situations. \(rising1.rawValue) Rising and \(rising2.rawValue) Rising create a balanced presence together. Where one leads, the other supports, making you versatile partners in navigating life's varied landscapes."
        }
    }
    
    // MARK: - Complete Chart Compatibility Summary
    
    func getFullChartReading() -> String {
        var reading = oracleReading
        
        if let moonReading = moonCompatibility {
            reading += "\n\n🌙 **Emotional Connection (Moon)**\n\(moonReading)"
        }
        
        if let risingReading = risingCompatibility {
            reading += "\n\n⬆️ **First Impressions & Lifestyle (Rising)**\n\(risingReading)"
        }
        
        return reading
    }
}

