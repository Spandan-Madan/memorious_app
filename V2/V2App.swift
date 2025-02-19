import SwiftUI
import Firebase
import GoogleSignIn
import FirebaseAuth

@main
struct V2App: App {
    @StateObject private var authViewModel = AuthViewModel()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            NavigationView {
                RootView()
                    .environmentObject(authViewModel)
                    .onOpenURL { url in
                        GIDSignIn.sharedInstance.handle(url)
                    }
            }
        }
    }
}

struct RootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var passphraseSetupCompleted = false

    var body: some View {
        if authViewModel.isAuthenticated {
            if let userID = Auth.auth().currentUser?.uid,
               KeychainHelper.getPassphrase(for: userID) == nil && !passphraseSetupCompleted {
                PassphraseSetupView(userID: userID, onPassphraseSaved: {
                    passphraseSetupCompleted = true
                })
            } else {
                ContentView()
            }
        } else {
            LoginView(onLoginSuccess: {
                DispatchQueue.main.async {
                    authViewModel.isAuthenticated = true
                }
            })
        }
    }
}
