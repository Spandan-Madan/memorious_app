import SwiftUI

struct ResultView: View {
    let score: Int
    let resultMessage: String
    
    @State private var scores: [(Int, Date)] = []
    
    var body: some View {
        VStack {
            Text("Your Score: \(score)")
                .font(.largeTitle)
                .padding()
            
            Text(resultMessage)
                .font(.title2)
                .padding()
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
            
            Spacer()
            
            ChartView(scores: scores) // Display scores using a custom chart view
            
            Spacer()
        }
        .padding()
        .navigationTitle("Result")
        .onAppear {
            saveResult()
            loadResults()
        }
    }
    
    func saveResult() {
        let result = ["score": score, "date": Date()] as [String : Any]
        var results = UserDefaults.standard.array(forKey: "TestResults") as? [[String: Any]] ?? []
        results.append(result)
        UserDefaults.standard.set(results, forKey: "TestResults")
    }
    
    func loadResults() {
        let results = UserDefaults.standard.array(forKey: "TestResults") as? [[String: Any]] ?? []
        scores = results.compactMap { result in
            if let score = result["score"] as? Int, let date = result["date"] as? Date {
                return (score, date)
            }
            return nil
        }
    }
}

struct ResultView_Previews: PreviewProvider {
    static var previews: some View {
        ResultView(score: 10, resultMessage: "At Risk: Check your diet, yoga and meditation might be good.")
    }
}

