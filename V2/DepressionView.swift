
import SwiftUI

struct DepressionView: View {
    @State private var responses: [Bool?] = Array(repeating: nil, count: 15)
    
    let questions = [
        "Are you basically satisfied with your life?",
        "Have you dropped many of your activities and interests?",
        "Do you feel that your life is empty?",
        "Do you often get bored?",
        "Are you in good spirits most of the time?",
        "Are you afraid that something bad is going to happen to you?",
        "Do you feel happy most of the time?",
        "Do you often feel helpless?",
        "Do you prefer to stay at home, rather than going out and doing things?",
        "Do you feel that you have more problems with memory than most?",
        "Do you think it is wonderful to be alive now?",
        "Do you feel worthless the way you are now?",
        "Do you feel full of energy?",
        "Do you feel that your situation is hopeless?",
        "Do you think that most people are better off than you are?"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Tick mark the answer that best describes how you felt over the past week")) {
                    ForEach(0..<questions.count, id: \.self) { index in
                        HStack {
                            Text(questions[index])
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer()
                            Picker("", selection: $responses[index]) {
                                Text("Yes").tag(true as Bool?)
                                Text("No").tag(false as Bool?)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                    }
                }
                
                Section {
                    Button(action: submitAnswers) {
                        Text("Submit")
                    }
                }
            }
            .navigationBarTitle("Depression Questionnaire", displayMode: .inline)
        }
        .navigationBarBackButtonHidden(true)
    }
    
    func submitAnswers() {
        // Process the responses here
        print("Responses: \(responses)")
    }
}

struct DepressionView_Previews: PreviewProvider {
    static var previews: some View {
        DepressionView()
    }
}

