import SwiftUI

// MARK: - Compatibility View
struct CompatibilityView: View {
    let contact: Contact
    @State private var userSign: ZodiacSign = .aries
    @AppStorage("userZodiacSign") private var savedUserSign: String = "Aries"
    @Environment(\.dismiss) private var dismiss
    
    var compatibility: AstralCompatibility {
        AstralCompatibility(person1Sign: userSign, person2Sign: contact.zodiacSign)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with both signs
                    headerView
                    
                    // Harmony Score
                    harmonyScoreView
                    
                    // Poetic Summary
                    poeticSummaryView
                    
                    // Oracle Reading
                    oracleReadingView
                    
                    // Elemental & Modality Dynamic
                    dynamicsView
                    
                    // Strengths
                    strengthsView
                    
                    // Growth Opportunities
                    growthView
                    
                    // Nurturing Advice
                    nurturingAdviceView
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [Color(red: 0.05, green: 0.05, blue: 0.15), Color(red: 0.1, green: 0.05, blue: 0.2)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Compatibility")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .onAppear {
                if let sign = ZodiacSign(rawValue: savedUserSign) {
                    userSign = sign
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 16) {
            Text("The Oracle of Harmony")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.6))
                .tracking(2)
            
            HStack(spacing: 24) {
                // User sign
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(elementGradient(for: userSign))
                            .frame(width: 80, height: 80)
                        
                        Text(userSign.emoji)
                            .font(.system(size: 40))
                    }
                    
                    Text("You")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Menu {
                        ForEach(ZodiacSign.allCases, id: \.self) { sign in
                            Button {
                                userSign = sign
                                savedUserSign = sign.rawValue
                            } label: {
                                Label(sign.rawValue, systemImage: sign == userSign ? "checkmark" : "")
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(userSign.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                        }
                        .foregroundColor(.white)
                    }
                }
                
                // Connection indicator
                VStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.pink, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text(compatibility.harmonyLevel.emoji)
                        .font(.title3)
                }
                
                // Contact sign
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(elementGradient(for: contact.zodiacSign))
                            .frame(width: 80, height: 80)
                        
                        Text(contact.zodiacSign.emoji)
                            .font(.system(size: 40))
                    }
                    
                    Text(contact.name.components(separatedBy: " ").first ?? contact.name)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                    
                    Text(contact.zodiacSign.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Harmony Score View
    private var harmonyScoreView: some View {
        VStack(spacing: 12) {
            // Score circle
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 8)
                    .frame(width: 100, height: 100)
                
                Circle()
                    .trim(from: 0, to: CGFloat(compatibility.harmonyScore) / 100)
                    .stroke(
                        LinearGradient(
                            colors: harmonyColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 2) {
                    Text("\(compatibility.harmonyScore)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("harmony")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            // Harmony level
            VStack(spacing: 4) {
                Text(compatibility.harmonyLevel.rawValue)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(compatibility.harmonyLevel.description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.05))
        .cornerRadius(20)
    }
    
    // MARK: - Poetic Summary View
    private var poeticSummaryView: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            Text(compatibility.poeticSummary)
                .font(.body)
                .italic()
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color.purple.opacity(0.2), Color.indigo.opacity(0.15)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
    }
    
    // MARK: - Oracle Reading View
    private var oracleReadingView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("The Oracle Speaks", systemImage: "moon.stars.fill")
                .font(.headline)
                .foregroundColor(.white)
            
            Text(compatibility.oracleReading)
                .font(.body)
                .foregroundColor(.white.opacity(0.85))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    // MARK: - Dynamics View
    private var dynamicsView: some View {
        HStack(spacing: 12) {
            // Elemental Dynamic
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: elementIcon(for: userSign))
                        .foregroundColor(elementColor(for: userSign))
                    Text("+")
                        .foregroundColor(.white.opacity(0.5))
                    Image(systemName: elementIcon(for: contact.zodiacSign))
                        .foregroundColor(elementColor(for: contact.zodiacSign))
                }
                .font(.title3)
                
                Text("Elements")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                
                Text(compatibility.elementalDynamic.description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
            
            // Modality Dynamic
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(userSign.modality.rawValue.prefix(3))
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(4)
                    
                    Text("+")
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text(contact.zodiacSign.modality.rawValue.prefix(3))
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(4)
                }
                .foregroundColor(.white)
                
                Text("Modalities")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                
                Text(compatibility.modalityDynamic.description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Strengths View
    private var strengthsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Your Strengths Together", systemImage: "star.fill")
                .font(.headline)
                .foregroundColor(.yellow)
            
            ForEach(compatibility.strengths, id: \.self) { strength in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.subheadline)
                    
                    Text(strength)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.green.opacity(0.1))
        .cornerRadius(16)
    }
    
    // MARK: - Growth View
    private var growthView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Growth Opportunities", systemImage: "leaf.fill")
                .font(.headline)
                .foregroundColor(.mint)
            
            ForEach(compatibility.growthOpportunities, id: \.self) { opportunity in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(.mint)
                        .font(.subheadline)
                    
                    Text(opportunity)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.mint.opacity(0.1))
        .cornerRadius(16)
    }
    
    // MARK: - Nurturing Advice View
    private var nurturingAdviceView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Nurturing Your Bond", systemImage: "heart.circle.fill")
                .font(.headline)
                .foregroundColor(.pink)
            
            Text(compatibility.nurturingAdvice)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.85))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.pink.opacity(0.15), Color.purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .padding(.bottom, 20)
    }
    
    // MARK: - Helper Functions
    
    private var harmonyColors: [Color] {
        switch compatibility.harmonyLevel {
        case .soulmates:
            return [.yellow, .orange, .pink]
        case .deepConnection:
            return [.purple, .pink]
        case .harmoniousFlow:
            return [.blue, .cyan]
        case .growthPartners:
            return [.green, .mint]
        case .dynamicTension:
            return [.orange, .red]
        }
    }
    
    private func elementGradient(for sign: ZodiacSign) -> LinearGradient {
        let colors: [Color]
        switch sign.element {
        case "Fire":
            colors = [.red, .orange]
        case "Earth":
            colors = [.green, .brown]
        case "Air":
            colors = [.purple, .indigo]
        case "Water":
            colors = [.blue, .cyan]
        default:
            colors = [.gray, .secondary]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    private func elementIcon(for sign: ZodiacSign) -> String {
        switch sign.element {
        case "Fire": return "flame.fill"
        case "Earth": return "leaf.fill"
        case "Air": return "wind"
        case "Water": return "drop.fill"
        default: return "star.fill"
        }
    }
    
    private func elementColor(for sign: ZodiacSign) -> Color {
        switch sign.element {
        case "Fire": return .orange
        case "Earth": return .green
        case "Air": return .purple
        case "Water": return .cyan
        default: return .gray
        }
    }
}

// MARK: - Quick Compatibility Badge (for use in lists)
struct CompatibilityBadge: View {
    let userSign: ZodiacSign
    let contactSign: ZodiacSign
    
    var compatibility: AstralCompatibility {
        AstralCompatibility(person1Sign: userSign, person2Sign: contactSign)
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Text(compatibility.harmonyLevel.emoji)
                .font(.caption2)
            
            Text("\(compatibility.harmonyScore)%")
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(badgeColor.opacity(0.2))
        .foregroundColor(badgeColor)
        .cornerRadius(8)
    }
    
    private var badgeColor: Color {
        switch compatibility.harmonyLevel {
        case .soulmates: return .yellow
        case .deepConnection: return .purple
        case .harmoniousFlow: return .blue
        case .growthPartners: return .green
        case .dynamicTension: return .orange
        }
    }
}

