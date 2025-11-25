import Foundation

// MARK: - Natal Chart
/// Represents a person's astrological birth chart with Sun, Moon, and Rising signs
struct NatalChart {
    let birthDate: Date
    let birthTime: Date?
    let birthPlace: String?
    
    // MARK: - Sun Sign (from birth date)
    var sunSign: ZodiacSign {
        ZodiacSign.from(birthday: birthDate)
    }
    
    // MARK: - Moon Sign (approximate without time, more precise with time)
    var moonSign: ZodiacSign {
        calculateMoonSign()
    }
    
    // MARK: - Rising Sign / Ascendant (requires birth time)
    var risingSign: ZodiacSign? {
        guard birthTime != nil else { return nil }
        return calculateRisingSign()
    }
    
    // MARK: - Completeness
    var hasFullChart: Bool {
        birthTime != nil && birthPlace != nil
    }
    
    var chartCompleteness: ChartCompleteness {
        if birthTime != nil && birthPlace != nil {
            return .full
        } else if birthTime != nil {
            return .partial
        } else {
            return .sunOnly
        }
    }
    
    // MARK: - Moon Sign Calculation
    /// Calculates approximate Moon sign based on birth date
    /// The Moon moves through all 12 signs in about 27.3 days (~2.3 days per sign)
    private func calculateMoonSign() -> ZodiacSign {
        let calendar = Calendar.current
        
        // Reference: January 1, 2000 the Moon was approximately in Cancer
        let referenceDate = calendar.date(from: DateComponents(year: 2000, month: 1, day: 1))!
        let referenceMoonSign = ZodiacSign.cancer
        
        let daysSinceReference = calendar.dateComponents([.day], from: referenceDate, to: birthDate).day ?? 0
        
        // Moon completes cycle in ~27.3 days
        let lunarCycle = 27.3
        let daysPerSign = lunarCycle / 12.0
        
        // Calculate how many signs the Moon has moved
        let signsMoved = Int(Double(daysSinceReference) / daysPerSign)
        
        // Get the reference sign index
        let referenceIndex = ZodiacSign.allCases.firstIndex(of: referenceMoonSign) ?? 0
        
        // Calculate current moon sign index
        let moonIndex = (referenceIndex + signsMoved) % 12
        
        // Adjust if we have birth time for more precision
        if let time = birthTime {
            let hour = calendar.component(.hour, from: time)
            // Moon moves ~0.5 degrees per hour, so 12 hours = ~half a sign
            let hourAdjustment = hour >= 12 ? 1 : 0
            let adjustedIndex = (moonIndex + hourAdjustment) % 12
            return ZodiacSign.allCases[adjustedIndex]
        }
        
        return ZodiacSign.allCases[moonIndex]
    }
    
    // MARK: - Rising Sign Calculation
    /// Calculates Rising sign (Ascendant) based on birth time and approximate location
    /// Rising sign changes every ~2 hours
    private func calculateRisingSign() -> ZodiacSign {
        guard let time = birthTime else {
            return sunSign // Fallback to Sun sign
        }
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: time)
        let minute = calendar.component(.minute, from: time)
        
        // Convert to decimal hour
        let decimalHour = Double(hour) + Double(minute) / 60.0
        
        // Get the Sun sign at birth
        let sunSignIndex = ZodiacSign.allCases.firstIndex(of: sunSign) ?? 0
        
        // Rising sign calculation:
        // At sunrise (~6am), Rising = Sun sign
        // Each 2 hours adds one sign
        // Adjust for time zone approximation based on birth place
        var timeOffset = 0.0
        if let place = birthPlace?.lowercased() {
            // Very rough timezone approximations
            if place.contains("paris") || place.contains("france") || place.contains("europe") {
                timeOffset = 1.0
            } else if place.contains("new york") || place.contains("usa") || place.contains("america") {
                timeOffset = -5.0
            } else if place.contains("tokyo") || place.contains("japan") {
                timeOffset = 9.0
            } else if place.contains("london") || place.contains("uk") {
                timeOffset = 0.0
            } else if place.contains("sydney") || place.contains("australia") {
                timeOffset = 10.0
            }
        }
        
        // Adjust hour for approximate timezone
        let adjustedHour = decimalHour + timeOffset
        
        // Calculate rising sign offset from sunrise (assume 6am sunrise)
        let hoursFromSunrise = adjustedHour - 6.0
        let signsOffset = Int(hoursFromSunrise / 2.0)
        
        // Rising sign index
        let risingIndex = (sunSignIndex + signsOffset + 12) % 12
        
        return ZodiacSign.allCases[risingIndex]
    }
    
    // MARK: - Chart Description
    var description: String {
        var desc = "☀️ Sun in \(sunSign.rawValue)"
        desc += "\n🌙 Moon in \(moonSign.rawValue)"
        if let rising = risingSign {
            desc += "\n⬆️ Rising in \(rising.rawValue)"
        }
        return desc
    }
}

// MARK: - Chart Completeness
enum ChartCompleteness {
    case sunOnly
    case partial // Has time but no place
    case full // Has time and place
    
    var description: String {
        switch self {
        case .sunOnly:
            return "Basic Chart (Sun sign only)"
        case .partial:
            return "Partial Chart (Sun + Moon)"
        case .full:
            return "Full Chart (Sun + Moon + Rising)"
        }
    }
    
    var emoji: String {
        switch self {
        case .sunOnly: return "☀️"
        case .partial: return "☀️🌙"
        case .full: return "☀️🌙⬆️"
        }
    }
}

// MARK: - Contact Extension for Natal Chart
extension Contact {
    var natalChart: NatalChart? {
        guard let birthday = birthday else { return nil }
        return NatalChart(
            birthDate: birthday,
            birthTime: birthTime,
            birthPlace: birthPlace
        )
    }
    
    var moonSign: ZodiacSign? {
        natalChart?.moonSign
    }
    
    var risingSign: ZodiacSign? {
        natalChart?.risingSign
    }
    
    var chartCompleteness: ChartCompleteness {
        natalChart?.chartCompleteness ?? .sunOnly
    }
}

// MARK: - Zodiac Sign Personality Traits
extension ZodiacSign {
    var sunTraits: String {
        switch self {
        case .aries: return "courageous, pioneering, and action-oriented"
        case .taurus: return "grounded, sensual, and steadfast"
        case .gemini: return "curious, communicative, and adaptable"
        case .cancer: return "nurturing, intuitive, and protective"
        case .leo: return "creative, generous, and warm-hearted"
        case .virgo: return "analytical, helpful, and detail-oriented"
        case .libra: return "diplomatic, harmonious, and partnership-focused"
        case .scorpio: return "intense, transformative, and deeply perceptive"
        case .sagittarius: return "adventurous, philosophical, and optimistic"
        case .capricorn: return "ambitious, disciplined, and achievement-oriented"
        case .aquarius: return "innovative, humanitarian, and independent"
        case .pisces: return "compassionate, imaginative, and spiritually attuned"
        }
    }
    
    var moonTraits: String {
        switch self {
        case .aries: return "emotionally direct, needs independence, quick to react"
        case .taurus: return "emotionally stable, needs security, slow to change"
        case .gemini: return "emotionally curious, needs mental stimulation, changeable moods"
        case .cancer: return "emotionally deep, needs nurturing, highly intuitive"
        case .leo: return "emotionally warm, needs appreciation, generous with feelings"
        case .virgo: return "emotionally reserved, needs order, processes through analysis"
        case .libra: return "emotionally balanced, needs harmony, dislikes conflict"
        case .scorpio: return "emotionally intense, needs depth, all-or-nothing feelings"
        case .sagittarius: return "emotionally free, needs adventure, optimistic outlook"
        case .capricorn: return "emotionally controlled, needs achievement, reserved expression"
        case .aquarius: return "emotionally detached, needs freedom, unconventional feelings"
        case .pisces: return "emotionally boundless, needs creativity, absorbs others' emotions"
        }
    }
    
    var risingTraits: String {
        switch self {
        case .aries: return "comes across as bold, direct, and energetic"
        case .taurus: return "comes across as calm, reliable, and sensual"
        case .gemini: return "comes across as witty, curious, and youthful"
        case .cancer: return "comes across as caring, approachable, and protective"
        case .leo: return "comes across as confident, dramatic, and charismatic"
        case .virgo: return "comes across as modest, helpful, and observant"
        case .libra: return "comes across as charming, graceful, and fair-minded"
        case .scorpio: return "comes across as mysterious, intense, and magnetic"
        case .sagittarius: return "comes across as friendly, enthusiastic, and philosophical"
        case .capricorn: return "comes across as serious, capable, and professional"
        case .aquarius: return "comes across as unique, friendly, and progressive"
        case .pisces: return "comes across as dreamy, gentle, and artistic"
        }
    }
}

