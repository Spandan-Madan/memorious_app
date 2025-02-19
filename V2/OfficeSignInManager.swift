import Foundation
import MSAL
import FirebaseAuth
import UIKit

struct OfficeSignInManager {
    
    static func requestMicrosoftAccess(completion: @escaping (Bool) -> Void) {
        
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
        
        // Replace with your actual client ID from Azure
        let clientId = "800b6101-120e-4767-a90a-da9efe3e0cd5"
        
        // Use "common" if you selected multi-tenant + personal in Azure,
        // or "organizations" / specific tenant if needed
        let authorityString = "https://login.microsoftonline.com/common"
        
        // Replace with your actual Redirect URI
        let redirectUri = "msauth.MemoriousAI.V2://auth"
        
        do {
            let authorityURL = try MSALAuthority(url: URL(string: authorityString)!)
            let msalConfig = MSALPublicClientApplicationConfig(clientId: clientId,
                                                               redirectUri: redirectUri,
                                                               authority: authorityURL)
            let application = try MSALPublicClientApplication(configuration: msalConfig)
            
            let scopes = [
                "User.Read",
                "Mail.Read",
                "Files.Read",
                "Calendars.Read",
            ]
            
            let webParameters = MSALWebviewParameters(authPresentationViewController: rootViewController)
            let parameters = MSALInteractiveTokenParameters(scopes: scopes, webviewParameters: webParameters)
            
            application.acquireToken(with: parameters) { (result, error) in
                if let error = error {
                    print("Office365 sign-in error: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                guard let result = result else {
                    print("No MSAL result returned.")
                    completion(false)
                    return
                }
                
                // We have a valid access token now
                print("Office365 Access Token: \(result.accessToken)")
                
                UserDefaults.standard.set(true, forKey: "hasOfficeAccess")
                sendMicrosoftTokenToBackend(accessToken: result.accessToken)
                
                completion(true)
            }
        } catch {
            print("Failed to create MSAL application: \(error)")
            completion(false)
        }
    }
    
    private static func sendMicrosoftTokenToBackend(accessToken: String) {
        guard let url = URL(string: "https://api.memoriousai.com/microsofttoken") else {
            print("Invalid URL for Microsoft token")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "microsoft_token": accessToken,
            "user_id": Auth.auth().currentUser?.uid ?? ""
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("Failed to serialize Microsoft request body: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Failed to send Microsoft token: \(error)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response sending Microsoft token")
                return
            }
            
            if httpResponse.statusCode == 200 {
                print("Successfully sent Microsoft token to backend")
            } else {
                print("Failed to send Microsoft token. Status code: \(httpResponse.statusCode)")
            }
        }.resume()
    }
}
