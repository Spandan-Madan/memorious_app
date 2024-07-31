import SwiftUI

struct ContentView: View {
    @State private var navigateToQuestionnaire = false
    @State private var navigateToChartView = false
    @State private var chartScores: [(Int, Date)] = [] // State to hold chart data
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    Image("logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 200)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white)
                        )
                    
                    Text("Welcome")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("We hope to assist your memory loss with AI.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Button(action: {
                        loadChartData() // Load stored data before navigation
                        navigateToChartView = true // Trigger navigation to ChartView
                    }) {
                        Text("Progress Report")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.black)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        navigateToQuestionnaire = true
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
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
