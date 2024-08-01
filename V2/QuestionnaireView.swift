import SwiftUI
import AVFoundation
import SDWebImageSwiftUI

class AudioRecorder: ObservableObject {
    @Published var isRecording = false
    private var audioRecorder: AVAudioRecorder?
    
    func startRecording(for questionIndex: Int) {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioFilename = documentsPath.appendingPathComponent("answer_\(questionIndex).m4a")
            
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()
            
            isRecording = true
        } catch {
            print("Failed to set up recording session")
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
    }
}

class AudioPlayer: ObservableObject {
    @Published var isPlaying = false
    private var audioPlayer: AVAudioPlayer?
    
    func startPlayback(for questionIndex: Int) {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .default)
            
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioFilename = documentsPath.appendingPathComponent("answer_\(questionIndex).m4a")
            
            audioPlayer = try AVAudioPlayer(contentsOf: audioFilename)
            audioPlayer?.play()
            
            isPlaying = true
        } catch {
            print("Playback failed")
        }
    }
    
    func stopPlayback() {
        audioPlayer?.stop()
        isPlaying = false
    }
}

struct QuestionnaireView: View {
    @State private var selectedAnswers: [Int?] = Array(repeating: nil, count: 11)
    @State private var navigateToResult = false
    @State private var score: Int = 0
    @State private var resultMessage: String = ""
    @StateObject private var audioRecorder = AudioRecorder()
    @StateObject private var audioPlayer = AudioPlayer()
    @State private var recordingQuestionIndex: Int? = nil
    @State private var playingQuestionIndex: Int? = nil
    @State private var textResponses: [String] = Array(repeating: "", count: 11)

    let questions = [
        "What is today's date? (Day, Month, Year)",
        "What is the name of this place? (Current location)",
        "Please repeat these three words: Apple, Table, Penny.",
        "Count backward from 100 by sevens (e.g., 93, 86, 79...).",
        "What were the three words I asked you to remember?",
        "Please name these objects: (Provide images or show objects).",
        "Write a sentence of your choice.",
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
                            
                            if index == 5 { // For the question with images
                                VStack {
                                    HStack {
                                        WebImage(url: URL(string: "https://thumbs.dreamstime.com/b/house-icon-24661687.jpg"))
                                            .resizable()
                                            .frame(width: 100, height: 100)
                                        WebImage(url: URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/8/8a/Banana-Single.jpg/1200px-Banana-Single.jpg"))
                                            .resizable()
                                            .frame(width: 100, height: 100)
                                        WebImage(url: URL(string: "https://png.pngtree.com/png-clipart/20230512/original/pngtree-isolated-cat-on-white-background-png-image_9158356.png"))
                                            .resizable()
                                            .frame(width: 100, height: 100)
                                    }
                                    TextField("Enter your answer here", text: $textResponses[index])
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .padding()
                                }
                            } else if [2, 3, 4, 8].contains(index) { // Audio recording for questions 3, 4, 5, and 9
                                HStack {
                                    Button(action: {
                                        if audioRecorder.isRecording && recordingQuestionIndex == index {
                                            audioRecorder.stopRecording()
                                            recordingQuestionIndex = nil
                                        } else {
                                            if audioRecorder.isRecording {
                                                audioRecorder.stopRecording()
                                            }
                                            audioRecorder.startRecording(for: index)
                                            recordingQuestionIndex = index
                                        }
                                    }) {
                                        Text(audioRecorder.isRecording && recordingQuestionIndex == index ? "Stop Recording" : "Start Recording")
                                            .padding()
                                            .background(audioRecorder.isRecording && recordingQuestionIndex == index ? Color.red : Color.blue)
                                            .foregroundColor(.white)
                                            .cornerRadius(10)
                                    }
                                    
                                    Button(action: {
                                        if audioPlayer.isPlaying && playingQuestionIndex == index {
                                            audioPlayer.stopPlayback()
                                            playingQuestionIndex = nil
                                        } else {
                                            if audioPlayer.isPlaying {
                                                audioPlayer.stopPlayback()
                                            }
                                            audioPlayer.startPlayback(for: index)
                                            playingQuestionIndex = index
                                        }
                                    }) {
                                        Text(audioPlayer.isPlaying && playingQuestionIndex == index ? "Stop Playback" : "Play Recording")
                                            .padding()
                                            .background(Color.green)
                                            .foregroundColor(.white)
                                            .cornerRadius(10)
                                    }
                                }
                            } else if index == 1 || index == 0 || index == 6 || index == 7 {
                                TextField("Enter your answer here", text: $textResponses[index])
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .padding()
                            } else {
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
                        calculateScore()
                        resultMessage = determineResultMessage(score)
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
        score = selectedAnswers.compactMap { $0 }.count
        // Note: You may want to add logic to evaluate the audio recordings and text responses
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
