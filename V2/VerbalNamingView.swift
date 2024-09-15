import SwiftUI
import AVFoundation
import Speech

struct VerbalNamingView: View {
    @StateObject private var audioRecorder = AudioRecorder()
    @StateObject private var audioPlayer = AudioPlayer()
    @StateObject private var speechRecognizer = SpeechRecognizer()
    
    @State private var isRecording = Array(repeating: false, count: 10)
    @State private var isPlaying = Array(repeating: false, count: 10)
    @State private var transcribedText = Array(repeating: "", count: 10)
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    @State private var scores = Array(repeating: 0, count: 10)
    
    private let statements = [
        "The part of your shirt that goes around your neck",
        "The thing you hold over your head when it rains",
        "The country where the Great Pyramids are",
        "The animal in the desert with a hump on its back",
        "What you do when you put your nose up to a flower",
        "What happens to a ship if it can no longer float",
        "A structure you drive over to cross a river",
        "A period of ten years",
        "A small amount of money left for the waiter at a restaurant",
        "What you use to sweep the floor"
    ]
    
    private let correctAnswers = [
        "Collar", "Umbrella", "Egypt", "Camel", "Smell", "Sink", "Bridge", "Decade", "Tip", "Broom"
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    Text("Verbal Naming")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding()
                    
                    Text("Now we are going to do something different. I’m going to describe an object or a verb and I want you to tell me the name of what I am describing. What is the name of....")
                        .padding()
                    
                    ForEach(0..<statements.count, id: \.self) { index in
                        VStack(alignment: .leading, spacing: 15) {
                            Text(statements[index])
                                .font(.body)
                                .padding(.bottom, 5)
                            
                            HStack {
                                Spacer()
                                Button(action: { toggleRecording(for: index) }) {
                                    Text(isRecording[index] ? "Stop Recording \(index + 1)" : "Start Recording \(index + 1)")
                                        .padding()
                                        .background(isRecording[index] ? Color.red : Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                                Spacer()
                                
                                Button(action: { togglePlayback(for: index) }) {
                                    Text(isPlaying[index] ? "Stop Playback \(index + 1)" : "Play Recording \(index + 1)")
                                        .padding()
                                        .background(Color.yellow)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                                Spacer()
                            }
                            
                            if !transcribedText[index].isEmpty {
                                Text("Transcription for Statement \(index + 1):")
                                    .font(.headline)
                                Text(transcribedText[index])
                                    .font(.body)
                                    .padding()
                                
                                Text("Score for Statement \(index + 1): \(scores[index])")
                                    .font(.headline)
                                    .padding()
                            }
                        }
                        .padding(.bottom, 20)
                    }
                    
                    NavigationLink(destination: StoryRecallView()) {
                        Text("Proceed to Category Fluency Test")
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .frame(maxWidth: .infinity) // Make button take full width
                    }
                    .padding(.top, 30)
                }
                .padding()
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Transcription"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .onAppear {
                configureAudioSession()
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session: \(error)")
        }
    }
    
    private func toggleRecording(for index: Int) {
        if isRecording[index] {
            audioRecorder.stopRecording()
            isRecording[index] = false
            transcribeAudio(for: index)
        } else {
            audioRecorder.startRecording(for: index)
            isRecording[index] = true
        }
    }
    
    private func togglePlayback(for index: Int) {
        if isPlaying[index] {
            audioPlayer.stopPlayback()
            isPlaying[index] = false
        } else {
            audioPlayer.startPlayback(for: index)
            isPlaying[index] = true
        }
    }
    
    private func transcribeAudio(for index: Int) {
        speechRecognizer.transcriptionCompletion = { transcription in
            self.transcribedText[index] = transcription
            self.scores[index] = calculateScore(for: transcription, correctAnswer: correctAnswers[index])
            self.alertMessage = "Your transcription for Statement \(index + 1) is: \(transcription)"
            self.showAlert = true
        }
        
        speechRecognizer.transcribeAudio(for: index)
    }
    
    private func calculateScore(for transcription: String, correctAnswer: String) -> Int {
        let words = transcription
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
        
        let transcribedAnswer = words.joined(separator: " ").capitalized
        return transcribedAnswer == correctAnswer.capitalized ? 1 : 0
    }
}

struct VerbalNamingView_Previews: PreviewProvider {
    static var previews: some View {
        VerbalNamingView()
    }
}
