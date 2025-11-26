import SwiftUI
import SwiftData
import UIKit

struct ContactRowView: View {
    let contact: Contact
    
    private func elementColor(for sign: ZodiacSign) -> Color {
        switch sign.element {
        case "Fire": return .orange
        case "Earth": return .green
        case "Air": return .purple
        case "Water": return .cyan
        default: return .gray
        }
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            // Avatar with zodiac element color
            ZStack {
                if let imageData = contact.profileImageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [elementColor(for: contact.zodiacSign), elementColor(for: contact.zodiacSign).opacity(0.5)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                } else {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [elementColor(for: contact.zodiacSign).opacity(0.3), elementColor(for: contact.zodiacSign).opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                    
                    Text(contact.name.prefix(1).uppercased())
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(elementColor(for: contact.zodiacSign))
                }
            }
            
            // Contact Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(contact.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if contact.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                    }
                }
                
                // Zodiac sign info
                HStack(spacing: 4) {
                    if contact.zodiacSign.isMissingInfo {
                        Image(systemName: "questionmark.circle")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text("Missing Info")
                            .font(.caption)
                            .foregroundColor(.orange.opacity(0.8))
                    } else {
                        Text(contact.zodiacSign.emoji)
                            .font(.caption)
                        Text(contact.zodiacSign.rawValue)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        Text("•")
                            .foregroundColor(.white.opacity(0.3))
                        Text(contact.zodiacSign.element)
                            .font(.caption)
                            .foregroundColor(elementColor(for: contact.zodiacSign).opacity(0.8))
                    }
                }
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.white.opacity(0.06))
        .cornerRadius(16)
    }
}
