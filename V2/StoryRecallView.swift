import SwiftUI
import AVFoundation
import Speech

struct StoryRecallView: View {
    @StateObject private var audioRecorder = AudioRecorder()
    @StateObject private var audioPlayer = AudioPlayer()
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @State private var isRecording = false
    @State private var isPlaying = false
    @State private var transcribedText = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    // AVAudioPlayer for playing the story
    @State private var storyPlayer: AVAudioPlayer?
    @State private var isStoryPlaying = false  // To track the state of story playback

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Delayed Recall")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding()
                    
                    Text("I read you a story a few minutes ago. Can you tell me what you remember about that story now? It was a story about a boy. Can you tell it to me now?")
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
                    }
                    
                    NavigationLink(destination: DepressionView()) {
                        Text("Proceed to Number Span Test")
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
                    self.stopStory() // Call stopStory on the main thread
                }
            })
            storyPlayer?.play()
            isStoryPlaying = true
            
            // Stop the story after 22 seconds
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
            storyPlayer = nil // Clear the player
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
            audioRecorder.startRecording(for: 0)  // Using 0 as the question index
            isRecording = true
        }
    }
    
    private func togglePlayback() {
        if isPlaying {
            audioPlayer.stopPlayback()
            isPlaying = false
        } else {
            audioPlayer.startPlayback(for: 0)  // Using 0 as the question index
            isPlaying = true
        }
    }
    
    private func transcribeAudio() {
        speechRecognizer.transcriptionCompletion = { transcription in
            self.transcribedText = transcription
            self.alertMessage = "Your transcription is: \(transcription)"
            self.showAlert = true
        }
        
        speechRecognizer.transcribeAudio(for: 0)  // Using 0 as the question index
    }
}

struct StoryRecallView_Previews: PreviewProvider {
    static var previews: some View {
        StoryRecallView()
    }
}
