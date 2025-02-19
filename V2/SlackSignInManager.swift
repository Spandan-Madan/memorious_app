import Foundation
import AuthenticationServices
import FirebaseAuth
import UIKit

class SlackAuthHelper: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            return UIApplication.shared.windows.first ?? ASPresentationAnchor()
        }
        return window
    }
}

struct SlackSignInManager {
    
    static func requestSlackAccess(completion: @escaping (Bool) -> Void) {
        let clientId = "8490353320080.8467800772454"
        let scopes = "channels:read"
        let redirectUri = "https://api.memoriousai.com/slack-auth-callback"
        
        // Use a random state to protect against CSRF
        let state = UUID().uuidString
        
        // Use URLComponents to properly encode the URL
        var urlComponents = URLComponents(string: "https://slack.com/oauth/v2/authorize")!
        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "scope", value: scopes),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "state", value: state)
        ]
        
        guard let authUrl = urlComponents.url else {
            print("Invalid Slack authorization URL")
            completion(false)
            return
        }
        
        // Store state for later verification
        UserDefaults.standard.set(state, forKey: "slackAuthState")
        
        print("Starting Slack auth with URL: \(authUrl.absoluteString)")
        
        let slackAuthHelper = SlackAuthHelper()
        let session = ASWebAuthenticationSession(
            url: authUrl,
            callbackURLScheme: "memoriousai.v2"
        ) { callbackURL, error in
            if let error = error {
                print("Slack authentication error: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            guard let callbackURL = callbackURL,
                  let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: true),
                  let queryItems = components.queryItems else {
                print("Invalid callback URL")
                completion(false)
                return
            }
            
            // Get the saved state
            guard let savedState = UserDefaults.standard.string(forKey: "slackAuthState") else {
                print("No saved Slack auth state found")
                completion(false)
                return
            }
            
            // Extract the authorization code and verify state
            if let code = queryItems.first(where: { $0.name == "code" })?.value,
               let returnedState = queryItems.first(where: { $0.name == "state" })?.value,
               returnedState == savedState {
                
                // Clear saved state
                UserDefaults.standard.removeObject(forKey: "slackAuthState")
                
                print("Slack authorization code received: \(code)")
                
                // Send code to backend
                sendSlackCodeToBackend(code: code) { success in
                    if success {
                        // Update local Slack access state
                        UserDefaults.standard.set(true, forKey: "hasSlackAccess")
                        completion(true)
                    } else {
                        completion(false)
                    }
                }
            } else {
                print("State mismatch or missing code")
                completion(false)
            }
        }
        
        session.presentationContextProvider = slackAuthHelper
        
        // For improved security, prefer ephemeral
        session.prefersEphemeralWebBrowserSession = true
        
        // Start the session
        if !session.start() {
            print("Failed to start Slack authentication session")
            completion(false)
        }
    }
    
    private static func sendSlackCodeToBackend(code: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "https://api.memoriousai.com/slacktoken") else {
            print("Invalid Slack token URL")
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "slack_code": code,
            "user_id": Auth.auth().currentUser?.uid ?? ""
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("Failed to serialize Slack request body: \(error)")
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Failed to send Slack code: \(error)")
                completion(false)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid Slack response")
                completion(false)
                return
            }
            
            if httpResponse.statusCode == 200 {
                print("Successfully sent Slack code to backend")
                completion(true)
            } else {
                print("Failed to send Slack code. Status code: \(httpResponse.statusCode)")
                completion(false)
            }
        }.resume()
    }
}
