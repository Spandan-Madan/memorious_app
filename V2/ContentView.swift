import SwiftUI
import AVFoundation
import Speech
import VisionKit

struct ContentView: View {
    @State private var navigateToQuestionnaire = false
    @State private var navigateToChartView = false
    @State private var chartScores: [(Int, Date)] = []
    @State private var showAlert = false
    @State private var alertMessage = ""

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
                    
                    Text("Welcome,\n Spandan.")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("We hope to assist your memory loss with AI.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Button(action: {
                        requestPermissions {
                            loadChartData()
                            navigateToChartView = true
                        }
                    }) {
                        Text("Progress Report")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.black)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        requestPermissions {
                            navigateToQuestionnaire = true
                        }
                    }) {
                        Text("Launch Memory Test")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.black)
                            .cornerRadius(10)
                    }
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
                NavigationLink(destination: QuestionnaireView(), isActive: $navigateToQuestionnaire) {
                    EmptyView()
                }
            )
            .background(
                NavigationLink(destination: ChartView(scores: chartScores), isActive: $navigateToChartView) {
                    EmptyView()
                }
            )
        }
    }
    
    func loadChartData() {
        let results = UserDefaults.standard.array(forKey: "TestResults") as? [[String: Any]] ?? []
        chartScores = results.compactMap { result in
            if let score = result["score"] as? Int, let date = result["date"] as? Date {
                return (score, date)
            }
            return nil
        }
    }
    
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
    
    private func requestVisionPermission(completion: @escaping (Bool) -> Void) {
        // No explicit VisionKit permission needed; ensure camera/photo library access is granted
        completion(true)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
