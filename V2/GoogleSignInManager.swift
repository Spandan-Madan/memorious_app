import Foundation
import GoogleSignIn
import FirebaseAuth
import UIKit

struct GoogleSignInManager {
    
    static func requestGoogleAccess(completion: @escaping (Bool) -> Void) {
        
        guard let rootViewController = UIApplication
            .shared
            .connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: \.isKeyWindow)?
            .rootViewController else {
                print("No root view controller found.")
                completion(false)
                return
        }
        
        let scopes = [
            "https://www.googleapis.com/auth/drive.readonly",
            "https://www.googleapis.com/auth/gmail.readonly"
        ]
        
        GIDSignIn.sharedInstance.signIn(
            withPresenting: rootViewController,
            hint: nil,
            additionalScopes: scopes
        ) { signInResult, error in
            if let error = error {
                print("Failed to add Google scopes: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            guard let signedInUser = signInResult?.user,
                  let grantedScopes = signedInUser.grantedScopes else {
                print("No user or scopes found.")
                completion(false)
                return
            }
            
            let driveGranted = grantedScopes.contains(scopes[0])
            let gmailGranted = grantedScopes.contains(scopes[1])
            
            if driveGranted && gmailGranted {
                print("Google Drive and Gmail access granted.")
                UserDefaults.standard.set(true, forKey: "hasDriveAccess")
                UserDefaults.standard.set(true, forKey: "hasGmailAccess")
                
                sendGoogleTokenToBackend(user: signedInUser)
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    private static func sendGoogleTokenToBackend(user: GIDGoogleUser) {
        let accessToken = user.accessToken.tokenString
        
        guard let url = URL(string: "https://api.memoriousai.com/googletoken") else {
            print("Invalid URL for Google token")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "google_token": accessToken,
            "user_id": Auth.auth().currentUser?.uid ?? ""
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("Failed to serialize Google request body: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Failed to send Google token: \(error)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response from sending Google token")
                return
            }
            
            if httpResponse.statusCode == 200 {
                print("Successfully sent Google token to backend")
            } else {
                print("Failed to send Google token. Status code: \(httpResponse.statusCode)")
            }
        }.resume()
    }
}
