import SwiftUI
import AVFoundation
import Speech

struct StoryView: View {
    @StateObject private var audioRecorder = AudioRecorder()
    @StateObject private var audioPlayer = AudioPlayer()
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @State private var isRecording = false
    @State private var isPlaying = false
    @State private var transcribedText = ""
    @State private var commonWordCount = 0
    @State private var showAlert = false
    @State private var alertMessage = ""

    // AVAudioPlayer for playing the story
    @State private var storyPlayer: AVAudioPlayer?
    @State private var isStoryPlaying = false  // To track the state of story playback
    
    // Reference text to compare with transcription
    let referenceText = """
    Maria's child Ricky played soccer every Monday at 3:30. He liked going to the field behind their house and joining the game. One day, he kicked the ball so hard that it went over the neighbor’s fence where three large dogs lived. The dogs’ owner heard loud barking, came out, and helped them retrieve the ball.
    """

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Story Recall")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding()
                    
                    Text("I am going to read you a story. Listen carefully, and when I am through, I want you to tell me everything you can remember. Click Play Story below to listen to the story.")
                        .font(.body)
                        .padding()
                    
                    HStack {
                        Spacer()
                        Button(action: playStory) {
                            Text("Play Story")
                                .padding()
                                .background(isStoryPlaying ? Color.gray : Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .disabled(isStoryPlaying)
                        
                        Spacer()
                        
                        Button(action: stopStory) {
                            Text("Stop Story")
                                .padding()
                                .background(isStoryPlaying ? Color.red : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .disabled(!isStoryPlaying)
                        
                        Spacer()
                    }
                    
                    Text("Try to use the same words I use but you may also use your own words. Click Start Recording below, and start speaking. If you're not satisfied with your answer, you can always record it again.")
                        .font(.body)
                        .padding()
                    
                    HStack {
                        Spacer()
                        Button(action: toggleRecording) {
                            Text(isRecording ? "Stop Recording" : "Start Recording")
                                .padding()
                                .background(isRecording ? Color.red : Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        
                        Spacer()
                        
                        Button(action: togglePlayback) {
                            Text(isPlaying ? "Stop Playback" : "Play Recording")
                                .padding()
                                .background(Color.yellow)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        Spacer()
                    }
                    
                    if !transcribedText.isEmpty {
                        Text("Transcription:")
                            .font(.headline)
                        Text(transcribedText)
                            .font(.body)
                            .padding()
                        
                        Text("Score: \(commonWordCount)/42")
                            .font(.title)
                            .padding()
                    }
                    
                    NavigationLink(destination: NumberSpanView()) {
                        Text("Proceed to Number Span Test")
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
    }
    
    private func playStory() {
        guard !isStoryPlaying else { return }
        
        guard let url = Bundle.main.url(forResource: "recall_story", withExtension: "mp3") else {
            print("Audio file not found")
            return
        }
        
        do {
            storyPlayer = try AVAudioPlayer(contentsOf: url)
            storyPlayer?.delegate = AVAudioPlayerDelegateWrapper(onFinish: {
                DispatchQueue.main.async {
                    self.stopStory()
                }
            })
            storyPlayer?.play()
            isStoryPlaying = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 21) {
                if self.isStoryPlaying {
                    self.stopStory()
                }
            }
        } catch {
            print("Failed to play audio: \(error)")
        }
    }
    
    private func stopStory() {
        if isStoryPlaying {
            storyPlayer?.stop()
            storyPlayer = nil
            isStoryPlaying = false
        }
    }
    
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session: \(error)")
        }
    }
    
    private func toggleRecording() {
        if isRecording {
            audioRecorder.stopRecording()
            isRecording = false
            transcribeAudio()
        } else {
            audioRecorder.startRecording(for: 0)
            isRecording = true
        }
    }
    
    private func togglePlayback() {
        if isPlaying {
            audioPlayer.stopPlayback()
            isPlaying = false
        } else {
            audioPlayer.startPlayback(for: 0)
            isPlaying = true
        }
    }
    
    private func transcribeAudio() {
        speechRecognizer.transcriptionCompletion = { transcription in
            self.transcribedText = transcription
            self.commonWordCount = calculateCommonWordCount(transcription: transcription, reference: referenceText)
            self.alertMessage = "Your transcription is: \(transcription)"
            self.showAlert = true
        }
        
        speechRecognizer.transcribeAudio(for: 0)
    }

    // Function to calculate the number of common words between transcription and reference text
    private func calculateCommonWordCount(transcription: String, reference: String) -> Int {
        let transcriptionWords = Set(transcription.lowercased().split(separator: " ").map { $0.trimmingCharacters(in: .punctuationCharacters) })
        let referenceWords = Set(reference.lowercased().split(separator: " ").map { $0.trimmingCharacters(in: .punctuationCharacters) })
        
        let commonWords = transcriptionWords.intersection(referenceWords)
        return commonWords.count
    }
}

// A wrapper to handle AVAudioPlayer's delegate methods for tracking when playback finishes
class AVAudioPlayerDelegateWrapper: NSObject, AVAudioPlayerDelegate {
    private let onFinish: () -> Void
    
    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinish()
    }
}

struct StoryView_Previews: PreviewProvider {
    static var previews: some View {
        StoryView()
    }
}
