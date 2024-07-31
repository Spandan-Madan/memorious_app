import SwiftUI

struct QuestionnaireView: View {
    @State private var selectedAnswers: [Int?] = Array(repeating: nil, count: 15)
    @State private var navigateToResult = false // State to control navigation
    @State private var trueCount: Int = 0 // To store the count of True answers
    @State private var resultMessage: String = "" // To store the result message
    
    let questions = [
        "From time to time, I forget what day of the week it is.",
        "Sometimes when I’m looking for something, I forget what it is that I’m looking for.",
        "My friends and family seem to think I’m more forgetful now than I used to be.",
        "Sometimes I forget the names of my friends.",
        "It’s hard for me to add two-digit numbers without writing them down.",
        "I frequently miss appointments because I forget them.",
        "I rarely feel energetic.",
        "Small problems upset me more than they once did.",
        "It’s hard for me to concentrate for even an hour.",
        "I often misplace my keys, and when I find them, I often can’t remember putting them there.",
        "I frequently repeat myself.",
        "Sometime I get lost, even when I’m driving somewhere I’ve been before.",
        "Sometimes I forget the point I’m trying to make.",
        "To feel mentally sharp, I depend upon caffeine.",
        "It takes longer for me to learn things than it used to."
    ]
    
    let answers = Array(repeating: ["True", "False"], count: 15)
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Please respond to the questions below.")
                        .font(.title)
                        .padding(.bottom)
                    
                    ForEach(0..<questions.count, id: \.self) { index in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(questions[index])
                                .font(.headline)
                            
                            ForEach(0..<answers[index].count, id: \.self) { answerIndex in
                                Button(action: {
                                    selectedAnswers[index] = answerIndex
                                }) {
                                    HStack {
                                        Text(answers[index][answerIndex])
                                        Spacer()
                                        if selectedAnswers[index] == answerIndex {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                        .padding(.bottom)
                    }
                    
                    Button(action: {
                        // Count the number of "True" answers
                        trueCount = selectedAnswers.compactMap { $0 }.filter { $0 == 0 }.count
                        
                        // Set the result message based on the count
                        switch trueCount {
                        case 12...:
                            resultMessage = "Dangerously high: Please visit a physician soon."
                        case 9...11:
                            resultMessage = "At Risk: Check your diet, yoga and meditation might be good."
                        case 5...8:
                            resultMessage = "Normal: Your brain is functioning okay."
                        default:
                            resultMessage = "Your memory seems to be in good shape!"
                        }
                        
                        // Navigate to the result view
                        navigateToResult = true
                    }) {
                        Text("Submit Answers")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.top)
                    
                    // Navigation link to the result view
                    NavigationLink(
                        destination: ResultView(trueCount: trueCount, resultMessage: resultMessage),
                        isActive: $navigateToResult
                    ) {
                        EmptyView()
                    }
                    .hidden() // Hide the link
                }
                .padding()
            }
            .navigationTitle("Memory Assessment")
        }
    }
}

struct QuestionnaireView_Previews: PreviewProvider {
    static var previews: some View {
        QuestionnaireView()
    }
}
