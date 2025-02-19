import SwiftUI
import FirebaseAuth

// MARK: - Message Model
struct Message: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let isAudio: Bool
}

// MARK: - MessageBubble View
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

// MARK: - MessagingHelper
struct MessagingHelper {
    /// Sends a message query to the server.
    static func sendMessageToServer(query: String, userUID: String, completion: @escaping (Result<String, Error>) -> Void) {
//        guard let url = URL(string: "http://3.144.183.101:6820/userquery") else {
        guard let url = URL(string: "https://api.memoriousai.com/userquery") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }
        
        // Fetch the JWT from Firebase
        Auth.auth().currentUser?.getIDToken { idToken, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let idToken = idToken else {
                completion(.failure(NSError(domain: "JWT error", code: -1)))
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            var body: [String: Any] = [:] // Declare body outside

            if let userSecret = KeychainHelper.getPassphrase(for: userUID) {
                print("Secret key found in Keychain for user \(userSecret)")
                body = [
                    "query": query,
                    "user_uid": userUID,
                    "jwt": idToken,
                    "passphrase": userSecret
                ]
            } else {
                print("Error: No secret key found in Keychain for user \(userUID)")
                body = [
                    "query": query,
                    "user_uid": userUID,
                    "jwt": idToken,
                    "passphrase": userUID
                ]
//                return // Exit if no key is found
            }
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: body)
                request.httpBody = jsonData
                
                URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    
                    guard let data = data else {
                        completion(.failure(NSError(domain: "No data received", code: -1)))
                        return
                    }
                    
                    do {
                        if let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let serverResponse = responseDict["response"] as? String {
                            completion(.success(serverResponse))
                        } else {
                            completion(.failure(NSError(domain: "Invalid response format", code: -1)))
                        }
                    } catch {
                        completion(.failure(error))
                    }
                }.resume()
            } catch {
                completion(.failure(error))
            }
        }
    }
}
