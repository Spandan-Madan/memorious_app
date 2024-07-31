import SwiftUI

struct ChartView: View {
    let scores: [(Int, Date)]
    
    var body: some View {
        VStack {
            Text("Score History")
                .font(.headline)
            
            HStack(alignment: .bottom) {
                ForEach(scores, id: \.1) { score in
                    VStack {
                        Text("\(score.0)")
                            .font(.caption)
                            .rotationEffect(.degrees(-90))
                            .offset(y: score.0 > 0 ? 0 : 20)
                        
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: 20, height: CGFloat(score.0) * 10)
                        
                        Text(scoreDateString(score.1))
                            .font(.caption)
                            .rotationEffect(.degrees(-90))
                            .frame(height: 40)
                            .offset(y: 10)
                    }
                }
            }
        }
        .padding()
    }
    
    func scoreDateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}
