import Foundation
import Combine

// MARK: - New Content Manager
/// Tracks which weekly content the user has seen
/// Shows "New ✨" badges for fresh content
final class NewContentManager: ObservableObject {
    static let shared = NewContentManager()
    
    // MARK: - Published Properties
    @Published private(set) var unseenHoroscopeSigns: Set<String> = []
    @Published private(set) var unseenCompatibilityPairs: Set<String> = []
    
    // MARK: - UserDefaults Keys
    private enum Keys {
        static let horoscopeSeenWeeks = "new_content_horoscope_seen_weeks"  // [SignName: WeekKey]
        static let compatibilitySeenWeeks = "new_content_compatibility_seen_weeks"  // [PairKey: WeekKey]
    }
    
    // MARK: - Private Properties
    private let defaults = UserDefaults.standard
    private let calendar = Calendar.current
    
    // MARK: - Initialization
    private init() {
        refreshUnseenContent()
    }
    
    // MARK: - Current Week Helper
    
    /// Get the current week identifier (e.g., "2025-W48")
    var currentWeekKey: String {
        let year = calendar.component(.yearForWeekOfYear, from: Date())
        let week = calendar.component(.weekOfYear, from: Date())
        return "\(year)-W\(String(format: "%02d", week))"
    }
    
    /// Get week key for a specific date
    func weekKey(for date: Date) -> String {
        let year = calendar.component(.yearForWeekOfYear, from: date)
        let week = calendar.component(.weekOfYear, from: date)
        return "\(year)-W\(String(format: "%02d", week))"
    }
    
    // MARK: - Horoscope "New" Badge
    
    /// Check if the weekly horoscope for a sign is new (unseen this week)
    func isHoroscopeNew(for sign: ZodiacSign) -> Bool {
        let signKey = sign.rawValue.lowercased()
        let seenWeeks = getHoroscopeSeenWeeks()
        
        // If we haven't seen this sign's horoscope this week, it's new
        return seenWeeks[signKey] != currentWeekKey
    }
    
    /// Mark the horoscope for a sign as seen this week
    func markHoroscopeSeen(for sign: ZodiacSign) {
        let signKey = sign.rawValue.lowercased()
        var seenWeeks = getHoroscopeSeenWeeks()
        
        // Update the seen week for this sign
        seenWeeks[signKey] = currentWeekKey
        saveHoroscopeSeenWeeks(seenWeeks)
        
        // Update published state
        unseenHoroscopeSigns.remove(signKey)
        
        // Track analytics
        AnalyticsManager.shared.trackEvent(AnalyticsEvent.newContentViewed, properties: [
            "content_type": "weekly_horoscope",
            "sign": sign.rawValue
        ])
        
        print("[NewContentManager] Marked \(sign.rawValue) horoscope as seen for \(currentWeekKey)")
    }
    
    // MARK: - Compatibility "New" Badge
    
    /// Generate a unique key for a compatibility pair
    func compatibilityPairKey(userSign: ZodiacSign, contactSign: ZodiacSign, contactId: UUID) -> String {
        // Use sorted signs + contact ID to ensure consistency
        let signs = [userSign.rawValue, contactSign.rawValue].sorted()
        return "\(signs[0])_\(signs[1])_\(contactId.uuidString.prefix(8))"
    }
    
    /// Check if "This Week" compatibility for a pair is new (unseen this week)
    func isCompatibilityNew(userSign: ZodiacSign, contactSign: ZodiacSign, contactId: UUID) -> Bool {
        let pairKey = compatibilityPairKey(userSign: userSign, contactSign: contactSign, contactId: contactId)
        let seenWeeks = getCompatibilitySeenWeeks()
        
        // If we haven't seen this pair's compatibility this week, it's new
        return seenWeeks[pairKey] != currentWeekKey
    }
    
    /// Mark the "This Week" compatibility for a pair as seen
    func markCompatibilitySeen(userSign: ZodiacSign, contactSign: ZodiacSign, contactId: UUID) {
        let pairKey = compatibilityPairKey(userSign: userSign, contactSign: contactSign, contactId: contactId)
        var seenWeeks = getCompatibilitySeenWeeks()
        
        // Update the seen week for this pair
        seenWeeks[pairKey] = currentWeekKey
        saveCompatibilitySeenWeeks(seenWeeks)
        
        // Update published state
        unseenCompatibilityPairs.remove(pairKey)
        
        // Track analytics
        AnalyticsManager.shared.trackEvent(AnalyticsEvent.newContentViewed, properties: [
            "content_type": "this_week_compatibility",
            "pair_key": pairKey
        ])
        
        print("[NewContentManager] Marked compatibility \(pairKey) as seen for \(currentWeekKey)")
    }
    
    // MARK: - Refresh Unseen Content
    
    /// Refresh the list of unseen content (call on app launch or view appear)
    func refreshUnseenContent() {
        // Check which horoscopes are unseen this week
        var unseen: Set<String> = []
        let seenWeeks = getHoroscopeSeenWeeks()
        
        for sign in ZodiacSign.realSigns {
            let signKey = sign.rawValue.lowercased()
            if seenWeeks[signKey] != currentWeekKey {
                unseen.insert(signKey)
            }
        }
        
        unseenHoroscopeSigns = unseen
        print("[NewContentManager] Unseen horoscopes this week: \(unseen.count)")
    }
    
    // MARK: - Private Storage Methods
    
    private func getHoroscopeSeenWeeks() -> [String: String] {
        return defaults.dictionary(forKey: Keys.horoscopeSeenWeeks) as? [String: String] ?? [:]
    }
    
    private func saveHoroscopeSeenWeeks(_ dict: [String: String]) {
        defaults.set(dict, forKey: Keys.horoscopeSeenWeeks)
    }
    
    private func getCompatibilitySeenWeeks() -> [String: String] {
        return defaults.dictionary(forKey: Keys.compatibilitySeenWeeks) as? [String: String] ?? [:]
    }
    
    private func saveCompatibilitySeenWeeks(_ dict: [String: String]) {
        defaults.set(dict, forKey: Keys.compatibilitySeenWeeks)
    }
    
    // MARK: - Cleanup (optional, for week transitions)
    
    /// Clean up old week data (keep only current and previous week)
    func cleanupOldData() {
        // Get previous week key
        let previousWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: Date())!
        let previousWeekKey = weekKey(for: previousWeek)
        let validWeeks = [currentWeekKey, previousWeekKey]
        
        // Clean horoscope seen weeks
        var horoscopeWeeks = getHoroscopeSeenWeeks()
        horoscopeWeeks = horoscopeWeeks.filter { validWeeks.contains($0.value) }
        saveHoroscopeSeenWeeks(horoscopeWeeks)
        
        // Clean compatibility seen weeks
        var compatWeeks = getCompatibilitySeenWeeks()
        compatWeeks = compatWeeks.filter { validWeeks.contains($0.value) }
        saveCompatibilitySeenWeeks(compatWeeks)
        
        print("[NewContentManager] Cleaned up old week data")
    }
    
    /// Reset all seen data (for testing)
    func resetAllData() {
        defaults.removeObject(forKey: Keys.horoscopeSeenWeeks)
        defaults.removeObject(forKey: Keys.compatibilitySeenWeeks)
        refreshUnseenContent()
        print("[NewContentManager] All data reset")
    }
}

// MARK: - New Badge View
import SwiftUI

/// Reusable "New ✨" badge view
struct NewBadge: View {
    var text: String = "New"
    var showSparkle: Bool = true
    
    var body: some View {
        HStack(spacing: 2) {
            if showSparkle {
                Text("✨")
                    .font(.caption2)
            }
            Text(text)
                .font(.caption2)
                .fontWeight(.semibold)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            LinearGradient(
                colors: [.purple, .pink],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(10)
    }
}

/// Modifier to easily add "New" badge to any view
struct NewBadgeModifier: ViewModifier {
    let isNew: Bool
    let alignment: Alignment
    
    func body(content: Content) -> some View {
        content.overlay(alignment: alignment) {
            if isNew {
                NewBadge()
                    .offset(x: alignment == .topTrailing ? 10 : -10, y: -10)
            }
        }
    }
}

extension View {
    /// Add a "New ✨" badge if condition is true
    func newBadge(isNew: Bool, alignment: Alignment = .topTrailing) -> some View {
        modifier(NewBadgeModifier(isNew: isNew, alignment: alignment))
    }
}

