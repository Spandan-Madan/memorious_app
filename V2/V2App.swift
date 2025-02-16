import SwiftUI
import Firebase
import GoogleSignIn

@main
struct V2App: App {
    @StateObject private var authViewModel = AuthViewModel()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}

struct RootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        if authViewModel.isAuthenticated {
            ContentView()
        } else {
            LoginView(onLoginSuccess: {
                DispatchQueue.main.async {
                    authViewModel.isAuthenticated = true
                }
            })
        }
    }
}
