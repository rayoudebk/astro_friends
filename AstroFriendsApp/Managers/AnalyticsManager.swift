import Foundation

// MARK: - Analytics Tracking Protocol
/// Protocol for analytics implementations
/// Allows easy swapping between console logging and real analytics services
protocol AnalyticsTracking {
    func trackEvent(_ name: String, properties: [String: Any]?)
    func trackScreen(_ screenName: String)
    func setUserProperty(_ key: String, value: Any?)
}

// MARK: - Analytics Manager
/// Centralized analytics tracking for the app
/// Sprint 1: Console logging implementation
/// Sprint 2+: Wire to real analytics service (Mixpanel, Amplitude, Firebase, etc.)
final class AnalyticsManager: AnalyticsTracking {
    static let shared = AnalyticsManager()
    
    // MARK: - Configuration
    private let isEnabled: Bool = true
    private let logPrefix = "[Analytics]"
    
    // MARK: - User Properties (cached locally)
    private var userProperties: [String: Any] = [:]
    
    // MARK: - Initialization
    private init() {
        print("\(logPrefix) AnalyticsManager initialized (console logging mode)")
    }
    
    // MARK: - Public API
    
    /// Track a named event with optional properties
    /// - Parameters:
    ///   - name: Event name (e.g., "weekly_horoscope_viewed")
    ///   - properties: Optional dictionary of event properties
    func trackEvent(_ name: String, properties: [String: Any]?) {
        guard isEnabled else { return }
        
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let propsString = properties?.description ?? "[:]"
        
        print("\(logPrefix) EVENT: \(name)")
        print("         └─ Properties: \(propsString)")
        print("         └─ Timestamp: \(timestamp)")
        
        // TODO (Sprint 2): Send to real analytics service
        // Mixpanel.track(event: name, properties: properties)
        // or
        // Analytics.logEvent(name, parameters: properties)
    }
    
    /// Track a screen view
    /// - Parameter screenName: Name of the screen being viewed
    func trackScreen(_ screenName: String) {
        guard isEnabled else { return }
        
        print("\(logPrefix) SCREEN: \(screenName)")
        
        // Also track as event for consistency
        trackEvent("screen_view", properties: ["screen_name": screenName])
    }
    
    /// Set a user property for segmentation
    /// - Parameters:
    ///   - key: Property name
    ///   - value: Property value (nil to unset)
    func setUserProperty(_ key: String, value: Any?) {
        guard isEnabled else { return }
        
        if let value = value {
            userProperties[key] = value
            print("\(logPrefix) USER_PROPERTY SET: \(key) = \(value)")
        } else {
            userProperties.removeValue(forKey: key)
            print("\(logPrefix) USER_PROPERTY REMOVED: \(key)")
        }
        
        // TODO (Sprint 2): Send to real analytics service
        // Mixpanel.people.set(key, to: value)
    }
    
    /// Identify the user (for logged-in users)
    /// - Parameter userId: Unique user identifier
    func identify(userId: String) {
        guard isEnabled else { return }
        
        print("\(logPrefix) IDENTIFY: \(userId)")
        
        // TODO (Sprint 2): Send to real analytics service
        // Mixpanel.identify(distinctId: userId)
    }
    
    /// Reset user identity (on logout)
    func reset() {
        userProperties.removeAll()
        print("\(logPrefix) RESET: User identity cleared")
        
        // TODO (Sprint 2): Send to real analytics service
        // Mixpanel.reset()
    }
}

// MARK: - Predefined Event Names
/// Centralized event name constants for consistency
enum AnalyticsEvent {
    // Horoscope Events
    static let weeklyHoroscopeViewed = "weekly_horoscope_viewed"
    static let horoscopeDetailOpened = "horoscope_detail_opened"
    static let horoscopeShared = "horoscope_shared"
    
    // Compatibility Events
    static let compatibilityViewed = "compatibility_viewed"
    static let compatibilityWeeklyViewed = "compatibility_weekly_viewed"
    static let compatibilityShared = "compatibility_shared"
    
    // Oracle Events
    static let oracleGenerated = "oracle_generated"
    static let oracleViewed = "oracle_viewed"
    static let oracleRefreshed = "oracle_refreshed"
    
    // Engagement Events
    static let streakUpdated = "streak_updated"
    static let appOpened = "app_opened"
    static let contactAdded = "contact_added"
    static let contactViewed = "contact_viewed"
    
    // Ask the Stars Events
    static let askStarsQuestionAsked = "ask_stars_question"
    static let askStarsFollowUpTapped = "ask_stars_followup"
    
    // Settings Events
    static let notificationPermissionResponse = "notification_permission_response"
    static let userSignChanged = "user_sign_changed"
    static let birthDataUpdated = "birth_data_updated"
    
    // New Content Events
    static let newContentBadgeSeen = "new_content_badge_seen"
    static let newContentViewed = "new_content_viewed"
}

// MARK: - Predefined User Properties
enum AnalyticsUserProperty {
    static let zodiacSign = "zodiac_sign"
    static let hasFullBirthData = "has_full_birth_data"
    static let contactCount = "contact_count"
    static let currentStreak = "current_streak"
    static let longestStreak = "longest_streak"
    static let isPremium = "is_premium"
}

