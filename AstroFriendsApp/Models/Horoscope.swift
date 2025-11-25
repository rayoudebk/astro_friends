import Foundation

// MARK: - Moon Phase
enum MoonPhase: String, CaseIterable {
    case newMoon = "New Moon"
    case waxingCrescent = "Waxing Crescent"
    case firstQuarter = "First Quarter"
    case waxingGibbous = "Waxing Gibbous"
    case fullMoon = "Full Moon"
    case waningGibbous = "Waning Gibbous"
    case lastQuarter = "Last Quarter"
    case waningCrescent = "Waning Crescent"
    
    var emoji: String {
        switch self {
        case .newMoon: return "🌑"
        case .waxingCrescent: return "🌒"
        case .firstQuarter: return "🌓"
        case .waxingGibbous: return "🌔"
        case .fullMoon: return "🌕"
        case .waningGibbous: return "🌖"
        case .lastQuarter: return "🌗"
        case .waningCrescent: return "🌘"
        }
    }
    
    var emotionalTone: String {
        switch self {
        case .newMoon:
            return "introspective and ready for fresh starts"
        case .waxingCrescent:
            return "hopeful and building momentum"
        case .firstQuarter:
            return "determined and action-oriented"
        case .waxingGibbous:
            return "refining your focus and trusting the process"
        case .fullMoon:
            return "emotionally heightened and illuminated"
        case .waningGibbous:
            return "grateful and ready to share wisdom"
        case .lastQuarter:
            return "reflective and releasing what no longer serves"
        case .waningCrescent:
            return "surrendering and preparing for renewal"
        }
    }
    
    var guidance: String {
        switch self {
        case .newMoon:
            return "Set intentions and plant seeds for new beginnings."
        case .waxingCrescent:
            return "Take small steps toward your goals with faith."
        case .firstQuarter:
            return "Push through obstacles—commitment brings rewards."
        case .waxingGibbous:
            return "Fine-tune your approach and stay patient."
        case .fullMoon:
            return "Celebrate progress and release emotional blocks."
        case .waningGibbous:
            return "Share your knowledge and express gratitude."
        case .lastQuarter:
            return "Let go of what's holding you back."
        case .waningCrescent:
            return "Rest, reflect, and prepare for transformation."
        }
    }
    
    // Calculate current moon phase based on date
    static func current(for date: Date = Date()) -> MoonPhase {
        // Approximate moon phase calculation
        // A lunar cycle is about 29.53 days
        // Reference: January 6, 2000 was a New Moon
        let calendar = Calendar.current
        let referenceDate = calendar.date(from: DateComponents(year: 2000, month: 1, day: 6))!
        let daysSinceReference = calendar.dateComponents([.day], from: referenceDate, to: date).day ?? 0
        let lunarCycle = 29.53
        let daysIntoCycle = Double(daysSinceReference).truncatingRemainder(dividingBy: lunarCycle)
        let phaseIndex = Int((daysIntoCycle / lunarCycle) * 8) % 8
        return MoonPhase.allCases[phaseIndex]
    }
}

// MARK: - Moon Sign (where the Moon is transiting)
enum MoonSign: String, CaseIterable {
    case aries = "Aries"
    case taurus = "Taurus"
    case gemini = "Gemini"
    case cancer = "Cancer"
    case leo = "Leo"
    case virgo = "Virgo"
    case libra = "Libra"
    case scorpio = "Scorpio"
    case sagittarius = "Sagittarius"
    case capricorn = "Capricorn"
    case aquarius = "Aquarius"
    case pisces = "Pisces"
    
    var emotionalFlavor: String {
        switch self {
        case .aries: return "bold and impulsive"
        case .taurus: return "grounded and sensual"
        case .gemini: return "curious and communicative"
        case .cancer: return "nurturing and nostalgic"
        case .leo: return "expressive and warm-hearted"
        case .virgo: return "practical and detail-oriented"
        case .libra: return "harmonious and relationship-focused"
        case .scorpio: return "intense and transformative"
        case .sagittarius: return "adventurous and optimistic"
        case .capricorn: return "disciplined and achievement-driven"
        case .aquarius: return "innovative and humanitarian"
        case .pisces: return "dreamy and deeply intuitive"
        }
    }
    
    // Approximate moon sign based on date (moon changes signs every ~2.5 days)
    static func current(for date: Date = Date()) -> MoonSign {
        let calendar = Calendar.current
        let referenceDate = calendar.date(from: DateComponents(year: 2000, month: 1, day: 6))!
        let daysSinceReference = calendar.dateComponents([.day], from: referenceDate, to: date).day ?? 0
        // Moon moves through all 12 signs in ~27.3 days
        let daysPerSign = 27.3 / 12.0
        let signIndex = Int(Double(daysSinceReference) / daysPerSign) % 12
        return MoonSign.allCases[signIndex]
    }
}

// MARK: - Planetary Transit
struct PlanetaryTransit {
    let planet: String
    let emoji: String
    let aspect: String
    let description: String
    let advice: String
    
    static let weeklyTransits: [[PlanetaryTransit]] = [
        // Week 0
        [
            PlanetaryTransit(
                planet: "Venus",
                emoji: "♀️",
                aspect: "trine Neptune",
                description: "Venus forms a gentle trine with Neptune, heightening creativity and romantic sensitivity.",
                advice: "Express love through art, music, or heartfelt gestures. Your imagination is a powerful connector."
            ),
            PlanetaryTransit(
                planet: "Mercury",
                emoji: "☿️",
                aspect: "conjunct Sun",
                description: "Mercury aligns with the Sun, sharpening your mental clarity and communication.",
                advice: "Speak your truth with confidence. Important conversations are favored now."
            )
        ],
        // Week 1
        [
            PlanetaryTransit(
                planet: "Mars",
                emoji: "♂️",
                aspect: "sextile Jupiter",
                description: "Mars harmonizes with Jupiter, fueling ambition and expanding opportunities for action.",
                advice: "Take bold steps toward your goals. Fortune favors the courageous this week."
            ),
            PlanetaryTransit(
                planet: "Venus",
                emoji: "♀️",
                aspect: "entering Taurus",
                description: "Venus enters her home sign of Taurus, emphasizing comfort, beauty, and sensual pleasures.",
                advice: "Indulge in life's simple pleasures. Treat yourself and loved ones with care."
            )
        ],
        // Week 2
        [
            PlanetaryTransit(
                planet: "Mercury",
                emoji: "☿️",
                aspect: "trine Saturn",
                description: "Mercury trines Saturn, bringing structure to your thoughts and grounding your ideas.",
                advice: "Plan for the long term. Your words carry weight—use them wisely."
            ),
            PlanetaryTransit(
                planet: "Sun",
                emoji: "☀️",
                aspect: "square Pluto",
                description: "The Sun squares Pluto, intensifying power dynamics and urging transformation.",
                advice: "Face what you've been avoiding. True empowerment comes through authenticity."
            )
        ],
        // Week 3
        [
            PlanetaryTransit(
                planet: "Venus",
                emoji: "♀️",
                aspect: "sextile Mars",
                description: "Venus and Mars dance in harmony, igniting passion and creative energy.",
                advice: "Pursue what you desire with grace. Balance assertion with receptivity."
            ),
            PlanetaryTransit(
                planet: "Jupiter",
                emoji: "♃",
                aspect: "trine Moon",
                description: "Jupiter trines the Moon, expanding emotional wisdom and bringing good fortune.",
                advice: "Trust your instincts—they're aligned with abundance right now."
            )
        ],
        // Week 4
        [
            PlanetaryTransit(
                planet: "Mercury",
                emoji: "☿️",
                aspect: "opposite Uranus",
                description: "Mercury opposes Uranus, bringing unexpected insights and surprising news.",
                advice: "Stay flexible in your thinking. Breakthroughs come from unexpected directions."
            ),
            PlanetaryTransit(
                planet: "Mars",
                emoji: "♂️",
                aspect: "conjunct North Node",
                description: "Mars aligns with the North Node, energizing your life purpose and destiny.",
                advice: "Take action on your soul's calling. Courage moves you toward your fate."
            )
        ]
    ]
    
    static func currentTransits(for date: Date = Date()) -> [PlanetaryTransit] {
        let weekNumber = Calendar.current.component(.weekOfYear, from: date)
        let index = weekNumber % weeklyTransits.count
        return weeklyTransits[index]
    }
}

// MARK: - Horoscope
struct Horoscope {
    let sign: ZodiacSign
    let weeklyReading: String
    let loveAdvice: String
    let careerAdvice: String
    let luckyNumber: Int
    let luckyColor: String
    let compatibility: ZodiacSign
    let mood: String
    let celestialInsight: String // New: ties Moon phase + transits to practical advice
    
    // Weekly horoscope readings - rotates based on week number
    static func getWeeklyHoroscope(for sign: ZodiacSign) -> Horoscope {
        let weekNumber = Calendar.current.component(.weekOfYear, from: Date())
        let readings = horoscopeReadings[sign] ?? defaultReadings
        let index = weekNumber % readings.count
        return readings[index]
    }
    
    // Get current celestial context
    static var currentMoonPhase: MoonPhase {
        MoonPhase.current()
    }
    
    static var currentMoonSign: MoonSign {
        MoonSign.current()
    }
    
    static var currentTransits: [PlanetaryTransit] {
        PlanetaryTransit.currentTransits()
    }
    
    // Generate dynamic celestial message combining moon phase, moon sign, and transits
    static func celestialMessage(for sign: ZodiacSign) -> String {
        let moonPhase = currentMoonPhase
        let moonSign = currentMoonSign
        let transits = currentTransits
        
        var message = "With the \(moonPhase.rawValue) \(moonPhase.emoji) in \(moonSign.rawValue), you may feel \(moonSign.emotionalFlavor). "
        
        if let primaryTransit = transits.first {
            message += "\(primaryTransit.planet) \(primaryTransit.aspect) adds \(transitFlavor(for: primaryTransit, sign: sign)). "
        }
        
        message += signSpecificAdvice(for: sign, moonPhase: moonPhase, moonSign: moonSign)
        
        return message
    }
    
    private static func transitFlavor(for transit: PlanetaryTransit, sign: ZodiacSign) -> String {
        switch transit.planet {
        case "Venus":
            return "a touch of grace and beauty to your connections"
        case "Mars":
            return "dynamic energy to fuel your ambitions"
        case "Mercury":
            return "clarity to your thoughts and communications"
        case "Jupiter":
            return "expansion and optimism to your outlook"
        case "Saturn":
            return "structure and wisdom to your endeavors"
        case "Sun":
            return "illumination to your path forward"
        default:
            return "cosmic support to your journey"
        }
    }
    
    private static func signSpecificAdvice(for sign: ZodiacSign, moonPhase: MoonPhase, moonSign: MoonSign) -> String {
        let element = sign.element
        
        switch element {
        case "Fire":
            if moonPhase == .fullMoon || moonPhase == .waxingGibbous {
                return "Channel this luminous energy into creative expression. Your passion can inspire others—share it generously."
            } else {
                return "Honor your need for action while staying grounded. Small, intentional steps lead to lasting victories."
            }
        case "Earth":
            if moonPhase == .newMoon || moonPhase == .waxingCrescent {
                return "Plant seeds for practical goals now. Your steady approach transforms dreams into reality."
            } else {
                return "Appreciate the tangible progress you've made. Celebrate small wins and nurture what you've built."
            }
        case "Air":
            if moonSign == .gemini || moonSign == .libra || moonSign == .aquarius {
                return "Your intellectual insights are especially sharp. Share your ideas—they're meant to circulate and connect."
            } else {
                return "Balance mental activity with moments of stillness. Your best insights come when you give your mind space to breathe."
            }
        case "Water":
            if moonPhase == .fullMoon || moonSign == .cancer || moonSign == .scorpio || moonSign == .pisces {
                return "Your emotional antennae are finely tuned. Trust your intuition—it's your most reliable guide right now."
            } else {
                return "Honor your sensitivity as a superpower. Create sacred space for emotional processing and self-care."
            }
        default:
            return moonPhase.guidance
        }
    }
    
    private static let defaultReadings: [Horoscope] = [
        Horoscope(
            sign: .aries,
            weeklyReading: "The stars align in your favor this week.",
            loveAdvice: "Open your heart to new possibilities.",
            careerAdvice: "Take initiative on that project you've been postponing.",
            luckyNumber: 7,
            luckyColor: "Red",
            compatibility: .leo,
            mood: "Energetic",
            celestialInsight: "The cosmos supports bold moves—trust your instincts and take the lead."
        )
    ]
    
    private static let horoscopeReadings: [ZodiacSign: [Horoscope]] = [
        .aries: [
            Horoscope(
                sign: .aries,
                weeklyReading: "Your fiery energy is at its peak this week. Bold moves in your career could lead to unexpected rewards. Trust your instincts when making decisions—they won't lead you astray. A conversation with a friend might reveal a new perspective you hadn't considered.",
                loveAdvice: "Passion runs high. If single, someone magnetic may enter your orbit. If attached, plan something spontaneous.",
                careerAdvice: "Leadership opportunities are coming. Don't shy away from taking charge.",
                luckyNumber: 9,
                luckyColor: "Crimson",
                compatibility: .sagittarius,
                mood: "Adventurous",
                celestialInsight: "With Mars amplifying your natural fire, channel this surge into meaningful pursuits. The cosmic warriors favor those who act with both courage and compassion."
            ),
            Horoscope(
                sign: .aries,
                weeklyReading: "Mars energizes your communication sector, making this an excellent time for important conversations. Your natural charisma is amplified—use it wisely. Financial matters require careful attention; avoid impulsive purchases.",
                loveAdvice: "Express your feelings openly. Vulnerability can deepen connections.",
                careerAdvice: "Networking events favor you. Make those connections count.",
                luckyNumber: 3,
                luckyColor: "Orange",
                compatibility: .leo,
                mood: "Confident",
                celestialInsight: "Mercury's dance with your ruling planet Mars sharpens your words into arrows of truth. Speak boldly, but aim with intention—your voice carries extra power now."
            )
        ],
        .taurus: [
            Horoscope(
                sign: .taurus,
                weeklyReading: "Venus graces your sign, bringing harmony and beauty into your daily life. This is a wonderful time for self-care and indulgence. Financial stability improves, but don't rest on your laurels—keep building your foundation.",
                loveAdvice: "Romance blooms through shared experiences. Plan a cozy evening in.",
                careerAdvice: "Steady progress beats rushing. Your patience will be rewarded.",
                luckyNumber: 6,
                luckyColor: "Emerald Green",
                compatibility: .virgo,
                mood: "Content",
                celestialInsight: "Venus, your ruling planet, bathes you in her gentle light. Embrace sensory pleasures guilt-free—a beautiful meal, soft music, or time in nature replenishes your soul."
            ),
            Horoscope(
                sign: .taurus,
                weeklyReading: "Your practical nature serves you well as complex situations arise. Others look to you for stability and wisdom. A creative project may capture your attention—give it the time it deserves.",
                loveAdvice: "Physical affection strengthens bonds. Don't underestimate the power of touch.",
                careerAdvice: "Your reliability is noticed. A reward or recognition may come your way.",
                luckyNumber: 4,
                luckyColor: "Rose",
                compatibility: .cancer,
                mood: "Grounded",
                celestialInsight: "The Earth trines between planets support your natural steadfastness. Plant seeds now—both literal and metaphorical—and watch them flourish with patient nurturing."
            )
        ],
        .gemini: [
            Horoscope(
                sign: .gemini,
                weeklyReading: "Mercury's influence sparks your intellectual curiosity. New information comes your way that could change your perspective on something important. Social gatherings are favored—your wit and charm will be in high demand.",
                loveAdvice: "Mental connection matters most now. Engage in deep conversations.",
                careerAdvice: "Your adaptability is your superpower. Multiple projects? You've got this.",
                luckyNumber: 5,
                luckyColor: "Yellow",
                compatibility: .libra,
                mood: "Curious",
                celestialInsight: "Mercury wings through favorable aspects, accelerating your thoughts and conversations. Write down your ideas—they're coming faster than usual and deserve to be captured."
            ),
            Horoscope(
                sign: .gemini,
                weeklyReading: "The twin energy within you seeks balance. Take time to integrate your different sides. Short trips or local adventures could bring unexpected joy and inspiration.",
                loveAdvice: "Variety keeps things fresh. Try something new together.",
                careerAdvice: "Communication skills shine. Present your ideas with confidence.",
                luckyNumber: 11,
                luckyColor: "Silver",
                compatibility: .aquarius,
                mood: "Playful",
                celestialInsight: "Air signs are harmonizing in the cosmos, creating a symphony of mental clarity. Your dual nature is a gift—let both sides of yourself express and explore."
            )
        ],
        .cancer: [
            Horoscope(
                sign: .cancer,
                weeklyReading: "The Moon highlights your emotional intelligence. Trust your intuition—it's sharper than ever. Home and family matters take center stage. Creating a nurturing environment brings deep satisfaction.",
                loveAdvice: "Emotional security is paramount. Create safe spaces for vulnerable sharing.",
                careerAdvice: "Your empathetic leadership style wins support from colleagues.",
                luckyNumber: 2,
                luckyColor: "Pearl White",
                compatibility: .scorpio,
                mood: "Nurturing",
                celestialInsight: "The Moon, your celestial mother, whispers secrets only you can hear. Create a cozy sanctuary and let your intuition speak—it knows the way forward."
            ),
            Horoscope(
                sign: .cancer,
                weeklyReading: "Your protective shell serves you well, but don't retreat entirely. Someone needs your compassion this week. Financial intuition is strong—trust your gut on investments.",
                loveAdvice: "Past wounds may surface for healing. Approach them with self-compassion.",
                careerAdvice: "Creative projects flourish. Let your imagination guide you.",
                luckyNumber: 7,
                luckyColor: "Moonstone Blue",
                compatibility: .pisces,
                mood: "Reflective",
                celestialInsight: "Water signs receive Neptune's blessing this week. Your emotional depth is your superpower—don't hide from feelings, let them flow like healing waters."
            )
        ],
        .leo: [
            Horoscope(
                sign: .leo,
                weeklyReading: "The Sun, your ruling planet, amplifies your natural radiance. This is your time to shine! Creative pursuits and self-expression bring joy. Recognition for your efforts is on the horizon.",
                loveAdvice: "Grand romantic gestures are favored. Make your loved one feel special.",
                careerAdvice: "Step into the spotlight. Your talents deserve to be seen.",
                luckyNumber: 1,
                luckyColor: "Gold",
                compatibility: .aries,
                mood: "Radiant",
                celestialInsight: "The Sun blazes in harmony with Jupiter, expanding your natural warmth and charisma. Your light illuminates others—share it generously, and watch abundance return tenfold."
            ),
            Horoscope(
                sign: .leo,
                weeklyReading: "Your generous heart attracts abundance. Share your warmth with others, but remember to reserve some energy for yourself. A child or creative project may bring unexpected joy.",
                loveAdvice: "Loyalty is tested and proven. Your devotion inspires others.",
                careerAdvice: "Leadership roles suit you now. Others look to you for direction.",
                luckyNumber: 8,
                luckyColor: "Amber",
                compatibility: .sagittarius,
                mood: "Generous",
                celestialInsight: "Venus graces your sign with artistic inspiration. Create something beautiful—whether art, music, or memorable moments with loved ones. Your heart is the compass."
            )
        ],
        .virgo: [
            Horoscope(
                sign: .virgo,
                weeklyReading: "Mercury sharpens your analytical mind. Details that others miss are crystal clear to you. Health and wellness routines bring positive results. Organization brings peace of mind.",
                loveAdvice: "Show love through acts of service. Small gestures mean everything.",
                careerAdvice: "Your attention to detail saves the day. Excellence is noticed.",
                luckyNumber: 5,
                luckyColor: "Forest Green",
                compatibility: .taurus,
                mood: "Productive",
                celestialInsight: "Mercury trines Saturn, blessing your meticulous nature with cosmic support. Your careful planning manifests real results—trust your process and watch order emerge from chaos."
            ),
            Horoscope(
                sign: .virgo,
                weeklyReading: "Your perfectionist tendencies can be channeled positively this week. A project reaches completion with your careful guidance. Don't forget to celebrate small victories.",
                loveAdvice: "Release the need for perfection in relationships. Embrace beautiful imperfection.",
                careerAdvice: "Systems and processes you create will have lasting impact.",
                luckyNumber: 3,
                luckyColor: "Sage",
                compatibility: .capricorn,
                mood: "Methodical",
                celestialInsight: "Earth energy grounds the cosmic flow this week. Your practical wisdom is needed—share your insights while remembering that sometimes 'good enough' is perfect."
            )
        ],
        .libra: [
            Horoscope(
                sign: .libra,
                weeklyReading: "Venus enhances your natural grace and diplomacy. Relationships of all kinds benefit from your balanced approach. Beauty and art inspire you—visit a gallery or create something yourself.",
                loveAdvice: "Partnership harmony is achievable. Compromise comes naturally.",
                careerAdvice: "Collaboration over competition wins the day.",
                luckyNumber: 6,
                luckyColor: "Soft Pink",
                compatibility: .gemini,
                mood: "Harmonious",
                celestialInsight: "Venus forms a gentle trine with Neptune, heightening your aesthetic sensibilities and romantic imagination. Surround yourself with beauty—it feeds your soul and inspires your best self."
            ),
            Horoscope(
                sign: .libra,
                weeklyReading: "Your scales tip toward justice this week. Stand up for what's right, even when it's uncomfortable. Social invitations abound—choose the ones that truly nourish your soul.",
                loveAdvice: "Balance giving and receiving in love. You deserve reciprocity.",
                careerAdvice: "Negotiation skills are sharp. Close that deal with confidence.",
                luckyNumber: 2,
                luckyColor: "Lavender",
                compatibility: .aquarius,
                mood: "Diplomatic",
                celestialInsight: "Mars energizes your partnerships sector, adding passion to diplomacy. Your natural balance becomes dynamic—use this energy to advocate for fairness with fire."
            )
        ],
        .scorpio: [
            Horoscope(
                sign: .scorpio,
                weeklyReading: "Pluto's transformative energy runs deep. Old patterns ready to be released make way for powerful new beginnings. Your intensity attracts others—use this magnetism wisely.",
                loveAdvice: "Deep emotional bonds strengthen. Intimacy reaches new levels.",
                careerAdvice: "Research and investigation reveal important truths.",
                luckyNumber: 8,
                luckyColor: "Burgundy",
                compatibility: .cancer,
                mood: "Intense",
                celestialInsight: "Pluto, your ruling planet, harmonizes with the transformative currents flowing through the cosmos. Shed what no longer serves you like a phoenix—rebirth awaits on the other side."
            ),
            Horoscope(
                sign: .scorpio,
                weeklyReading: "Your regenerative powers are strong. What seemed impossible becomes achievable through sheer determination. Secrets may be revealed—handle them with your characteristic discretion.",
                loveAdvice: "Trust is earned through consistency. Show up for your loved ones.",
                careerAdvice: "Strategic thinking gives you an edge. Play the long game.",
                luckyNumber: 13,
                luckyColor: "Black",
                compatibility: .pisces,
                mood: "Powerful",
                celestialInsight: "Mars fuels your investigative powers while Neptune deepens your intuition. Trust the mysteries that call to you—your ability to see beneath surfaces is a gift."
            )
        ],
        .sagittarius: [
            Horoscope(
                sign: .sagittarius,
                weeklyReading: "Jupiter expands your horizons. Travel, education, or philosophical pursuits call to you. Your optimism is contagious—spread it generously. Adventure awaits around every corner.",
                loveAdvice: "Freedom within commitment is possible. Discuss boundaries openly.",
                careerAdvice: "Big-picture thinking impresses higher-ups. Share your vision.",
                luckyNumber: 9,
                luckyColor: "Royal Purple",
                compatibility: .aries,
                mood: "Optimistic",
                celestialInsight: "Jupiter, your magnificent ruler, expands everything it touches. Aim your arrow at the stars—the cosmos supports bold visions and big dreams. Your optimism is medicine for the world."
            ),
            Horoscope(
                sign: .sagittarius,
                weeklyReading: "Your arrow aims true this week. Goals that seemed distant are within reach. Foreign connections or international opportunities may present themselves.",
                loveAdvice: "Honesty, even when uncomfortable, strengthens relationships.",
                careerAdvice: "Teaching or mentoring roles suit you now. Share your wisdom.",
                luckyNumber: 7,
                luckyColor: "Turquoise",
                compatibility: .leo,
                mood: "Adventurous",
                celestialInsight: "Fire trines activate your natural enthusiasm. Share your hard-won wisdom with others—your experiences contain lessons that can light another's path."
            )
        ],
        .capricorn: [
            Horoscope(
                sign: .capricorn,
                weeklyReading: "Saturn rewards your discipline and hard work. Long-term goals see tangible progress. Your reputation for reliability opens new doors. Structure brings comfort rather than constraint.",
                loveAdvice: "Show your softer side. Vulnerability is strength, not weakness.",
                careerAdvice: "Career advancement is likely. Your efforts are finally recognized.",
                luckyNumber: 4,
                luckyColor: "Charcoal",
                compatibility: .virgo,
                mood: "Ambitious",
                celestialInsight: "Saturn, your wise taskmaster, trines supportive planets. Your patient efforts are crystallizing into lasting achievement. The mountain you're climbing has a view worth every step."
            ),
            Horoscope(
                sign: .capricorn,
                weeklyReading: "The mountain goat climbs steadily upward. Each step, no matter how small, brings you closer to the summit. Authority figures look favorably upon you.",
                loveAdvice: "Quality time matters more than grand gestures. Be present.",
                careerAdvice: "Long-term planning pays dividends. Think five years ahead.",
                luckyNumber: 10,
                luckyColor: "Navy",
                compatibility: .taurus,
                mood: "Determined",
                celestialInsight: "Pluto continues its transformative journey through your sign, urging authentic power. Build legacies, not just success—what you create now echoes into the future."
            )
        ],
        .aquarius: [
            Horoscope(
                sign: .aquarius,
                weeklyReading: "Uranus sparks innovation and originality. Your unique perspective is your greatest asset. Community involvement brings fulfillment. Technology and future-thinking ideas flow freely.",
                loveAdvice: "Friendship is the foundation of lasting love. Cultivate it.",
                careerAdvice: "Revolutionary ideas are welcomed. Don't hold back your vision.",
                luckyNumber: 11,
                luckyColor: "Electric Blue",
                compatibility: .libra,
                mood: "Innovative",
                celestialInsight: "Uranus electrifies your sector of self-expression with brilliant flashes of insight. Your unconventional ideas are ahead of their time—share them fearlessly with your community."
            ),
            Horoscope(
                sign: .aquarius,
                weeklyReading: "Your humanitarian instincts guide you toward meaningful action. Group projects thrive under your unconventional leadership. Unexpected connections prove valuable.",
                loveAdvice: "Independence and togetherness can coexist. Find your balance.",
                careerAdvice: "Networking in unexpected places leads to opportunities.",
                luckyNumber: 22,
                luckyColor: "Violet",
                compatibility: .gemini,
                mood: "Visionary",
                celestialInsight: "Saturn grounds your visionary nature while Uranus sparks innovation. You're uniquely positioned to build bridges between tradition and revolution—be the change you envision."
            )
        ],
        .pisces: [
            Horoscope(
                sign: .pisces,
                weeklyReading: "Neptune enhances your already powerful intuition. Dreams carry important messages—pay attention. Creative and spiritual pursuits bring deep fulfillment. Your compassion heals others.",
                loveAdvice: "Soulmate connections deepen. Trust the universe's timing.",
                careerAdvice: "Artistic and healing professions are especially favored.",
                luckyNumber: 12,
                luckyColor: "Sea Green",
                compatibility: .scorpio,
                mood: "Dreamy",
                celestialInsight: "Neptune, your mystical ruler, opens portals to the divine. Your dreams are messages from the cosmos—keep a journal by your bed and let your imagination guide you to hidden treasures."
            ),
            Horoscope(
                sign: .pisces,
                weeklyReading: "Your empathic abilities are heightened. Remember to protect your energy while helping others. Water activities bring peace and clarity. A creative breakthrough is possible.",
                loveAdvice: "Romantic idealism meets reality. Accept loved ones as they are.",
                careerAdvice: "Trust your creative instincts. They lead to success.",
                luckyNumber: 7,
                luckyColor: "Ocean Blue",
                compatibility: .cancer,
                mood: "Intuitive",
                celestialInsight: "Venus blesses Neptune with artistic grace, turning your inner visions into tangible beauty. Create without judgment—your sensitivity transforms raw emotion into art that touches souls."
            )
        ]
    ]
}

