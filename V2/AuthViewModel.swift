//import SwiftUI
//import FirebaseAuth
//
//class AuthViewModel: ObservableObject {
//    @Published var isAuthenticated = false
//    @Published var isPassphraseSet = false
//
//    init() {
//        checkAuthStatus()
//        listenForAuthChanges()
//        
//        // If the user is already logged in, check for the stored passphrase.
//        if let userID = Auth.auth().currentUser?.uid,
//           let storedPassphrase = KeychainHelper.getPassphrase(for: userID),
//           !storedPassphrase.isEmpty {
//            self.isPassphraseSet = true
//        }
//    }
//
//    func checkAuthStatus() {
//        let user = Auth.auth().currentUser
//        DispatchQueue.main.async {
//            self.isAuthenticated = (user != nil)
//        }
//    }
//
//    func listenForAuthChanges() {
//        Auth.auth().addStateDidChangeListener { [weak self] _, user in
//            DispatchQueue.main.async {
//                self?.isAuthenticated = (user != nil)
//            }
//        }
//    }
//
//    func signOut() {
//        do {
//            try Auth.auth().signOut()
//            DispatchQueue.main.async {
//                self.isAuthenticated = false
//                self.isPassphraseSet = false
//            }
//        } catch {
//            print("Error signing out: \(error.localizedDescription)")
//        }
//    }
//}
