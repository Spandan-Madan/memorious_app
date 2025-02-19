import SwiftUI
import FirebaseAuth

struct MemoriesView: View {
    @StateObject private var audioRecorder = AudioRecorder()
    @StateObject private var uploadManager = AudioUploadManager()
    
    @State private var userQuery = ""
    @State private var messages: [Message] = []
    @State private var isAnimating = false
    // Timer that triggers chunk finalization and upload every 60 seconds.
    @State private var uploadTimer: Timer?
    // Timer for polling the server for the memory result.
    @State private var pollingTimer: Timer?
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top UI
                VStack(spacing: 30) {
                    Text("Record Memories")
                        .font(.system(size: 24, weight: .bold))
                        .padding(.top, 20)
                    
                    ZStack {
                        Circle()
                            .stroke(Color(.systemGray4), lineWidth: 3)
                            .frame(width: 50, height: 50)
                        
                        Circle()
                            .trim(from: 0, to: isAnimating ? 1 : 0)
                            .stroke(audioRecorder.isRecording ? Color.red : Color(.systemGray4), lineWidth: 3)
                            .frame(width: 50, height: 50)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: isAnimating)
                        
                        Button(action: {
                            if audioRecorder.isRecording {
                                // -- STOP / FINALIZE --
                                if let recId = audioRecorder.recordingId,
                                   let user = Auth.auth().currentUser {
                                    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                                    let finalFileName = "\(recId)_chunk_\(audioRecorder.currentChunkIndex).m4a"
                                    let finalFileURL = documentsPath.appendingPathComponent(finalFileName)
                                    
                                    audioRecorder.stopRecording()
                                    uploadTimer?.invalidate()
                                    uploadTimer = nil
                                    
                                    uploadManager.uploadAudio(fileURL: finalFileURL, recordingId: recId)
                                    messages.append(Message(text: "Audio recording sent for transcription...", isUser: true, isAudio: true))
                                    
                                    // Start polling for the memory result after upload.
                                    pollMemoryResult(userUID: user.uid)
                                } else {
                                    print("No recording ID or user available.")
                                }
                            } else {
                                // -- START RECORDING --
                                audioRecorder.currentChunkIndex = 0  // Reset chunk index when starting new recording
                                audioRecorder.startRecording()
                                
                                // Start a timer that every 60 seconds stops the current chunk,
                                // uploads it, and starts a new chunk.
                                uploadTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                                    if let recId = audioRecorder.recordingId {
                                        if let chunkURL = audioRecorder.stopAndAdvanceChunk() {
                                            uploadManager.uploadAudio(fileURL: chunkURL, recordingId: recId)
                                            messages.append(Message(text: "Uploaded partial audio chunk...", isUser: true, isAudio: true))
                                        }
                                    }
                                }
                            }
                            
                            // Toggle the animation for the recording ring.
                            isAnimating.toggle()
                        }) {
                            Image(systemName: audioRecorder.isRecording ? "stop.fill" : "mic.fill")
                                .font(.system(size: 22))
                                .foregroundColor(audioRecorder.isRecording ? .red : .primary)
                        }
                    }
                    .padding(.bottom, 20)
                }
                
                Divider()
                
                // Chat area showing messages and upload notifications
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { message in
                            MessageBubble(message: message)
                        }
                    }
                    .padding()
                }
                
                Divider()
                
                // Bottom input area
                HStack(spacing: 12) {
                    TextField("Search a memory...", text: $userQuery)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(20)
                    
                    Button(action: {
                        sendMessage()
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
            }
        }
        .onAppear {
            // Handle transcription messages from the upload manager.
            uploadManager.onTranscriptionReceived = { message in
                DispatchQueue.main.async {
                    messages.append(Message(text: message, isUser: false, isAudio: false))
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func sendMessage() {
        guard let user = Auth.auth().currentUser else {
            print("❌ No authenticated user found!")
            return
        }
        
        let userUID = user.uid
        let messageText = userQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !messageText.isEmpty else {
            messages.append(Message(text: "Please help me find memories about...", isUser: true, isAudio: false))
            userQuery = ""
            return
        }
        messages.append(Message(text: messageText, isUser: true, isAudio: false))
        
        MessagingHelper.sendMessageToServer(query: messageText, userUID: userUID) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    messages.append(Message(text: response, isUser: false, isAudio: false))
                case .failure(let error):
                    messages.append(Message(text: "Error: \(error.localizedDescription)", isUser: false, isAudio: false))
                }
            }
        }
        
        userQuery = ""
    }
    
    /// Polls the server's `/memory_result` endpoint for the computed memory result.
    private func pollMemoryResult(userUID: String) {
        // First, fetch the current Firebase ID token.
        Auth.auth().currentUser?.getIDToken { idToken, error in
            if let error = error {
                print("Error getting token: \(error.localizedDescription)")
                return
            }
            guard let idToken = idToken else {
                print("No token available")
                return
            }
            
            // Replace with your actual server URL.
            let serverURL = "https://api.memoriousai.com/memory_result"
            guard let url = URL(string: serverURL) else {
                print("Invalid server URL")
                return
            }
            
            // Invalidate any existing polling timer.
            pollingTimer?.invalidate()
            
            // Start a new timer that fires every 5 seconds.
            pollingTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { timer in
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                // Attach the Firebase ID token as a Bearer token.
                request.addValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
                
                URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        print("Error polling memory result: \(error.localizedDescription)")
                        return
                    }
                    guard let data = data else {
                        print("No data received from memory result polling.")
                        return
                    }
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                            // Check if the result is ready.
                            if let result = json["intervened_memory"] as? String, !result.isEmpty {
                                DispatchQueue.main.async {
                                    messages.append(Message(text: result, isUser: false, isAudio: false))
                                }
                                timer.invalidate()  // Stop polling once we get the result.
                            } else {
                                print("Memory result not ready yet: \(json)")
                            }
                        }
                    } catch {
                        print("Error parsing memory result JSON: \(error.localizedDescription)")
                    }
                }.resume()
            }
        }
    }
}

struct MemoriesView_Previews: PreviewProvider {
    static var previews: some View {
        MemoriesView()
    }
}
