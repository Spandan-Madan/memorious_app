import SwiftUI
import AVFoundation
import Speech

struct CategoryFluencyView: View {
    @StateObject private var audioRecorder = AudioRecorder()
    @StateObject private var audioPlayer = AudioPlayer()
    @StateObject private var speechRecognizer = SpeechRecognizer()
    
    @State private var isRecordingClothing = false
    @State private var isRecordingAnimals = false
    @State private var isPlayingClothing = false
    @State private var isPlayingAnimals = false
    
    @State private var transcribedTextClothing = ""
    @State private var transcribedTextAnimals = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    @State private var scoreClothing = 0
    @State private var scoreAnimals = 0
    
    private let clothingReferenceList: [String] = ["T-shirt", "Shirt", "Blouse", "Sweater", "Hoodie", "Jacket", "Coat", "Vest", "Cardigan", "Tank top", "Polo shirt", "Long-sleeve shirt", "Dress shirt", "Sweatshirt", "Fleece", "Button-down shirt", "Tunic", "Blazer", "Suit jacket", "Raincoat", "Trench coat", "Peacoat", "Overcoat", "Parka", "Windbreaker", "Scarf", "Gloves", "Hat", "Beanie", "Beret", "Cap", "Baseball cap", "Fedora", "Skirt", "Shorts", "Jeans", "Trousers", "Leggings", "Sweatpants", "Joggers", "Chinos", "Cargo pants", "Overalls", "Dress", "Jumpsuit", "Romper", "Pajamas", "Bathrobe", "Underwear", "Socks", "Kimono", "Harem pants", "Culottes", "Capri pants", "Jogging suit", "Blazer jacket", "Tailcoat", "Dinner jacket", "Peplum top", "Camisole", "Bodysuit", "Corset", "Bralette", "Sports bra", "Bathing suit", "Swimsuit", "Cover-up", "Sarong", "Robe", "Poncho", "Cape", "Puffer jacket", "Down jacket", "Duffle coat", "Gilet", "Bolero", "Sweater vest", "Shawl", "Wrap dress", "Shift dress", "Sheath dress", "A-line dress", "Fit-and-flare dress", "Maxi dress", "Midi dress", "Mini dress", "Skater dress", "Sundress", "Shirtdress", "Overall dress", "Dungarees", "Romper dress", "Teddy coat", "Parka coat", "Peacoat", "Trapper hat", "Faux fur coat", "Leather jacket", "Denim jacket", "Puffer vest", "Down vest", "Fleece vest", "Utility vest", "Gown", "Evening dress", "Cocktail dress", "Ball gown", "Tuxedo", "Double-breasted jacket", "Single-breasted jacket", "Wool coat", "Double-breasted coat", "Single-breasted coat", "Gilet", "Track jacket", "Field jacket", "Military jacket", "Biker jacket", "Moto jacket", "Leather vest", "Knit dress", "Sweater dress", "Pullover", "Button-up dress", "Peacoat", "Down parka", "Bermuda shorts", "Board shorts", "Athletic shorts", "Running shorts", "Cargo shorts", "Short-sleeve shirt", "Sleeveless shirt", "V-neck shirt", "Round-neck shirt", "Henley shirt", "Long-sleeve top", "Graphic tee", "Striped shirt", "Plaid shirt", "Checked shirt", "Patterned shirt", "Denim shirt", "Chambray shirt", "Dress pants", "Slacks", "Wide-leg pants", "Slim-fit pants", "Bootcut pants", "High-waisted pants", "Low-rise pants", "Mid-rise pants", "Palazzo pants", "Tapered pants", "Ankle pants", "Cropped pants", "Gaucho pants", "Harem trousers", "Capri trousers", "Chinos", "Track pants", "Sweatpants", "Jogging trousers", "Lounge pants", "Yoga pants", "Leggings", "Compression pants", "Running tights", "Cycling shorts", "Thermal underwear", "Long johns", "Sleepwear", "Nightgown", "Slip dress", "Kimono robe", "Housecoat", "Silk robe", "Velvet robe"]

    private let animalsReferenceList: [String] = ["Cat", "Dog", "Aardvark", "Aardwolf", "Albatross", "Alligator", "Alpaca", "Anteater", "Antelope", "Armadillo", "Baboon", "Bactrian camel", "Badger", "Baiji", "Balinese", "Banded palm civet", "Barn owl", "Barred owl", "Bat", "Beaver", "Binturong", "Bird", "Bison", "Booby", "Bongo", "Bonito", "Bonobo", "Buffalo", "Bull", "Bongo", "Cheetah", "Chimpanzee", "Cobra", "Cockatoo", "Cod", "Colobus monkey", "Coral snake", "Cormorant", "Cougar", "Cow", "Coyote", "Crab", "Crane", "Crocodile", "Dolphin", "Donkey", "Dove", "Dragonfly", "Duck", "Eagle", "Echidna", "Eel", "Elephant", "Elk", "Emu", "Falcon", "Ferret", "Flamingo", "Frog", "Giraffe", "Goat", "Goldfish", "Goose", "Gorilla", "Guanaco", "Guinea pig", "Hawk", "Hedgehog", "Hippopotamus", "Horse", "Hummingbird", "Hyena", "Ibex", "Iguana", "Impala", "Indian elephant", "Indri", "Inchworm", "Jackal", "Jaguar", "Jellyfish", "Kangaroo", "Kingfisher", "Koala", "Komodo dragon", "Kookaburra", "Kudu", "Llama", "Lynx", "Macaw", "Macaque", "Manatee", "Marmot", "Meerkat", "Mole", "Mongoose", "Monkey", "Moose", "Mouse", "Narwhal", "Ocelot", "Octopus", "Opossum", "Orangutan", "Ostrich", "Otter", "Owl", "Panda", "Parrot", "Peacock", "Penguin", "Pig", "Platypus", "Polar bear", "Porcupine", "Possum", "Puma", "Quail", "Rabbit", "Raccoon", "Rat", "Raven", "Reindeer", "Rhino", "Salmon", "Sandpiper", "Sea lion", "Sea otter", "Seal", "Shark", "Sheep", "Shrimp", "Skunk", "Sloth", "Snail", "Snake", "Spider", "Squirrel", "Starling", "Stingray", "Swan", "Tapir", "Tiger", "Toad", "Tortoise", "Toucan", "Trout", "Turkey", "Turtle", "Uakari", "Ull", "Vulture", "Wallaby", "Walrus", "Warthog", "Wasp", "Weasel", "Whale", "Wild boar", "Wolf", "Wombat", "Woodpecker", "Yak", "Zebra"]

    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Category Fluency")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding()
                    
                    Text("I am going to give you a category and I want you to name, as fast as you can, all of the things that belong in that category. For example, if I say ‘articles of clothing,’ you could say ‘shirt,’ ‘tie,’ or ‘hat.’")
                        .font(.body)
                        .padding()
                    
                    // Articles of Clothing Section
                    Text("Can you think of other articles of clothing? Press Start Recording below, and you will have 1 minute to say as many as you can think.")
                        .font(.body)
                        .padding()
                    
                    HStack {
                        Spacer()
                        Button(action: toggleRecordingClothing) {
                            Text(isRecordingClothing ? "Stop Recording Clothing" : "Start Recording Clothing")
                                .padding()
                                .background(isRecordingClothing ? Color.red : Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        Spacer()
                        Button(action: togglePlaybackClothing) {
                            Text(isPlayingClothing ? "Stop Playback Clothing" : "Play Recording Clothing")
                                .padding()
                                .background(Color.yellow)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        Spacer()
                    }
                    
                    if !transcribedTextClothing.isEmpty {
                        Text("Transcription (Clothing):")
                            .font(.headline)
                        Text(transcribedTextClothing)
                            .font(.body)
                            .padding()
                        Text("Score (Clothing): \(scoreClothing)")
                            .font(.headline)
                            .padding()
                    }
                    
                    // Animals Section
                    Text("Now, let's talk about animals. Press Start Recording below, and name as many animals as you can. You will have 1 minute.")
                        .font(.body)
                        .padding()
                    
                    HStack {
                        Spacer()
                        Button(action: toggleRecordingAnimals) {
                            Text(isRecordingAnimals ? "Stop Recording Animals" : "Start Recording Animals")
                                .padding()
                                .background(isRecordingAnimals ? Color.red : Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        Spacer()
                        Button(action: togglePlaybackAnimals) {
                            Text(isPlayingAnimals ? "Stop Playback Animals" : "Play Recording Animals")
                                .padding()
                                .background(Color.yellow)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        Spacer()
                    }
                    
                    if !transcribedTextAnimals.isEmpty {
                        Text("Transcription (Animals):")
                            .font(.headline)
                        Text(transcribedTextAnimals)
                            .font(.body)
                            .padding()
                        Text("Score (Animals): \(scoreAnimals)")
                            .font(.headline)
                            .padding()
                    }
                    
                    NavigationLink(destination: VerbalNamingView()) {
                        Text("Proceed to Verbal Naming Test")
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
    
    private func toggleRecordingClothing() {
        if isRecordingClothing {
            audioRecorder.stopRecording()
            isRecordingClothing = false
            transcribeAudio(for: "clothing")
        } else {
            audioRecorder.startRecording(for: 0)  // Using 0 as the index for clothing
            isRecordingClothing = true
        }
    }
    
    private func togglePlaybackClothing() {
        if isPlayingClothing {
            audioPlayer.stopPlayback()
            isPlayingClothing = false
        } else {
            audioPlayer.startPlayback(for: 0)  // Using 0 as the index for clothing
            isPlayingClothing = true
        }
    }
    
    private func toggleRecordingAnimals() {
        if isRecordingAnimals {
            audioRecorder.stopRecording()
            isRecordingAnimals = false
            transcribeAudio(for: "animals")
        } else {
            audioRecorder.startRecording(for: 1)  // Using 1 as the index for animals
            isRecordingAnimals = true
        }
    }
    
    private func togglePlaybackAnimals() {
        if isPlayingAnimals {
            audioPlayer.stopPlayback()
            isPlayingAnimals = false
        } else {
            audioPlayer.startPlayback(for: 1)  // Using 1 as the index for animals
            isPlayingAnimals = true
        }
    }
    
    private func transcribeAudio(for category: String) {
        speechRecognizer.transcriptionCompletion = { transcription in
            if category == "clothing" {
                self.transcribedTextClothing = transcription
                self.alertMessage = "Your transcription for clothing is: \(transcription)"
                self.scoreClothing = calculateScore(for: transcription, using: clothingReferenceList)
            } else {
                self.transcribedTextAnimals = transcription
                self.alertMessage = "Your transcription for animals is: \(transcription)"
                self.scoreAnimals = calculateScore(for: transcription, using: animalsReferenceList)
            }
            self.showAlert = true
        }
        
        if category == "clothing" {
            speechRecognizer.transcribeAudio(for: 0)  // Using 0 as the index for clothing
        } else {
            speechRecognizer.transcribeAudio(for: 1)  // Using 1 as the index for animals
        }
    }
    
    private func calculateScore(for transcription: String, using referenceList: [String]) -> Int {
        let words = transcription
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
        
        let uniqueWords = Set(words.map { $0.capitalized })
        let referenceSet = Set(referenceList.map { $0.capitalized })
        
        return uniqueWords.intersection(referenceSet).count
    }
}

struct CategoryFluencyView_Previews: PreviewProvider {
    static var previews: some View {
        CategoryFluencyView()
    }
}
