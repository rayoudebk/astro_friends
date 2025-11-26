import Foundation
import SwiftData

@Model
final class Contact {
    var id: UUID
    var name: String
    var phoneNumber: String?
    var email: String?
    var zodiacSign: ZodiacSign
    var frequencyDays: Int
    var preferredDayOfWeek: Int? // 1 = Sunday, 7 = Saturday
    var preferredHour: Int? // 0-23
    var lastCheckInDate: Date?
    var notes: String
    var isFavorite: Bool
    var createdAt: Date
    var reminders: [String] // Checklist items
    var giftIdea: String // Next gift idea
    var photosPersonLocalIdentifier: String? // Link to Photos app person
    var birthday: Date? // Birthday from contacts
    var birthTime: Date? // Time of birth (hour/minute)
    var birthPlace: String? // City/Country of birth
    var profileImageData: Data? // Profile image from contacts
    var contactIdentifier: String? // Original CNContact identifier
    var weMet: String // "We met..." text
    
    @Relationship(deleteRule: .cascade, inverse: \CheckIn.contact)
    var checkIns: [CheckIn]?
    
    init(
        name: String,
        phoneNumber: String? = nil,
        email: String? = nil,
        zodiacSign: ZodiacSign = .aries,
        frequencyDays: Int = 30, // Default to monthly
        preferredDayOfWeek: Int? = nil,
        preferredHour: Int? = nil,
        notes: String = "",
        isFavorite: Bool = false,
        reminders: [String] = [],
        giftIdea: String = "",
        photosPersonLocalIdentifier: String? = nil,
        birthday: Date? = nil,
        birthTime: Date? = nil,
        birthPlace: String? = nil,
        profileImageData: Data? = nil,
        contactIdentifier: String? = nil,
        weMet: String = ""
    ) {
        self.id = UUID()
        self.name = name
        self.phoneNumber = phoneNumber
        self.email = email
        self.zodiacSign = zodiacSign
        self.frequencyDays = frequencyDays
        self.preferredDayOfWeek = preferredDayOfWeek
        self.preferredHour = preferredHour
        self.notes = notes
        self.isFavorite = isFavorite
        self.reminders = reminders
        self.giftIdea = giftIdea
        self.photosPersonLocalIdentifier = photosPersonLocalIdentifier
        self.birthday = birthday
        self.birthTime = birthTime
        self.birthPlace = birthPlace
        self.profileImageData = profileImageData
        self.contactIdentifier = contactIdentifier
        self.weMet = weMet
        self.createdAt = Date()
        self.checkIns = []
    }
    
    var daysUntilNextCheckIn: Int {
        guard let lastCheckIn = lastCheckInDate else {
            return 0 // Overdue - no check-in yet
        }
        
        let daysSinceLastCheckIn = Calendar.current.dateComponents(
            [.day],
            from: lastCheckIn,
            to: Date()
        ).day ?? 0
        
        return max(0, frequencyDays - daysSinceLastCheckIn)
    }
    
    var isOverdue: Bool {
        daysUntilNextCheckIn == 0
    }
    
    var nextCheckInDate: Date? {
        guard let lastCheckIn = lastCheckInDate else {
            return Date()
        }
        return Calendar.current.date(byAdding: .day, value: frequencyDays, to: lastCheckIn)
    }
}

enum ZodiacSign: String, Codable, CaseIterable {
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
    
    var emoji: String {
        switch self {
        case .aries: return "♈️"
        case .taurus: return "♉️"
        case .gemini: return "♊️"
        case .cancer: return "♋️"
        case .leo: return "♌️"
        case .virgo: return "♍️"
        case .libra: return "♎️"
        case .scorpio: return "♏️"
        case .sagittarius: return "♐️"
        case .capricorn: return "♑️"
        case .aquarius: return "♒️"
        case .pisces: return "♓️"
        }
    }
    
    var icon: String {
        switch self {
        case .aries: return "flame.fill"
        case .taurus: return "leaf.fill"
        case .gemini: return "wind"
        case .cancer: return "drop.fill"
        case .leo: return "sun.max.fill"
        case .virgo: return "leaf.fill"
        case .libra: return "wind"
        case .scorpio: return "drop.fill"
        case .sagittarius: return "flame.fill"
        case .capricorn: return "mountain.2.fill"
        case .aquarius: return "wind"
        case .pisces: return "drop.fill"
        }
    }
    
    var element: String {
        switch self {
        case .aries, .leo, .sagittarius: return "Fire"
        case .taurus, .virgo, .capricorn: return "Earth"
        case .gemini, .libra, .aquarius: return "Air"
        case .cancer, .scorpio, .pisces: return "Water"
        }
    }
    
    var elementColor: String {
        switch element {
        case "Fire": return "red"
        case "Earth": return "green"
        case "Air": return "purple"
        case "Water": return "blue"
        default: return "gray"
        }
    }
    
    var dateRange: String {
        switch self {
        case .aries: return "Mar 21 - Apr 19"
        case .taurus: return "Apr 20 - May 20"
        case .gemini: return "May 21 - Jun 20"
        case .cancer: return "Jun 21 - Jul 22"
        case .leo: return "Jul 23 - Aug 22"
        case .virgo: return "Aug 23 - Sep 22"
        case .libra: return "Sep 23 - Oct 22"
        case .scorpio: return "Oct 23 - Nov 21"
        case .sagittarius: return "Nov 22 - Dec 21"
        case .capricorn: return "Dec 22 - Jan 19"
        case .aquarius: return "Jan 20 - Feb 18"
        case .pisces: return "Feb 19 - Mar 20"
        }
    }
    
    // Get zodiac sign from birthday
    static func from(birthday: Date) -> ZodiacSign {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: birthday)
        let day = calendar.component(.day, from: birthday)
        
        switch (month, day) {
        case (3, 21...31), (4, 1...19): return .aries
        case (4, 20...30), (5, 1...20): return .taurus
        case (5, 21...31), (6, 1...20): return .gemini
        case (6, 21...30), (7, 1...22): return .cancer
        case (7, 23...31), (8, 1...22): return .leo
        case (8, 23...31), (9, 1...22): return .virgo
        case (9, 23...30), (10, 1...22): return .libra
        case (10, 23...31), (11, 1...21): return .scorpio
        case (11, 22...30), (12, 1...21): return .sagittarius
        case (12, 22...31), (1, 1...19): return .capricorn
        case (1, 20...31), (2, 1...18): return .aquarius
        case (2, 19...29), (3, 1...20): return .pisces
        default: return .aries
        }
    }
}


