import SwiftUI
import AVFoundation
import Speech
import VisionKit
import FirebaseAuth
import GoogleSignIn
import MSAL  // For Microsoft sign-in
import AuthenticationServices // For ASWebAuthenticationSession (Slack OAuth)

class SlackAuthHelper: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            return UIApplication.shared.windows.first ?? ASPresentationAnchor()
        }
        return window
    }
}

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // Navigation states
    @State private var navigateToQuestionnaire = false
    @State private var navigateToCognitiveAssessment = false
    @State private var navigateToMemoryBot = false
    
    // For chart data
    @State private var chartScores: [(Int, Date)] = []
    
    // Alert states
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    // Track access states
    @State private var hasDriveAccess = UserDefaults.standard.bool(forKey: "hasDriveAccess")
    @State private var hasGmailAccess = UserDefaults.standard.bool(forKey: "hasGmailAccess")
    @State private var hasOfficeAccess = UserDefaults.standard.bool(forKey: "hasOfficeAccess")
    
    // NEW: Slack access state
    @State private var hasSlackAccess = UserDefaults.standard.bool(forKey: "hasSlackAccess")
    @State private var slackAuthHelper: SlackAuthHelper?
    
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
                        .frame(width: 250, height: 250)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white)
                        )
                    
                    Text("All your memories. In one place.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    Spacer()
                    
                    Text("Welcome,\n\(userName).")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Button(action: {
                        requestPermissions {
                            navigateToMemoryBot = true
                        }
                    }) {
                        Text("Search your memories")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.black)
                            .cornerRadius(10)
                    }
                    
                    // Combined Google Button (Drive + Gmail)
                    Button(action: {
                        requestGoogleAccess()
                    }) {
                        HStack(spacing: 12) {
                            // Replace "google_icon" with your asset or SF Symbol.
                            Image("google_icon")
                                .resizable()
                                .frame(width: 24, height: 24)
                            
                            Text(hasDriveAccess && hasGmailAccess ? "Refresh Google connection" : "Connect Google")
                                .font(.headline)
                            
                            if hasDriveAccess && hasGmailAccess {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.2))
                        .foregroundColor(.red)
                        .cornerRadius(10)
                    }
                    
                    // Office365 Button with Icon
                    Button(action: {
                        requestMicrosoftAccess()
                    }) {
                        HStack(spacing: 12) {
                            // Replace "office_icon" with your asset or SF Symbol.
                            Image("office_icon")
                                .resizable()
                                .frame(width: 24, height: 24)
                            
                            Text(hasOfficeAccess ? "Refresh Office 365 connection" : "Connect Office 365")
                                .font(.headline)
                            
                            if hasOfficeAccess {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(10)
                    }
                    
                    // NEW: Slack Button
                    Button(action: {
                        requestSlackAccess()
                    }) {
                        HStack(spacing: 12) {
                            // Replace "slack_icon" with your asset or SF Symbol
                            Image("slack_icon")
                                .resizable()
                                .frame(width: 24, height: 24)
                            
                            Text(hasSlackAccess ? "Refresh Slack connection" : "Connect Slack")
                                .font(.headline)
                            
                            if hasSlackAccess {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple.opacity(0.2))
                        .foregroundColor(.purple)
                        .cornerRadius(10)
                    }
                    
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
                    .padding(.top, -10)
                }
                .padding()
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Permission Denied"),
                          message: Text(alertMessage),
                          dismissButton: .default(Text("OK")))
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .background(
                Group {
                    NavigationLink(destination: DemoAudioUploadView(),
                                   isActive: $navigateToQuestionnaire) {
                        EmptyView()
                    }
                    NavigationLink(destination: DemoAudioUploadView(),
                                   isActive: $navigateToCognitiveAssessment) {
                        EmptyView()
                    }
                    NavigationLink(destination: DemoAudioUploadView(),
                                   isActive: $navigateToMemoryBot) {
                        EmptyView()
                    }
                }
            )
        }
        .onAppear {
            loadChartData()
            checkAccessStatus()
        }
    }
    
    // MARK: - Load chart data
    func loadChartData() {
        let results = UserDefaults.standard.array(forKey: "TestResults") as? [[String: Any]] ?? []
        chartScores = results.compactMap { result in
            if let score = result["score"] as? Int, let date = result["date"] as? Date {
                return (score, date)
            }
            return nil
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
    
    // MARK: - Request Combined Google Access (Drive + Gmail)
    private func requestGoogleAccess() {
        guard let rootViewController = UIApplication
            .shared
            .connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: \.isKeyWindow)?
            .rootViewController else {
                print("No root view controller found.")
                return
        }
        
        let scopes = [
            "https://www.googleapis.com/auth/drive.readonly",
            "https://www.googleapis.com/auth/gmail.readonly"
        ]
        
        GIDSignIn.sharedInstance.signIn(
            withPresenting: rootViewController,
            hint: nil,
            additionalScopes: scopes
        ) { signInResult, error in
            if let error = error {
                print("Failed to add Google scopes: \(error.localizedDescription)")
                return
            }
            
            if let signedInUser = signInResult?.user,
               let grantedScopes = signedInUser.grantedScopes,
               grantedScopes.contains(scopes[0]) && grantedScopes.contains(scopes[1]) {
                print("Google Drive and Gmail access granted.")
                self.hasDriveAccess = true
                self.hasGmailAccess = true
                UserDefaults.standard.set(true, forKey: "hasDriveAccess")
                UserDefaults.standard.set(true, forKey: "hasGmailAccess")
                sendGoogleTokenToBackend(user: signedInUser)
            }
        }
    }
    
    // MARK: - Request Microsoft (Office 365) Access
    private func requestMicrosoftAccess() {
        guard let rootViewController = UIApplication
            .shared
            .connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: \.isKeyWindow)?
            .rootViewController else {
                print("No root view controller found.")
                return
        }
        
        // Replace with your actual client ID from Azure
        let clientId = "800b6101-120e-4767-a90a-da9efe3e0cd5"
        
        // Use "common" if you selected multi-tenant + personal in Azure,
        // or "organizations" / specific tenant if needed.
        let authorityString = "https://login.microsoftonline.com/common"
        
        // Replace with your actual Redirect URI
        let redirectUri = "msauth.MemoriousAI.V2://auth"
        
        do {
            let authorityURL = try MSALAuthority(url: URL(string: authorityString)!)
            let msalConfig = MSALPublicClientApplicationConfig(clientId: clientId,
                                                               redirectUri: redirectUri,
                                                               authority: authorityURL)
            let application = try MSALPublicClientApplication(configuration: msalConfig)
            
            let scopes = [
                "User.Read",
                "Mail.Read",
                "Files.Read",
                "Calendars.Read",
            ]
            
            let webParameters = MSALWebviewParameters(authPresentationViewController: rootViewController)
            let parameters = MSALInteractiveTokenParameters(scopes: scopes, webviewParameters: webParameters)
            
            application.acquireToken(with: parameters) { (result, error) in
                if let error = error {
                    print("Office365 sign-in error: \(error.localizedDescription)")
                    return
                }
                
                guard let result = result else {
                    print("No MSAL result returned.")
                    return
                }
                
                // We have a valid access token now
                print("Office365 Access Token: \(result.accessToken)")
                
                self.hasOfficeAccess = true
                UserDefaults.standard.set(true, forKey: "hasOfficeAccess")
                
                // Send token to your backend
                sendMicrosoftTokenToBackend(accessToken: result.accessToken)
            }
        } catch {
            print("Failed to create MSAL application: \(error)")
        }
    }
    
    // MARK: - Request Slack Access
    private func requestSlackAccess() {
        let clientId = "8490353320080.8467800772454"
        let scopes = "channels:read"
        let redirectUri = "https://api.memoriousai.com/slack-auth-callback"
        
        // Use a random state to protect against CSRF
        let state = UUID().uuidString
        
        // Use URLComponents to properly encode the URL
        var urlComponents = URLComponents(string: "https://slack.com/oauth/v2/authorize")!
        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "scope", value: scopes),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "state", value: state)
        ]
        
        guard let authUrl = urlComponents.url else {
            print("Invalid Slack authorization URL")
            return
        }
        
        // Store state for later verification
        UserDefaults.standard.set(state, forKey: "slackAuthState")
        
        print("Starting auth with URL: \(authUrl.absoluteString)")  // Debug print
        
        let slackAuthHelper = SlackAuthHelper()
        let session = ASWebAuthenticationSession(
            url: authUrl,
            callbackURLScheme: "memoriousai.v2"
        ) { callbackURL, error in
            if let error = error {
                print("Slack authentication error: \(error.localizedDescription)")
                return
            }
            
            print("Received callback: \(String(describing: callbackURL))")  // Debug print
            
            guard let callbackURL = callbackURL,
                  let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: true),
                  let queryItems = components.queryItems else {
                print("Invalid callback URL")
                return
            }
            
            // Get the saved state
            guard let savedState = UserDefaults.standard.string(forKey: "slackAuthState") else {
                print("No saved state found")
                return
            }
            
            // Extract the authorization code and verify state
            if let code = queryItems.first(where: { $0.name == "code" })?.value,
               let returnedState = queryItems.first(where: { $0.name == "state" })?.value,
               returnedState == savedState {
                
                // Clear saved state
                UserDefaults.standard.removeObject(forKey: "slackAuthState")
                
                print("Slack authorization code received: \(code)")
                
                // Update local Slack access state
                DispatchQueue.main.async {
                    self.hasSlackAccess = true
                    UserDefaults.standard.set(true, forKey: "hasSlackAccess")
                }
                
                // Send code to backend
                self.sendSlackCodeToBackend(code: code)
            } else {
                print("State mismatch or missing code")
            }
        }
        
        // Keep a strong reference to the helper
        self.slackAuthHelper = slackAuthHelper
        
        // Set the presentation context provider
        session.presentationContextProvider = slackAuthHelper
        
        // Enable ephemeral session for better security
        session.prefersEphemeralWebBrowserSession = true
        
        // Start the session and check the result
        if !session.start() {
            print("Failed to start authentication session")
        }
    }
    
    // MARK: - Send Slack Code to Backend
    private func sendSlackCodeToBackend(code: String) {
        guard let url = URL(string: "https://api.memoriousai.com/slacktoken") else {
            print("Invalid Slack token URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "slack_code": code,
            "user_id": Auth.auth().currentUser?.uid ?? ""
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("Failed to serialize Slack request body: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Failed to send Slack code: \(error)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid Slack response")
                return
            }
            
            if httpResponse.statusCode == 200 {
                print("Successfully sent Slack code to backend")
            } else {
                print("Failed to send Slack code. Status code: \(httpResponse.statusCode)")
            }
        }.resume()
    }
    
    // MARK: - Send Microsoft Token to Backend
    private func sendMicrosoftTokenToBackend(accessToken: String) {
        guard let url = URL(string: "https://api.memoriousai.com/microsofttoken") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "microsoft_token": accessToken,
            "user_id": Auth.auth().currentUser?.uid ?? ""
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("Failed to serialize request body: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Failed to send token: \(error)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response")
                return
            }
            
            if httpResponse.statusCode == 200 {
                print("Successfully sent Microsoft token to backend")
            } else {
                print("Failed to send Microsoft token. Status code: \(httpResponse.statusCode)")
            }
        }.resume()
    }
    
    // MARK: - Send Google Token to Backend
    private func sendGoogleTokenToBackend(user: GIDGoogleUser) {
        let accessToken = user.accessToken.tokenString
        
        guard let url = URL(string: "https://api.memoriousai.com/googletoken") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "google_token": accessToken,
            "user_id": Auth.auth().currentUser?.uid ?? ""
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("Failed to serialize request body: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Failed to send token: \(error)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response")
                return
            }
            
            if httpResponse.statusCode == 200 {
                print("Successfully sent Google token to backend")
            } else {
                print("Failed to send token. Status code: \(httpResponse.statusCode)")
            }
        }.resume()
    }
    
    // MARK: - Request Permissions (Microphone, Speech, Camera)
    private func requestPermissions(completion: @escaping () -> Void) {
        #if targetEnvironment(simulator)
        print("Simulator detected: granting permissions automatically.")
        DispatchQueue.main.async {
            completion()
        }
        #else
        requestMicrophonePermission { micGranted in
            if micGranted {
                requestSpeechRecognitionPermission { speechGranted in
                    if speechGranted {
                        requestCameraPermission { cameraGranted in
                            if cameraGranted {
                                DispatchQueue.main.async {
                                    completion()
                                }
                            } else {
                                DispatchQueue.main.async {
                                    alertMessage = "This app needs access to the camera to function properly."
                                    showAlert = true
                                }
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            alertMessage = "This app needs access to speech recognition to function properly."
                            showAlert = true
                        }
                    }
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
    
    private func requestSpeechRecognitionPermission(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            completion(authStatus == .authorized)
        }
    }
    
    private func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            completion(granted)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthViewModel())
    }
}
