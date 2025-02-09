import SwiftUI
import UserNotifications
import Firebase
import GoogleSignIn

@main
struct V2App: App {
    @StateObject private var authViewModel = AuthViewModel()

    init() {
        FirebaseApp.configure()
        
        // If you do NOT need cross-group keychain sharing, remove or comment out:
        // do {
        //     try Auth.auth().useUserAccessGroup(nil)
        //     print("✅ Firebase Auth Persistence Enabled")
        // } catch {
        //     print("⚠️ Error setting FirebaseAuth persistence: \(error.localizedDescription)")
        // }

        requestNotificationAuthorization()
        scheduleWeeklyNotification()
    }

    var body: some Scene {
        WindowGroup {
            // Wrap your login/content logic in a RootView
            RootView()
                .environmentObject(authViewModel)
                // IMPORTANT: Allows Google to finish the sign-in flow
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }

    // MARK: - Notification Setup (optional)
    func requestNotificationAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("❌ Error requesting notification authorization: \(error.localizedDescription)")
            }
        }
    }

    func scheduleWeeklyNotification() {
        let center = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        content.title = "Memory Test Reminder"
        content.body = "It's time to take your weekly memory test!"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.weekday = 2 // Monday
        dateComponents.hour = 9    // 9 AM

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "weeklyMemoryTestReminder", content: content, trigger: trigger)

        center.add(request) { error in
            if let error = error {
                print("❌ Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - RootView decides which screen to show
struct RootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        if authViewModel.isAuthenticated {
            ContentView()
        } else {
            // Pass a callback that sets `isAuthenticated` on success
            LoginView(onLoginSuccess: {
                DispatchQueue.main.async {
                    authViewModel.isAuthenticated = true
                }
            })
        }
    }
}
