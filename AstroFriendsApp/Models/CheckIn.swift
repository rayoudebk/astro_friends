import Foundation
import SwiftData

@Model
final class CheckIn {
    var id: UUID
    var date: Date
    var type: CheckInType
    var notes: String
    var contact: Contact?
    
    init(date: Date = Date(), type: CheckInType = .general, notes: String = "") {
        self.id = UUID()
        self.date = date
        self.type = type
        self.notes = notes
    }
}

enum CheckInType: String, Codable, CaseIterable {
    case general = "General"
    case call = "Call"
    case text = "Text"
    case meeting = "In Person"
    case video = "Video Call"
    case email = "Email"
    
    var icon: String {
        switch self {
        case .general: return "checkmark.circle"
        case .call: return "phone.fill"
        case .text: return "message.fill"
        case .meeting: return "person.2.fill"
        case .video: return "video.fill"
        case .email: return "envelope.fill"
        }
    }
}


