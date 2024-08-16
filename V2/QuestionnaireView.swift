import SwiftUI
import AVFoundation
import SDWebImageSwiftUI
import Speech
import VisionKit
import Vision
import CoreML

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
    @State private var isImagePickerPresented = false
    @State private var capturedImage: UIImage?
    @State private var detectedObjects: [String] = []
    @State private var showSubmitAlert = false
    @State private var navigateToNewPage = false
    
    let questions = [
        "What is today's date? (Day, Month, Year)",
        "What is the name of this place? (Current location)",
        "Please remember these three words: Apple, Table, Penny. Now, read them aloud.",
        "Count backward from 100 by fives (e.g., 100, 95, ...). Keep going till 75.",
        "I'd like you to say as many words as you can starting with a letter of your choice. Once you start recording, you get 60 seconds to mention as many as you'd like.",
        "Please name these objects:",
        "What is 7 + 8?",
        "I read some words to you earlier, which I asked you to remember. Tell me as many of those words as you can remember.",
        "Repeat this phrase: 'Every day I find happiness and comfort.",
        "Take a picture of a person around you."
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
//                                                speechRecognizer.transcriptionCompletion = { transcription in
//                                                    print("Transcription received for index \(index): \(transcription)")
//                                                    self.textResponses[index] = transcription
//                                                    self.alertMessage = "Transcription received for index \(index): \(transcription)"
////                                                    self.alertMessage = "Your transcription is: \(transcription)"
//                                                    self.showAlert = true
//                                                }
                                                
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
                            } else if index == 9 { // New camera question
                                VStack {
                                    if let image = capturedImage {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 200)
                                        
                                        // Display detected objects
                                        if !detectedObjects.isEmpty {
                                            VStack(alignment: .leading) {
                                                Text("Detected Objects:")
                                                    .font(.headline)
                                                ForEach(detectedObjects, id: \.self) { object in
                                                    Text(object)
                                                }
                                            }
                                            .padding(.top)
                                        }
                                    }
                                    
                                    Button(action: {
                                        isImagePickerPresented = true
                                    }) {
                                        Text(capturedImage == nil ? "Take Picture" : "Retake Picture")
                                            .padding()
                                            .background(Color.blue)
                                            .foregroundColor(.white)
                                            .cornerRadius(10)
                                    }
                                }
                                .sheet(isPresented: $isImagePickerPresented) {
                                    ImagePicker(image: $capturedImage, sourceType: .camera) { image in
                                        detectObjects(in: image)
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
                                                    self.textResponses[index] = transcription
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
                    }) {
                        Text("Submit")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.top)
//                    Button(action: {
//                        // Check if the text at index 2 contains "cambridge"
//                        let targetAnswer = "cambridge"
//                        let userAnswer = textResponses[2].lowercased()
//
//                        if userAnswer.contains(targetAnswer) {
//                            print("Correct")
//                            print(textResponses)
//                        } else {
//                            print("Incorrect")
//                            print(textResponses)
//                        }
//                    }) {
//                        Text("Submit")
//                            .padding()
//                            .background(Color.blue)
//                            .foregroundColor(.white)
//                            .cornerRadius(10)
//                    }
//                    .padding(.top)

                    Button(action: {
                        print("Proceed button clicked")
                        navigateToNewPage = true
//                        navigateToResult = true
                    }) {
                        Text("Proceed")
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.top)

                    // NavigationLink to ResultView
                    NavigationLink(destination: NewPageView(), isActive: $navigateToNewPage) {
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
        score = 0 // Reset the score before calculating
        
        let answer1 = textResponses[0].lowercased()
            let requiredWords1 = ["14", "august", "2024"]
            if requiredWords1.allSatisfy(answer1.contains) {
                score += 1
            }
        
        // Check if the answer at index 2 contains "cambridge"
        let answer2 = textResponses[1].lowercased()
        if answer2.contains("cambridge") {
            score += 1
        }
        
        // Check if the answer at index 3 contains "apple"
        let answer3 = textResponses[2].lowercased()
        let requiredWords3 = ["apple", "table", "penny"]
        if requiredWords3.allSatisfy(answer3.contains) {
            score += 1
        }
        
        let answer4 = textResponses[3].lowercased()
        let requiredWords4 = ["95", "90", "85", "80", "75"]
        if requiredWords4.allSatisfy(answer4.contains) {
            score += 1
        }
        
        let answer6 = textResponses[5].lowercased()
        let requiredWords6 = ["cat", "coffee", "camera"]
        if requiredWords6.allSatisfy(answer6.contains) {
            score += 1
        }
        
        let answer7 = textResponses[6].lowercased()
        if answer7.contains("15") {
            score += 1
        }
        
        let answer8 = textResponses[7].lowercased()
        let requiredWords8 = ["apple", "table", "penny"]
        if requiredWords8.allSatisfy(answer8.contains) {
            score += 1
        }
        
        let answer9 = textResponses[8].lowercased()
        let requiredWords9 = ["every", "day", "happiness", "comfort"]
        if requiredWords9.allSatisfy(answer9.contains) {
            score += 1
        }
        
        /// Display final score in a dialog box
        alertMessage = "Your final score is: \(score)"
        showAlert = true
        
        // Log the final score
        saveResult()
    }

    func saveResult() {
            let result = ["score": score, "date": Date()] as [String : Any]
            var results = UserDefaults.standard.array(forKey: "TestResults") as? [[String: Any]] ?? []
            results.append(result)
            UserDefaults.standard.set(results, forKey: "TestResults")
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
    
    func detectObjects(in image: UIImage) {
        guard let model = try? VNCoreMLModel(for: YOLOv3().model) else {
            print("Failed to load Core ML model")
            return
        }
        
        let request = VNCoreMLRequest(model: model) { request, error in
            if let error = error {
                print("Failed to detect objects: \(error.localizedDescription)")
                return
            }
            
            guard let results = request.results as? [VNRecognizedObjectObservation] else {
                print("Unexpected result type from VNCoreMLRequest")
                return
            }
            
            DispatchQueue.main.async {
                if results.isEmpty {
                    self.alertMessage = "No objects detected."
                } else {
                    self.detectedObjects = results.map { result in
                        return "\(result.labels.first?.identifier ?? "unknown object") with confidence: \(result.confidence)"
                    }
                    self.alertMessage = "Objects detected. Check the list below."
                }
                self.showAlert = true
            }
        }
        
        let handler = VNImageRequestHandler(cgImage: image.cgImage!, options: [:])
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                try handler.perform([request])
            } catch {
                print("Failed to perform object detection: \(error.localizedDescription)")
            }
        }
    }
}


struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType
    let onImagePicked: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
                parent.onImagePicked(image) // Call the callback
            }
            picker.dismiss(animated: true)
        }
    }
}

struct QuestionnaireView_Previews: PreviewProvider {
    static var previews: some View {
        QuestionnaireView()
    }
}
