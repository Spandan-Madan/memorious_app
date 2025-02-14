import SwiftUI
import GoogleSignIn
import GoogleSignInSwift
import FirebaseAuth
import Security

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    
    init() {
        checkAuthStatus()
        listenForAuthChanges()
    }
    
    func checkAuthStatus() {
        let user = Auth.auth().currentUser
        DispatchQueue.main.async {
            self.isAuthenticated = (user != nil)
        }
    }
    
    func listenForAuthChanges() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.isAuthenticated = (user != nil)
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                self.isAuthenticated = false
            }
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
    
    func generateAndStoreSecretKey(for userID: String) {
        let existingKey = KeychainHelper.getKey(for: userID)
        if existingKey == nil {
            let newKey = KeychainHelper.generateRandomKey()
            KeychainHelper.storeKey(newKey, for: userID)
            print("New secret key generated and stored for user: \(userID)")
        } else {
            print("Existing secret key found for user: \(userID)")
        }
    }
}

struct LoginView: View {
    var onLoginSuccess: () -> Void
    
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Spacer()
                
                Image("logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 250, height: 250)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white)
                    )
                
                Text("All your memories. In one place.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                GoogleSignInButton(action: handleSignIn)
                    .frame(width: 120, height: 50)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                
                Spacer()
            }
            .padding()
        }
    }
    
    private func handleSignIn() {
        guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else { return }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { signInResult, error in
            if let error = error {
                print("Google Sign-In failed: \(error.localizedDescription)")
                return
            }
            
            guard let user = signInResult?.user,
                  let idToken = user.idToken?.tokenString else {
                return
            }
            
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: user.accessToken.tokenString
            )
            
            Auth.auth().signIn(with: credential) { result, error in
                if let error = error {
                    print("Firebase Sign-In failed: \(error.localizedDescription)")
                    return
                }
                
                if let userID = result?.user.uid {
                    let authViewModel = AuthViewModel()
                    authViewModel.generateAndStoreSecretKey(for: userID)
                }
                
                DispatchQueue.main.async {
                    onLoginSuccess()
                }
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(onLoginSuccess: {})
    }
}
