import SwiftUI

struct QuestionnaireView: View {
    @State private var selectedAnswers: [Int?] = Array(repeating: nil, count: 11) // Adjust count based on number of questions
    @State private var navigateToResult = false
    @State private var score: Int = 0 // To store the MMSE score
    @State private var resultMessage: String = ""
    
    // MMSE-style questions
    let questions = [
        "What is today's date? (Day, Month, Year)",
        "What is the name of this place? (Current location)",
        "Please repeat these three words: Apple, Table, Penny.",
        "Count backward from 100 by sevens (e.g., 93, 86, 79...).",
        "What were the three words I asked you to remember?",
        "Please name these objects: (Provide images or show objects).",
        "Follow this command: Take this paper in your right hand, fold it in half, and put it on the floor.",
        "Write a sentence of your choice.",
        "Draw a clock face with the hands showing 10 past 11.",
        "What is 7 + 8?",
        "Repeat this phrase: 'No ifs, ands, or buts.'"
    ]
    
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
                            
                            // Use different UI elements based on question type
                            if index == 1 {
                                // For questions requiring user input (e.g., date, location)
                                TextField("Enter your answer here", text: .constant(""))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .padding()
                            } else if index == 3 {
                                // For questions requiring a number input
                                TextField("Enter your answer here", text: .constant(""))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .padding()
                            } else if index == 8 {
                                // For drawing tasks (you might use an image or a separate view)
                                Text("Draw a clock face on paper.")
                                    .padding()
                            } else {
                                // For simple multiple-choice or text-based questions
                                ForEach(0..<2) { answerIndex in
                                    Button(action: {
                                        selectedAnswers[index] = answerIndex
                                    }) {
                                        HStack {
                                            Text(answerIndex == 0 ? "Correct" : "Incorrect")
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
                        }
                        .padding(.bottom)
                    }
                    
                    Button(action: {
                        // Calculate the score based on answers
                        calculateScore()
                        
                        // Set the result message based on the score
                        resultMessage = determineResultMessage(score)
                        
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
                        destination: ResultView(trueCount: score, resultMessage: resultMessage),
                        isActive: $navigateToResult
                    ) {
                        EmptyView()
                    }
                    .hidden()
                }
                .padding()
            }
            .navigationTitle("Memory Assessment")
        }
    }
    
    func calculateScore() {
        // Implement scoring logic based on the selected answers
        score = selectedAnswers.compactMap { $0 }.count
    }
    
    func determineResultMessage(_ score: Int) -> String {
        switch score {
        case 27...30:
            return "Your cognitive function is normal."
        case 20...26:
            return "You might have some cognitive impairment."
        default:
            return "You should consult a healthcare professional."
        }
    }
}

struct QuestionnaireView_Previews: PreviewProvider {
    static var previews: some View {
        QuestionnaireView()
    }
}

