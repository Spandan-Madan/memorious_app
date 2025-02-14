import SwiftUI
import AVFoundation
import Speech
import VisionKit
import FirebaseAuth
import GoogleSignIn

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
    
    // Track whether the user has Drive access
    @State private var hasDriveAccess = UserDefaults.standard.bool(forKey: "hasDriveAccess")
    
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
                    
                    // Connect Google Drive Button
                    // Always interactive Google Drive Button
                    Button(action: {
                        requestDriveAccess()
                    }) {
                        HStack {
                            Text(hasDriveAccess ? "Refresh Google connection" : "Connect Google Drive and Mail")
                            if hasDriveAccess {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
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
                NavigationLink(destination: DemoAudioUploadView(),
                               isActive: $navigateToQuestionnaire) {
                    EmptyView()
                }
            )
            .background(
                NavigationLink(destination: DemoAudioUploadView(),
                               isActive: $navigateToCognitiveAssessment) {
                    EmptyView()
                }
            )
            .background(
                NavigationLink(destination: DemoAudioUploadView(),
                               isActive: $navigateToMemoryBot) {
                    EmptyView()
                }
            )
        }
        .onAppear {
            loadChartData()
            checkDriveAccess()
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
    
    // MARK: - Check Drive Access
    private func checkDriveAccess() {
        if let user = GIDSignIn.sharedInstance.currentUser,
           let grantedScopes = user.grantedScopes,
           grantedScopes.contains("https://www.googleapis.com/auth/drive.readonly") {
            self.hasDriveAccess = true
            UserDefaults.standard.set(true, forKey: "hasDriveAccess")
        } else {
            self.hasDriveAccess = false
            UserDefaults.standard.set(false, forKey: "hasDriveAccess")
        }
    }
    
    // MARK: - Request Permissions (Microphone, Speech, Camera)
    private func requestPermissions(completion: @escaping () -> Void) {
        #if targetEnvironment(simulator)
        // Simulator: auto-approve
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
    
    private func sendGoogleTokenToBackend(user: GIDGoogleUser) {
            // Get access token
            let accessToken = user.accessToken.tokenString
            
            // Prepare the URL
//            guard let url = URL(string: "http:/3.144.183.101:6820/googletoken") else {
        guard let url = URL(string: "https://api.memoriousai.com/googletoken") else {
                print("Invalid URL")
                return
            }
            
            // Prepare the request
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // Prepare the body
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
            
            // Make the request
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
    
    // MARK: - Request Google Drive Access
    private func requestDriveAccess() {
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
        
        // Always request a fresh token
        GIDSignIn.sharedInstance.signIn(
            withPresenting: rootViewController,
            hint: nil,
            additionalScopes: ["https://www.googleapis.com/auth/drive.readonly","https://www.googleapis.com/auth/gmail.readonly"]
        ) { signInResult, error in
            if let error = error {
                print("Failed to add Drive scope: \(error.localizedDescription)")
                return
            }
            
            if let signedInUser = signInResult?.user,
               let grantedScopes = signedInUser.grantedScopes,
               grantedScopes.contains("https://www.googleapis.com/auth/drive.readonly") {
                print("Drive access granted.")
                self.hasDriveAccess = true
                UserDefaults.standard.set(true, forKey: "hasDriveAccess")
                sendGoogleTokenToBackend(user: signedInUser)
            }
        }
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthViewModel())
    }
}
