import SwiftUI
import UserNotifications

@main
struct V2App: App {
    init() {
        requestNotificationAuthorization()
        scheduleWeeklyNotification()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    // Request permission for notifications
    func requestNotificationAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Error requesting notification authorization: \(error.localizedDescription)")
            }
        }
    }
    
    // Schedule a weekly notification
    func scheduleWeeklyNotification() {
        let center = UNUserNotificationCenter.current()
        
        // Create the content of the notification
        let content = UNMutableNotificationContent()
        content.title = "Memory Test Reminder"
        content.body = "It's time to take your weekly memory test!"
        content.sound = .default
        
        // Create the trigger for 9 AM every Monday
        var dateComponents = DateComponents()
        dateComponents.weekday = 2 // Monday
        dateComponents.hour = 9 // 9 AM
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // Create the request
        let request = UNNotificationRequest(identifier: "weeklyMemoryTestReminder", content: content, trigger: trigger)
        
        // Schedule the request
        center.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
}
