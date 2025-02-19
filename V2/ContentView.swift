import SwiftUI
import AVFoundation
import FirebaseAuth
import GoogleSignIn
import MSAL  // Keep if you need direct check of GIDSignIn/MSAL
import AuthenticationServices // Keep if you need direct checks
import Foundation

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    // MARK: - Navigation states
    @State private var navigateToQuestionnaire = false
    @State private var navigateToCognitiveAssessment = false
    @State private var navigateToMemoryBot = false

    // MARK: - NEW: Control navigation to PassphraseSetupView
    @State private var showPassphraseSetupView = false

    // For chart data
    @State private var chartScores: [(Int, Date)] = []

    // Alert states
    @State private var showAlert = false
    @State private var alertMessage = ""

    // Track access states
    @State private var hasDriveAccess = UserDefaults.standard.bool(forKey: "hasDriveAccess")
    @State private var hasGmailAccess = UserDefaults.standard.bool(forKey: "hasGmailAccess")
    @State private var hasOfficeAccess = UserDefaults.standard.bool(forKey: "hasOfficeAccess")
    @State private var hasSlackAccess = UserDefaults.standard.bool(forKey: "hasSlackAccess")
    
    // New state for deletion feedback
    @State private var deletionMessage: String = ""

    var userName: String {
        Auth.auth().currentUser?.displayName ?? "User"
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.white.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    Image("logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 150, height: 150)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white)
                        )
                    
                    // Top text line
                    Text("Click to extract your memories.")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding(.top, 10)
                    
                    // Row with connection buttons
                    HStack(spacing: 32) {
                        // Google Button with checkmark overlay if connected
                        Button(action: {
                            GoogleSignInManager.requestGoogleAccess { success in
                                if success {
                                    checkAccessStatus()
                                } else {
                                    print("Failed or canceled Google Sign In.")
                                }
                            }
                        }) {
                            ZStack {
                                Image("google_icon")
                                    .resizable()
                                    .frame(width: 32, height: 32)
                                
                                if hasDriveAccess && hasGmailAccess {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .offset(x: 12, y: -12)
                                }
                            }
                        }
                        
                        // Office365 Button with background change when connected
                        Button(action: {
                            OfficeSignInManager.requestMicrosoftAccess { success in
                                if success {
                                    checkAccessStatus()
                                } else {
                                    print("Failed or canceled Office 365 Sign In.")
                                }
                            }
                        }) {
                            Image("office_icon")
                                .resizable()
                                .frame(width: 32, height: 32)
                                .padding(8)
                                .background(hasOfficeAccess ? Color.green.opacity(0.3) : Color.gray.opacity(0.3))
                                .cornerRadius(8)
                        }
                        
                        // Slack Button with background change when connected
                        Button(action: {
                            SlackSignInManager.requestSlackAccess { success in
                                if success {
                                    checkAccessStatus()
                                } else {
                                    print("Failed or canceled Slack Sign In.")
                                }
                            }
                        }) {
                            Image("slack_icon")
                                .resizable()
                                .frame(width: 32, height: 32)
                                .padding(8)
                                .background(hasSlackAccess ? Color.green.opacity(0.3) : Color.gray.opacity(0.3))
                                .cornerRadius(8)
                        }
                    }
                    
                    // "Search your memories" button
                    Button(action: {
                        let userID = Auth.auth().currentUser?.uid ?? "tempUserID"
                        
                        // Check if a passphrase exists
                        if let existingPassphrase = KeychainHelper.getPassphrase(for: userID),
                           !existingPassphrase.isEmpty {
                            // Passphrase exists: proceed with microphone permission
                            requestPermissions {
                                navigateToMemoryBot = true
                            }
                        } else {
                            // No passphrase found: navigate to the PassphraseSetupView
                            showPassphraseSetupView = true
                        }
                    }) {
                        Text("Search your memories")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.black)
                            .cornerRadius(10)
                    }
                    
                    // Row with Logout and Delete buttons
                    HStack(spacing: 16) {
                        // Logout Button
                        Button(action: {
                            authViewModel.signOut()
                        }) {
                            Text("Logout")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.black.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        
                        // Delete Keychain Button
                        Button(action: {
                            deleteKeychainData()
                        }) {
                            Text("Delete Keys")
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.red)
                                .cornerRadius(10)
                                .shadow(radius: 5)
                        }
                    }
                    
                    // Feedback message after deletion
                    if !deletionMessage.isEmpty {
                        Text(deletionMessage)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    
                    Spacer()
                }
                .padding()
                .alert(isPresented: $showAlert) {
                    Alert(
                        title: Text("Permission Denied"),
                        message: Text(alertMessage),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .background(
                Group {
                    // Existing hidden NavigationLinks
                    NavigationLink(destination: MemoriesView(),
                                   isActive: $navigateToQuestionnaire) {
                        EmptyView()
                    }
                    NavigationLink(destination: MemoriesView(),
                                   isActive: $navigateToCognitiveAssessment) {
                        EmptyView()
                    }
                    NavigationLink(destination: MemoriesView(),
                                   isActive: $navigateToMemoryBot) {
                        EmptyView()
                    }
                    
                    // NEW: Navigate to PassphraseSetupView
                    NavigationLink(
                        destination: PassphraseSetupView(
                            userID: Auth.auth().currentUser?.uid ?? "tempUserID",
                            onPassphraseSaved: {
                                showPassphraseSetupView = false
                            }
                        ),
                        isActive: $showPassphraseSetupView
                    ) {
                        EmptyView()
                    }
                }
            )
        }
    }
    
    // MARK: - Check Access Status
    private func checkAccessStatus() {
        // Check Google scopes
        if let user = GIDSignIn.sharedInstance.currentUser,
           let grantedScopes = user.grantedScopes {
            self.hasDriveAccess = grantedScopes.contains("https://www.googleapis.com/auth/drive.readonly")
            self.hasGmailAccess = grantedScopes.contains("https://www.googleapis.com/auth/gmail.readonly")
            UserDefaults.standard.set(self.hasDriveAccess, forKey: "hasDriveAccess")
            UserDefaults.standard.set(self.hasGmailAccess, forKey: "hasGmailAccess")
        } else {
            self.hasDriveAccess = false
            self.hasGmailAccess = false
            UserDefaults.standard.set(false, forKey: "hasDriveAccess")
            UserDefaults.standard.set(false, forKey: "hasGmailAccess")
        }
        
        // Check Office 365
        self.hasOfficeAccess = UserDefaults.standard.bool(forKey: "hasOfficeAccess")
        
        // Check Slack
        self.hasSlackAccess = UserDefaults.standard.bool(forKey: "hasSlackAccess")
    }
    
    // MARK: - Request Permissions (Microphone only)
    private func requestPermissions(completion: @escaping () -> Void) {
        #if targetEnvironment(simulator)
        print("Simulator detected: granting microphone permission automatically.")
        DispatchQueue.main.async {
            completion()
        }
        #else
        requestMicrophonePermission { micGranted in
            if micGranted {
                DispatchQueue.main.async {
                    completion()
                }
            } else {
                DispatchQueue.main.async {
                    alertMessage = "This app needs access to the microphone to function properly."
                    showAlert = true
                }
            }
        }
        #endif
    }
    
    private func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            completion(granted)
        }
    }
    
    // MARK: - Delete Keychain Data
    private func deleteKeychainData() {
        if let userID = Auth.auth().currentUser?.uid {
            KeychainHelper.deletePassphrase(for: userID)
            deletionMessage = "Deleted Key & Passphrase for user: \(userID)"
        } else {
            deletionMessage = "No logged-in user found."
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthViewModel())
    }
}
