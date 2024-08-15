import SwiftUI
import AVFoundation
import SDWebImageSwiftUI
import Speech

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

class SpeechRecognizer: ObservableObject {
    var transcriptionCompletion: ((String) -> Void)?
    
    func transcribeAudio(for questionIndex: Int) {
        let audioURL = audioFileURL(for: questionIndex)
        
        guard FileManager.default.fileExists(atPath: audioURL.path) else {
            print("Audio file does not exist at path: \(audioURL.path)")
            return
        }

        let speechRecognizer = SFSpeechRecognizer()
        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        
        speechRecognizer?.recognitionTask(with: request) { result, error in
            if let error = error {
                print("Error during transcription: \(error.localizedDescription)")
                return
            }
            
            guard let result = result else {
                print("No result found.")
                return
            }
            
            if result.isFinal {
                let transcription = result.bestTranscription.formattedString
                DispatchQueue.main.async {
                    self.transcriptionCompletion?(transcription)
                }
            } else {
                print("Intermediate transcription result: \(result.bestTranscription.formattedString)")
            }
        }
    }
    
    private func audioFileURL(for questionIndex: Int) -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("answer_\(questionIndex).m4a")
    }
}

struct QuestionnaireView: View {
    @State private var selectedAnswers: [Int?] = Array(repeating: nil, count: 11)
    @State private var navigateToResult = false
    @State private var score: Int = 0
    @State private var resultMessage: String = ""
    @StateObject private var audioRecorder = AudioRecorder()
    @StateObject private var audioPlayer = AudioPlayer()
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @State private var recordingQuestionIndex: Int? = nil
    @State private var playingQuestionIndex: Int? = nil
    @State private var textResponses: [String] = Array(repeating: "", count: 11)
    @State private var showAlert = false
    @State private var alertMessage = ""

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
                                        WebImage(url: URL(string: "https://raw.githubusercontent.com/Spandan-Madan/memorious_app/main/V2/noun-camera-6796334.png"))
                                            .resizable()
                                            .frame(width: 100, height: 100)
                                        WebImage(url: URL(string: "https://raw.githubusercontent.com/Spandan-Madan/memorious_app/main/V2/noun-cat-6992177.png"))
                                            .resizable()
                                            .frame(width: 100, height: 100)
                                        WebImage(url: URL(string: "https://github.com/Spandan-Madan/memorious_app/blob/main/noun-coffee-6706442.png?raw=true"))
                                            .resizable()
                                            .frame(width: 100, height: 100)
                                    }
                                    HStack {
                                        Spacer()
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
                                        Spacer()
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

                                                // Set up transcription completion handler
                                                speechRecognizer.transcriptionCompletion = { transcription in
                                                    self.alertMessage = "Your transcription is: \(transcription)"
                                                    self.showAlert = true
                                                }
                                                
                                                // Transcribe the audio after starting playback
                                                speechRecognizer.transcribeAudio(for: index)
                                            }
                                        }) {
                                            Text(audioPlayer.isPlaying && playingQuestionIndex == index ? "Stop Playback" : "Play Recording")
                                                .padding()
                                                .background(Color.green)
                                                .foregroundColor(.white)
                                                .cornerRadius(10)
                                        }
                                        Spacer()
                                    }
                                }
                            } else if [0, 1, 2, 3, 4, 6, 7, 8].contains(index) { // All questions now have audio recording
                                VStack {
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

                                                // Set up transcription completion handler
                                                speechRecognizer.transcriptionCompletion = { transcription in
                                                    self.alertMessage = "Your transcription is: \(transcription)"
                                                    self.showAlert = true
                                                }
                                                
                                                // Transcribe the audio after starting playback
                                                speechRecognizer.transcribeAudio(for: index)
                                            }
                                        }) {
                                            Text(audioPlayer.isPlaying && playingQuestionIndex == index ? "Stop Playback" : "Play Recording")
                                                .padding()
                                                .background(Color.green)
                                                .foregroundColor(.white)
                                                .cornerRadius(10)
                                        }
                                    }
                                    .padding(.top)
                                }
                            } else {
                                TextField("Enter your answer here", text: $textResponses[index])
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .padding()
                            }
                        }
                    }
                    
                    Button(action: {
                        calculateScore()
                        resultMessage = determineResultMessage(score)
                        navigateToResult = true
                    }) {
                        Text("Submit")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.top)
                    .disabled(selectedAnswers.contains(nil))
                    
                    NavigationLink(destination: ResultView(score: score, resultMessage: resultMessage), isActive: $navigateToResult) {
                        EmptyView()
                    }
                }
                .padding()
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Transcription"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                }
            }
            .navigationBarTitle("Questionnaire", displayMode: .inline)
        }
    }
    
    func calculateScore() {
        score = selectedAnswers.compactMap { $0 }.reduce(0, +)
    }
    
    func determineResultMessage(_ score: Int) -> String {
        if score >= 8 {
            return "Great job! You have a strong memory."
        } else if score >= 5 {
            return "Your memory is good, but there might be some room for improvement."
        } else {
            return "Consider doing some memory exercises to strengthen your memory."
        }
    }
}

struct QuestionnaireView_Previews: PreviewProvider {
    static var previews: some View {
        QuestionnaireView()
    }
}
