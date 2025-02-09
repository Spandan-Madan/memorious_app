import SwiftUI
import AVFoundation
import FirebaseAuth

// MARK: - AudioRecorder
class AudioRecorder: ObservableObject {
    @Published var isRecording = false
    private var audioRecorder: AVAudioRecorder?
    
    /// A unique ID for the entire recording session (same for all chunks)
    var recordingId: String?
    
    /// Tracks the current chunk index so each chunk has its own file
    private var currentChunkIndex = 0
    
    /// Starts recording a new chunk.
    /// - Parameter chunkIndex: The starting chunk index (default is 0).
    func startRecording(chunkIndex: Int = 0) {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: .mixWithOthers)
            try audioSession.setActive(true)
            
            // Generate a recordingId for this session if not already set.
            if recordingId == nil {
                recordingId = UUID().uuidString
            }
            
            currentChunkIndex = chunkIndex
            
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            // Use the recordingId plus chunk index for the filename
            let fileName = "\(recordingId!)_chunk_\(currentChunkIndex).m4a"
            let audioFilename = documentsPath.appendingPathComponent(fileName)
            
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()
            isRecording = true
            
            print("Started recording \(fileName)")
        } catch {
            print("Failed to start recording: \(error)")
        }
    }
    
    /// Stops the current recording (does not start a new chunk).
    func stopRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
        print("Stopped recording chunk \(currentChunkIndex)")
    }
    
    /// Stops the current chunk and immediately starts a new one.
    /// - Returns: The URL of the chunk that was just finalized.
    func stopAndAdvanceChunk() -> URL? {
        // Stop current recording
        audioRecorder?.stop()
        let finishedChunkIndex = currentChunkIndex
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let finishedFileName = "\(recordingId!)_chunk_\(finishedChunkIndex).m4a"
        let finishedChunkURL = documentsPath.appendingPathComponent(finishedFileName)
        
        // Advance the chunk index and start a new recording immediately
        currentChunkIndex += 1
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setActive(true)
            
            let newFileName = "\(recordingId!)_chunk_\(currentChunkIndex).m4a"
            let newChunkURL = documentsPath.appendingPathComponent(newFileName)
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            audioRecorder = try AVAudioRecorder(url: newChunkURL, settings: settings)
            audioRecorder?.record()
            
            print("Started recording \(newFileName)")
        } catch {
            print("Error starting new chunk: \(error)")
            audioRecorder = nil
        }
        
        return finishedChunkURL
    }
}

// MARK: - AudioUploadManager
class AudioUploadManager: ObservableObject {
    @Published var isUploading = false
    var onTranscriptionReceived: ((String) -> Void)?
    
    /// Uploads the audio file at the given URL, sending along the recordingId.
    func uploadAudio(fileURL: URL, recordingId: String) {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("Audio file does not exist at path: \(fileURL.path)")
            return
        }
        
        guard let audioData = try? Data(contentsOf: fileURL) else {
            print("Could not load audio file data")
            return
        }
        
        // Prepare the URLRequest for your Flask server
//        let url = URL(string: "https://https://api.memoriousai.com/upload")!
        let url = URL(string: "http://3.144.183.101:6820/upload")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Use a unique multipart boundary
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Build the multipart form body
        var body = Data()
        
        // Append the recordingId field.
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"recordingId\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(recordingId)\r\n".data(using: .utf8)!)
        
        // Append the audio file data.
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        isUploading = true
        
        URLSession.shared.uploadTask(with: request, from: body) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isUploading = false
                
                if let error = error {
                    print("Upload failed: \(error)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("HTTP Status code: \(httpResponse.statusCode)")
                }
                
                if let data = data,
                   let responseDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let message = responseDict["message"] as? String {
                    print("Server response: \(message)")
                    self?.onTranscriptionReceived?("Memories uploaded successfully.")
                }
            }
        }.resume()
    }
}

// MARK: - Message Model
struct Message: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let isAudio: Bool
}

// MARK: - DemoAudioUploadView
struct DemoAudioUploadView: View {
    @StateObject private var audioRecorder = AudioRecorder()
    @StateObject private var uploadManager = AudioUploadManager()
    
    @State private var userQuery = ""
    @State private var messages: [Message] = []
    @State private var isAnimating = false
    // Timer that triggers chunk finalization and upload every 60 seconds.
    @State private var uploadTimer: Timer?
    
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
                                audioRecorder.stopRecording()
                                uploadTimer?.invalidate()
                                uploadTimer = nil
                                
                                // Optionally, upload the final chunk here if needed.
                                if let recId = audioRecorder.recordingId {
                                    messages.append(Message(text: "Audio recording sent for transcription...", isUser: true, isAudio: true))
                                } else {
                                    print("No recording ID available.")
                                }
                            } else {
                                // -- START RECORDING --
                                audioRecorder.startRecording()
                                
                                // Start a timer that every 60 seconds stops the current chunk,
                                // uploads it, and starts a new chunk.
                                uploadTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                                    if let recId = audioRecorder.recordingId,
                                       let chunkURL = audioRecorder.stopAndAdvanceChunk() {
                                        uploadManager.uploadAudio(fileURL: chunkURL, recordingId: recId)
                                        messages.append(Message(text: "Uploaded partial audio chunk...", isUser: true, isAudio: true))
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
        sendMessageToServer(query: messageText, userUID: userUID)
        userQuery = ""
    }
    
    private func sendMessageToServer(query: String, userUID: String) {
//        guard let url = URL(string: "https://api.memoriousai.com/userquery") else {
        guard let url = URL(string: "http://3.144.183.101:6820/userquery") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["query": query, "user_uid": userUID]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body)
            URLSession.shared.uploadTask(with: request, from: jsonData) { data, response, error in
                if let error = error {
                    print("Network error: \(error)")
                    DispatchQueue.main.async {
                        messages.append(Message(text: "Error: Could not connect to server", isUser: false, isAudio: false))
                    }
                    return
                }
                
                guard let data = data else {
                    print("No data received")
                    return
                }
                
                do {
                    if let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let serverResponse = responseDict["response"] as? String {
                        DispatchQueue.main.async {
                            messages.append(Message(text: serverResponse, isUser: false, isAudio: false))
                        }
                    } else {
                        print("Invalid response format")
                        DispatchQueue.main.async {
                            messages.append(Message(text: "Error: Invalid server response", isUser: false, isAudio: false))
                        }
                    }
                } catch {
                    print("JSON parsing error: \(error)")
                    DispatchQueue.main.async {
                        messages.append(Message(text: "Error: Could not parse server response", isUser: false, isAudio: false))
                    }
                }
            }.resume()
        } catch {
            print("JSON encoding error: \(error)")
            messages.append(Message(text: "Error: Could not encode message", isUser: false, isAudio: false))
        }
    }
}

// MARK: - MessageBubble
struct MessageBubble: View {
    let message: Message
    var body: some View {
        HStack {
            if message.isUser { Spacer() }
            VStack(alignment: message.isUser ? .trailing : .leading) {
                if message.isAudio {
                    HStack(spacing: 8) {
                        Image(systemName: "waveform")
                        Text("Audio recording")
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                } else {
                    Text(message.text)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                }
            }
            .background(message.isUser ? Color.blue : Color(.systemGray6))
            .foregroundColor(message.isUser ? .white : .primary)
            .cornerRadius(16)
            if !message.isUser { Spacer() }
        }
    }
}

struct DemoAudioUploadView_Previews: PreviewProvider {
    static var previews: some View {
        DemoAudioUploadView()
    }
}
