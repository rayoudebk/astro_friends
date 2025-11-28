import Foundation
import UserNotifications
import UIKit

// MARK: - Notification Manager
/// Manages local and push notifications for the app
/// Sprint 1: Foundation only (permission + placeholders)
/// Sprint 2: Real scheduling implementation
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    // MARK: - Published Properties
    @Published private(set) var isPermissionGranted: Bool = false
    @Published private(set) var permissionStatus: UNAuthorizationStatus = .notDetermined
    
    // MARK: - Private Properties
    private let notificationCenter = UNUserNotificationCenter.current()
    private let hasRequestedPermissionKey = "notification_permission_requested"
    
    // MARK: - Initialization
    private init() {
        Task {
            await checkCurrentPermission()
        }
    }
    
    // MARK: - Public API
    
    /// Request notification permission if not already requested
    /// Call this from a user action (Settings button) or lightly on first launch
    func requestPermissionIfNeeded() {
        // Check if we've already requested
        let hasRequested = UserDefaults.standard.bool(forKey: hasRequestedPermissionKey)
        
        if hasRequested {
            print("[NotificationManager] Permission already requested previously")
            Task {
                await checkCurrentPermission()
            }
            return
        }
        
        // Request permission
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isPermissionGranted = granted
                UserDefaults.standard.set(true, forKey: self?.hasRequestedPermissionKey ?? "")
                
                if let error = error {
                    print("[NotificationManager] Permission request error: \(error.localizedDescription)")
                } else {
                    print("[NotificationManager] Permission granted: \(granted)")
                }
                
                // Track analytics
                AnalyticsManager.shared.trackEvent("notification_permission_response", properties: [
                    "granted": granted
                ])
            }
        }
    }
    
    /// Force request permission (ignores previous request check)
    /// Use when user explicitly taps "Enable Notifications" in settings
    func requestPermission() {
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isPermissionGranted = granted
                UserDefaults.standard.set(true, forKey: self?.hasRequestedPermissionKey ?? "")
                
                if granted {
                    print("[NotificationManager] Permission granted!")
                } else if let error = error {
                    print("[NotificationManager] Error: \(error.localizedDescription)")
                } else {
                    print("[NotificationManager] Permission denied")
                }
            }
        }
    }
    
    /// Check current notification permission status
    func checkCurrentPermission() async {
        let settings = await notificationCenter.notificationSettings()
        
        await MainActor.run {
            self.permissionStatus = settings.authorizationStatus
            self.isPermissionGranted = settings.authorizationStatus == .authorized
            print("[NotificationManager] Current status: \(settings.authorizationStatus.rawValue)")
        }
    }
    
    // MARK: - Scheduling Placeholders (Sprint 2)
    
    /// Placeholder for weekly horoscope reminder
    /// TODO (Sprint 2): Implement actual scheduling for Monday 9am
    func scheduleWeeklyReminderPlaceholder() {
        print("[NotificationManager] scheduleWeeklyReminderPlaceholder() called – to be implemented in Sprint 2")
        
        // TODO: Sprint 2 implementation
        // - Schedule for Monday 9:00 AM local time
        // - Title: "Your Weekly Horoscope is Ready ✨"
        // - Body: "The stars have new insights for [UserSign] this week"
        // - Repeating weekly
        
        AnalyticsManager.shared.trackEvent("weekly_reminder_scheduled_placeholder", properties: nil)
    }
    
    /// Placeholder for daily streak reminder
    /// TODO (Sprint 2): Implement reminder if user hasn't opened app today
    func scheduleDailyStreakReminderPlaceholder() {
        print("[NotificationManager] scheduleDailyStreakReminderPlaceholder() called – to be implemented in Sprint 2")
        
        // TODO: Sprint 2 implementation
        // - Schedule for evening (7pm) if user hasn't opened app
        // - Title: "Don't break your streak! 🔥"
        // - Body: "You're on a X day streak. Check in to keep it going!"
    }
    
    /// Placeholder for Mercury Retrograde alert
    /// TODO (Sprint 2): Implement based on astronomical calendar
    func scheduleMercuryRetrogradeAlertPlaceholder() {
        print("[NotificationManager] scheduleMercuryRetrogradeAlertPlaceholder() called – to be implemented in Sprint 2")
        
        // TODO: Sprint 2 implementation
        // - Check astronomical calendar for retrograde dates
        // - Schedule 1 day before retrograde starts
        // - Title: "Mercury Retrograde Incoming ☿️"
        // - Body: "Heads up! Mercury goes retrograde tomorrow. Time to double-check your plans."
    }
    
    /// Cancel all scheduled notifications
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        print("[NotificationManager] All notifications cancelled")
    }
    
    // MARK: - Helper Methods
    
    /// Open system settings for notification permissions
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Authorization Status Extension
extension UNAuthorizationStatus {
    var displayName: String {
        switch self {
        case .notDetermined: return "Not Determined"
        case .denied: return "Denied"
        case .authorized: return "Authorized"
        case .provisional: return "Provisional"
        case .ephemeral: return "Ephemeral"
        @unknown default: return "Unknown"
        }
    }
}

