import SwiftUI
import AVFoundation

// Delegate class to handle audio playback
class AudioDelegate: NSObject, AVAudioPlayerDelegate {
    var onAudioFinish: (() -> Void)?
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onAudioFinish?()
    }
}

struct NumberSpanView: View {
    @StateObject private var audioRecorder = AudioRecorder()
    @StateObject private var audioPlayer = AudioPlayer()
    @StateObject private var speechRecognizer = SpeechRecognizer()
    
    @State private var isRecording = [Bool]() // Record state for each sequence
    @State private var isPlaying = [Bool]()   // Play state for each sequence
    @State private var transcribedText = [String]() // Transcription for each sequence
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    // Meta list for multiple sequences
    private let audioSequences: [[String]] = [
        ["1", "8", "4"],
        ["2", "7", "9"],
        ["4", "1", "6", "2"],
        ["8", "1", "9", "5"],
        ["6", "4", "9", "2", "8"],
        ["7", "3", "8", "6", "1"],
//        ["3", "9", "2", "4", "7", "5"],
//        ["6", "2", "8", "3", "1", "9"],
//        ["9", "6", "4", "7", "1", "5", "3"],
//        ["7", "4", "9", "2", "6", "8", "1"],
//        ["4", "7", "2", "5", "8", "1", "3", "9"],
//        ["2", "9", "5", "7", "3", "6", "1", "8"],
//        ["6", "8", "4", "1", "9", "3", "5", "2", "7"],
//        ["1", "3", "9", "2", "7", "5", "8", "6", "4"]
    ]
    
    @State private var currentAudioIndex: [Int]
    @State private var isStoryPlaying: [Bool]
    
    // AVAudioPlayer for playing the audio files
    @State private var storyPlayer: AVAudioPlayer?
    
    // Instance of the delegate class
    private var audioDelegate = AudioDelegate()
    
    init() {
        // Initialize state variables based on the number of sequences
        _isRecording = State(initialValue: Array(repeating: false, count: audioSequences.count))
        _isPlaying = State(initialValue: Array(repeating: false, count: audioSequences.count))
        _transcribedText = State(initialValue: Array(repeating: "", count: audioSequences.count))
        _currentAudioIndex = State(initialValue: Array(repeating: 0, count: audioSequences.count))
        _isStoryPlaying = State(initialValue: Array(repeating: false, count: audioSequences.count))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Number Span")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding()
                    
                    Text("I am going to read some numbers. Listen carefully, and when I am through, I want you to tell me the numbers.")
                        .font(.body)
                        .padding()
                    
                    // Dynamic list for playing sequences
                    ForEach(0..<audioSequences.count, id: \.self) { index in
                        VStack {
                            Text("Sequence \(index + 1)")
                                .font(.headline)
                            
                            // Play and Stop buttons for each sequence
                            HStack {
                                Spacer()
                                Button(action: {
                                    currentAudioIndex[index] = 0
                                    playNextStory(for: index)
                                }) {
                                    Text("Play Sequence \(index + 1)")
                                        .padding()
                                        .background(isStoryPlaying[index] ? Color.gray : Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                                .disabled(isStoryPlaying[index])
                                
                                Spacer()
                                
                                Button(action: { stopStory(for: index) }) {
                                    Text("Stop Sequence \(index + 1)")
                                        .padding()
                                        .background(isStoryPlaying[index] ? Color.red : Color.gray)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                                .disabled(!isStoryPlaying[index])
                                Spacer()
                            }
                            
                            // Start/Stop Recording and Play/Stop Playback buttons for each sequence
                            HStack {
                                Spacer()
                                Button(action: { toggleRecording(for: index) }) {
                                    Text(isRecording[index] ? "Stop Recording" : "Start Recording")
                                        .padding()
                                        .background(isRecording[index] ? Color.red : Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                                
                                Spacer()
                                
                                Button(action: { togglePlayback(for: index) }) {
                                    Text(isPlaying[index] ? "Stop Playback" : "Play Recording")
                                        .padding()
                                        .background(Color.yellow)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                                Spacer()
                            }
                            
                            // Display transcription for each sequence
                            if !transcribedText[index].isEmpty {
                                Text("Transcription for Sequence \(index + 1):")
                                    .font(.headline)
                                Text(transcribedText[index])
                                    .font(.body)
                                    .padding()
                            }
                        }
                        .padding(.bottom, 20)
                    }
                    
                    Button(action: calculateScore) {
                                            Text("Calculate Score")
                                                .padding()
                                                .background(Color.orange)
                                                .foregroundColor(.white)
                                                .cornerRadius(10)
                                                .frame(maxWidth: .infinity)
                    }
                    .padding(.top, 30)

                    NavigationLink(destination: CategoryFluencyView()) {
                        Text("Proceed to Category Fluency Test")
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .frame(maxWidth: .infinity)
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
    
    // Play the next audio in the sequence
    private func playNextStory(for index: Int) {
        guard !isStoryPlaying[index] else {
            return
        }
        
        if currentAudioIndex[index] < audioSequences[index].count {
            let fileName = audioSequences[index][currentAudioIndex[index]]
            guard let url = Bundle.main.url(forResource: fileName, withExtension: "mp3") else {
                print("Audio file \(fileName) not found")
                return
            }
            
            do {
                storyPlayer = try AVAudioPlayer(contentsOf: url)
                
                // Assign the delegate and handle completion
                audioDelegate.onAudioFinish = { [self] in
                    stopStory(for: index) // Call stop when the audio finishes
                }
                storyPlayer?.delegate = audioDelegate
                storyPlayer?.play()
                isStoryPlaying[index] = true

                // Stop the story after 1 second
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    if self.isStoryPlaying[index] {
                        self.stopStory(for: index)
                    }
                }
            } catch {
                print("Failed to play audio: \(error)")
            }
        }
    }
    
    // Stop Story function for each sequence
    private func stopStory(for index: Int) {
        if isStoryPlaying[index] {
            storyPlayer?.stop()
            storyPlayer = nil
            isStoryPlaying[index] = false
            
            // Move to the next audio file and play it
            currentAudioIndex[index] += 1
            if currentAudioIndex[index] < audioSequences[index].count {
                // Play the next story after 1 second
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    playNextStory(for: index)
                }
            } else {
                // Reset after all files in the sequence are played
                currentAudioIndex[index] = 0
            }
        }
    }
    
    // Configure audio session
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session: \(error)")
        }
    }
    
    // Toggle Recording for each sequence
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
    
    // Toggle Playback for each sequence
    private func togglePlayback(for index: Int) {
        if isPlaying[index] {
            audioPlayer.stopPlayback()
            isPlaying[index] = false
        } else {
            audioPlayer.startPlayback(for: index)
            isPlaying[index] = true
        }
    }
    
    // Transcribe audio for each sequence
    private func transcribeAudio(for index: Int) {
        speechRecognizer.transcriptionCompletion = { transcription in
            self.transcribedText[index] = transcription
            self.alertMessage = "Your transcription for Sequence \(index + 1) is: \(transcription)"
            self.showAlert = true
        }
        
        speechRecognizer.transcribeAudio(for: index)
    }
    
    private func calculateScore() {
            var score = 0
            
            for (index, sequence) in audioSequences.enumerated() {
                let expectedSequence = sequence.joined(separator: "")
                let transcribedSequence = transcribedText[index].trimmingCharacters(in: .whitespacesAndNewlines)
                
                if expectedSequence == transcribedSequence {
                    score += 1
                }
            }
            
            print("Score: \(score) out of \(audioSequences.count)")
            alertMessage = "Your score is \(score) out of \(audioSequences.count)"
            showAlert = true
    }
}

struct NumberSpanView_Previews: PreviewProvider {
    static var previews: some View {
        NumberSpanView()
    }
}
