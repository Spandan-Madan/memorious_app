import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var navigateToQuestionnaire = false
    @State private var navigateToChartView = false
    @State private var chartScores: [(Int, Date)] = [] // State to hold chart data
    @State private var showAlert = false // State to show alert if permission is denied

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
                        requestMicrophonePermission {
                            loadChartData() // Load stored data before navigation
                            navigateToChartView = true // Trigger navigation to ChartView
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
                        requestMicrophonePermission {
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
                    Alert(title: Text("Microphone Access Denied"),
                          message: Text("This app needs access to the microphone to function properly."),
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
    
    // Function to load past results from UserDefaults
    func loadChartData() {
        let results = UserDefaults.standard.array(forKey: "TestResults") as? [[String: Any]] ?? []
        chartScores = results.compactMap { result in
            if let score = result["score"] as? Int, let date = result["date"] as? Date {
                return (score, date)
            }
            return nil
        }
    }
    
    // Function to request microphone permission
    private func requestMicrophonePermission(completion: @escaping () -> Void) {
        #if targetEnvironment(simulator)
        // Log that we are in the simulator and granting permission automatically
        print("Simulator detected: granting permission automatically.")
        DispatchQueue.main.async {
            completion()
        }
        #else
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                print("Permission granted: \(granted)")
                if granted {
                    completion()
                } else {
                    showAlert = true
                }
            }
        }
        #endif
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

