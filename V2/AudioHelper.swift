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
    @Published var currentChunkIndex = 0
    
    /// The file URL for the chunk that's currently being recorded.
    var currentChunkURL: URL?
    
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
            // Use the recordingId plus chunk index for the filename.
            let fileName = "\(recordingId!)_chunk_\(currentChunkIndex).m4a"
            let audioFilename = documentsPath.appendingPathComponent(fileName)
            
            // Store the URL for later use.
            currentChunkURL = audioFilename
            
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
    
    /// Stops recording and returns the URL of the finalized chunk.
    func stopRecordingAndReturnURL() -> URL? {
        guard let currentFileURL = currentChunkURL else { return nil }
        audioRecorder?.stop()
        isRecording = false
        audioRecorder = nil
        print("Stopped recording chunk \(currentChunkIndex)")
        let finalizedURL = currentFileURL
        currentChunkURL = nil
        return finalizedURL
    }
    
    /// Stops the current chunk and immediately starts a new one.
    /// - Returns: The URL of the chunk that was just finalized.
    func stopAndAdvanceChunk() -> URL? {
        // Ensure we have a valid current chunk URL.
        guard let finishedChunkURL = currentChunkURL else { return nil }
        
        // Stop the current recording.
        audioRecorder?.stop()
        
        // Advance the chunk index.
        currentChunkIndex += 1
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let newFileName = "\(recordingId!)_chunk_\(currentChunkIndex).m4a"
        let newChunkURL = documentsPath.appendingPathComponent(newFileName)
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setActive(true)
            
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            audioRecorder = try AVAudioRecorder(url: newChunkURL, settings: settings)
            audioRecorder?.record()
            
            print("Started recording \(newFileName)")
            // Update the currentChunkURL with the new recording file's URL.
            currentChunkURL = newChunkURL
        } catch {
            print("Error starting new chunk: \(error)")
            audioRecorder = nil
            currentChunkURL = nil
        }
        
        return finishedChunkURL
    }
}

// MARK: - AudioUploadManager
class AudioUploadManager: ObservableObject {
    @Published var isUploading = false
    var onTranscriptionReceived: ((String) -> Void)?
    
    /// Internal queue to hold pending upload requests.
    private var uploadQueue: [(fileURL: URL, recordingId: String)] = []
    
    /// Adds an upload request to the queue.
    func uploadAudio(fileURL: URL, recordingId: String) {
        DispatchQueue.main.async {
            self.uploadQueue.append((fileURL: fileURL, recordingId: recordingId))
            self.processNextUpload()
        }
    }
    
    /// Checks the queue and begins the next upload if no upload is currently in progress.
    private func processNextUpload() {
        guard !isUploading, let nextUpload = uploadQueue.first else {
            return
        }
        uploadQueue.removeFirst()
        isUploading = true
        performUpload(fileURL: nextUpload.fileURL, recordingId: nextUpload.recordingId)
    }
    
    /// Performs the actual upload using URLSession.
    private func performUpload(fileURL: URL, recordingId: String) {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("Audio file does not exist at path: \(fileURL.path)")
            self.isUploading = false
            self.processNextUpload() // Process the next upload if available.
            return
        }
        
        guard let audioData = try? Data(contentsOf: fileURL) else {
            print("Could not load audio file data")
            self.isUploading = false
            self.processNextUpload()
            return
        }
        
        // Fetch JWT before proceeding.
        Auth.auth().currentUser?.getIDToken { idToken, error in
            guard let idToken = idToken, error == nil else {
                print("Error fetching JWT: \(error?.localizedDescription ?? "Unknown error")")
                DispatchQueue.main.async {
                    self.onTranscriptionReceived?("Error: Authentication failed")
                }
                self.isUploading = false
                self.processNextUpload()
                return
            }
            
            // Prepare the URLRequest for your server.
//            let url = URL(string: "http://3.144.183.101:6820/upload")!
            let url = URL(string: "https://api.memoriousai.com/upload")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            // Use a unique multipart boundary.
            let boundary = "Boundary-\(UUID().uuidString)"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            // Build the multipart form body.
            var body = Data()
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"recordingId\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(recordingId)\r\n".data(using: .utf8)!)
            
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"jwt\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(idToken)\r\n".data(using: .utf8)!)
            
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"user_secret\"\r\n\r\n".data(using: .utf8)!)
            body.append("abc123xyz\r\n".data(using: .utf8)!)
            
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
            body.append(audioData)
            body.append("\r\n".data(using: .utf8)!)
            body.append("--\(boundary)--\r\n".data(using: .utf8)!)
            
            URLSession.shared.uploadTask(with: request, from: body) { [weak self] data, response, error in
                DispatchQueue.main.async {
                    self?.isUploading = false
                    
                    if let error = error {
                        print("Upload failed: \(error)")
                        self?.onTranscriptionReceived?("Error: Could not upload audio")
                    } else {
                        if let httpResponse = response as? HTTPURLResponse {
                            print("HTTP Status code: \(httpResponse.statusCode)")
                            // If the file was accepted (even if it's still being processed), display a non-error message.
                            if httpResponse.statusCode == 200 || httpResponse.statusCode == 202 {
                                if let data = data,
                                   let responseDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                                   let message = responseDict["message"] as? String {
                                    print("Server response: \(message)")
                                    self?.onTranscriptionReceived?(message)
                                } else {
                                    self?.onTranscriptionReceived?("Upload accepted, processing.")
                                }
                            } else {
                                // If the status code indicates an error, display an error message.
                                self?.onTranscriptionReceived?("Error: Could not upload audio")
                            }
                        } else {
                            // No valid HTTP response—treat as error.
                            self?.onTranscriptionReceived?("Error: Could not upload audio")
                        }
                    }
                    
                    // Process the next upload in the queue, if any.
                    self?.processNextUpload()
                }
            }.resume()
        }
    }
}
