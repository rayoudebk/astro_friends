import Foundation

struct Horoscope {
    let sign: ZodiacSign
    let weeklyReading: String
    let loveAdvice: String
    let careerAdvice: String
    let luckyNumber: Int
    let luckyColor: String
    let compatibility: ZodiacSign
    let mood: String
    
    // Weekly horoscope readings - rotates based on week number
    static func getWeeklyHoroscope(for sign: ZodiacSign) -> Horoscope {
        let weekNumber = Calendar.current.component(.weekOfYear, from: Date())
        let readings = horoscopeReadings[sign] ?? defaultReadings
        let index = weekNumber % readings.count
        return readings[index]
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
            mood: "Energetic"
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
                mood: "Adventurous"
            ),
            Horoscope(
                sign: .aries,
                weeklyReading: "Mars energizes your communication sector, making this an excellent time for important conversations. Your natural charisma is amplified—use it wisely. Financial matters require careful attention; avoid impulsive purchases.",
                loveAdvice: "Express your feelings openly. Vulnerability can deepen connections.",
                careerAdvice: "Networking events favor you. Make those connections count.",
                luckyNumber: 3,
                luckyColor: "Orange",
                compatibility: .leo,
                mood: "Confident"
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
                mood: "Content"
            ),
            Horoscope(
                sign: .taurus,
                weeklyReading: "Your practical nature serves you well as complex situations arise. Others look to you for stability and wisdom. A creative project may capture your attention—give it the time it deserves.",
                loveAdvice: "Physical affection strengthens bonds. Don't underestimate the power of touch.",
                careerAdvice: "Your reliability is noticed. A reward or recognition may come your way.",
                luckyNumber: 4,
                luckyColor: "Rose",
                compatibility: .cancer,
                mood: "Grounded"
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
                mood: "Curious"
            ),
            Horoscope(
                sign: .gemini,
                weeklyReading: "The twin energy within you seeks balance. Take time to integrate your different sides. Short trips or local adventures could bring unexpected joy and inspiration.",
                loveAdvice: "Variety keeps things fresh. Try something new together.",
                careerAdvice: "Communication skills shine. Present your ideas with confidence.",
                luckyNumber: 11,
                luckyColor: "Silver",
                compatibility: .aquarius,
                mood: "Playful"
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
                mood: "Nurturing"
            ),
            Horoscope(
                sign: .cancer,
                weeklyReading: "Your protective shell serves you well, but don't retreat entirely. Someone needs your compassion this week. Financial intuition is strong—trust your gut on investments.",
                loveAdvice: "Past wounds may surface for healing. Approach them with self-compassion.",
                careerAdvice: "Creative projects flourish. Let your imagination guide you.",
                luckyNumber: 7,
                luckyColor: "Moonstone Blue",
                compatibility: .pisces,
                mood: "Reflective"
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
                mood: "Radiant"
            ),
            Horoscope(
                sign: .leo,
                weeklyReading: "Your generous heart attracts abundance. Share your warmth with others, but remember to reserve some energy for yourself. A child or creative project may bring unexpected joy.",
                loveAdvice: "Loyalty is tested and proven. Your devotion inspires others.",
                careerAdvice: "Leadership roles suit you now. Others look to you for direction.",
                luckyNumber: 8,
                luckyColor: "Amber",
                compatibility: .sagittarius,
                mood: "Generous"
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
                mood: "Productive"
            ),
            Horoscope(
                sign: .virgo,
                weeklyReading: "Your perfectionist tendencies can be channeled positively this week. A project reaches completion with your careful guidance. Don't forget to celebrate small victories.",
                loveAdvice: "Release the need for perfection in relationships. Embrace beautiful imperfection.",
                careerAdvice: "Systems and processes you create will have lasting impact.",
                luckyNumber: 3,
                luckyColor: "Sage",
                compatibility: .capricorn,
                mood: "Methodical"
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
                mood: "Harmonious"
            ),
            Horoscope(
                sign: .libra,
                weeklyReading: "Your scales tip toward justice this week. Stand up for what's right, even when it's uncomfortable. Social invitations abound—choose the ones that truly nourish your soul.",
                loveAdvice: "Balance giving and receiving in love. You deserve reciprocity.",
                careerAdvice: "Negotiation skills are sharp. Close that deal with confidence.",
                luckyNumber: 2,
                luckyColor: "Lavender",
                compatibility: .aquarius,
                mood: "Diplomatic"
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
                mood: "Intense"
            ),
            Horoscope(
                sign: .scorpio,
                weeklyReading: "Your regenerative powers are strong. What seemed impossible becomes achievable through sheer determination. Secrets may be revealed—handle them with your characteristic discretion.",
                loveAdvice: "Trust is earned through consistency. Show up for your loved ones.",
                careerAdvice: "Strategic thinking gives you an edge. Play the long game.",
                luckyNumber: 13,
                luckyColor: "Black",
                compatibility: .pisces,
                mood: "Powerful"
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
                mood: "Optimistic"
            ),
            Horoscope(
                sign: .sagittarius,
                weeklyReading: "Your arrow aims true this week. Goals that seemed distant are within reach. Foreign connections or international opportunities may present themselves.",
                loveAdvice: "Honesty, even when uncomfortable, strengthens relationships.",
                careerAdvice: "Teaching or mentoring roles suit you now. Share your wisdom.",
                luckyNumber: 7,
                luckyColor: "Turquoise",
                compatibility: .leo,
                mood: "Adventurous"
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
                mood: "Ambitious"
            ),
            Horoscope(
                sign: .capricorn,
                weeklyReading: "The mountain goat climbs steadily upward. Each step, no matter how small, brings you closer to the summit. Authority figures look favorably upon you.",
                loveAdvice: "Quality time matters more than grand gestures. Be present.",
                careerAdvice: "Long-term planning pays dividends. Think five years ahead.",
                luckyNumber: 10,
                luckyColor: "Navy",
                compatibility: .taurus,
                mood: "Determined"
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
                mood: "Innovative"
            ),
            Horoscope(
                sign: .aquarius,
                weeklyReading: "Your humanitarian instincts guide you toward meaningful action. Group projects thrive under your unconventional leadership. Unexpected connections prove valuable.",
                loveAdvice: "Independence and togetherness can coexist. Find your balance.",
                careerAdvice: "Networking in unexpected places leads to opportunities.",
                luckyNumber: 22,
                luckyColor: "Violet",
                compatibility: .gemini,
                mood: "Visionary"
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
                mood: "Dreamy"
            ),
            Horoscope(
                sign: .pisces,
                weeklyReading: "Your empathic abilities are heightened. Remember to protect your energy while helping others. Water activities bring peace and clarity. A creative breakthrough is possible.",
                loveAdvice: "Romantic idealism meets reality. Accept loved ones as they are.",
                careerAdvice: "Trust your creative instincts. They lead to success.",
                luckyNumber: 7,
                luckyColor: "Ocean Blue",
                compatibility: .cancer,
                mood: "Intuitive"
            )
        ]
    ]
}

