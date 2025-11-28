import Foundation
import Combine

// MARK: - Streak Info
/// Struct for binding streak data into SwiftUI views
struct StreakInfo {
    let currentStreakDays: Int
    let longestStreakDays: Int
    let lastActiveDate: Date?
    
    var isActiveToday: Bool {
        guard let lastActive = lastActiveDate else { return false }
        return Calendar.current.isDateInToday(lastActive)
    }
    
    var streakEmoji: String {
        switch currentStreakDays {
        case 0: return "💤"
        case 1...2: return "🔥"
        case 3...6: return "🔥🔥"
        case 7...29: return "🔥🔥🔥"
        case 30...: return "⭐🔥⭐"
        default: return "🔥"
        }
    }
    
    var streakMessage: String {
        switch currentStreakDays {
        case 0: return "Start your streak today!"
        case 1: return "1 day streak - keep going!"
        case 2...6: return "\(currentStreakDays) day streak!"
        case 7: return "🎉 One week streak!"
        case 8...29: return "\(currentStreakDays) days - amazing!"
        case 30: return "🏆 30 day milestone!"
        case 31...: return "\(currentStreakDays) days - legendary!"
        default: return "\(currentStreakDays) day streak"
        }
    }
}

// MARK: - Streak Manager
/// Manages user engagement streaks locally using UserDefaults
/// Tracks consecutive days of app usage
final class StreakManager: ObservableObject {
    static let shared = StreakManager()
    
    // MARK: - Published Properties
    @Published private(set) var currentStreakDays: Int = 0
    @Published private(set) var longestStreakDays: Int = 0
    @Published private(set) var lastActiveDate: Date?
    
    // MARK: - UserDefaults Keys
    private enum Keys {
        static let lastActiveDate = "streak_lastActiveDate"
        static let currentDays = "streak_currentDays"
        static let longestDays = "streak_longestDays"
    }
    
    // MARK: - Private Properties
    private let defaults = UserDefaults.standard
    private let calendar = Calendar.current
    private let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter
    }()
    
    // MARK: - Initialization
    private init() {
        loadFromStorage()
    }
    
    // MARK: - Public API
    
    /// Get current streak info as a struct (useful for SwiftUI binding)
    var streakInfo: StreakInfo {
        StreakInfo(
            currentStreakDays: currentStreakDays,
            longestStreakDays: longestStreakDays,
            lastActiveDate: lastActiveDate
        )
    }
    
    /// Register a check-in for the given date (defaults to today)
    /// Call this when the user opens the app or visits Home
    func registerCheckIn(on date: Date = Date()) {
        let today = calendar.startOfDay(for: date)
        
        // If no last active date, start streak at 1
        guard let lastActive = lastActiveDate else {
            startNewStreak(on: today)
            return
        }
        
        let lastActiveDay = calendar.startOfDay(for: lastActive)
        
        // Same calendar day → do nothing
        if calendar.isDate(today, inSameDayAs: lastActiveDay) {
            print("[StreakManager] Already checked in today")
            return
        }
        
        // Calculate days between
        let daysBetween = calendar.dateComponents([.day], from: lastActiveDay, to: today).day ?? 0
        
        if daysBetween == 1 {
            // Exactly 1 day since last → continue streak
            incrementStreak(on: today)
        } else {
            // Gap > 1 day → reset streak
            resetStreak(on: today)
        }
    }
    
    /// Force reset the streak (for testing or special cases)
    func resetAllData() {
        defaults.removeObject(forKey: Keys.lastActiveDate)
        defaults.removeObject(forKey: Keys.currentDays)
        defaults.removeObject(forKey: Keys.longestDays)
        loadFromStorage()
        print("[StreakManager] All streak data reset")
    }
    
    // MARK: - Private Methods
    
    private func loadFromStorage() {
        // Load last active date
        if let dateString = defaults.string(forKey: Keys.lastActiveDate),
           let date = dateFormatter.date(from: dateString) {
            lastActiveDate = date
        } else {
            lastActiveDate = nil
        }
        
        // Load streak counts
        currentStreakDays = defaults.integer(forKey: Keys.currentDays)
        longestStreakDays = defaults.integer(forKey: Keys.longestDays)
        
        print("[StreakManager] Loaded - Current: \(currentStreakDays), Longest: \(longestStreakDays)")
    }
    
    private func saveToStorage() {
        if let date = lastActiveDate {
            defaults.set(dateFormatter.string(from: date), forKey: Keys.lastActiveDate)
        }
        defaults.set(currentStreakDays, forKey: Keys.currentDays)
        defaults.set(longestStreakDays, forKey: Keys.longestDays)
    }
    
    private func startNewStreak(on date: Date) {
        currentStreakDays = 1
        lastActiveDate = date
        updateLongestIfNeeded()
        saveToStorage()
        trackStreakEvent()
        print("[StreakManager] New streak started: 1 day")
    }
    
    private func incrementStreak(on date: Date) {
        currentStreakDays += 1
        lastActiveDate = date
        updateLongestIfNeeded()
        saveToStorage()
        trackStreakEvent()
        print("[StreakManager] Streak incremented: \(currentStreakDays) days")
    }
    
    private func resetStreak(on date: Date) {
        let previousStreak = currentStreakDays
        currentStreakDays = 1
        lastActiveDate = date
        saveToStorage()
        trackStreakEvent()
        print("[StreakManager] Streak reset from \(previousStreak) to 1 day (gap detected)")
    }
    
    private func updateLongestIfNeeded() {
        if currentStreakDays > longestStreakDays {
            longestStreakDays = currentStreakDays
            print("[StreakManager] New longest streak: \(longestStreakDays) days!")
        }
    }
    
    private func trackStreakEvent() {
        AnalyticsManager.shared.trackEvent("streak_updated", properties: [
            "currentStreakDays": currentStreakDays,
            "longestStreakDays": longestStreakDays
        ])
    }
}

