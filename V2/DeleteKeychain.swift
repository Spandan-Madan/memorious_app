import SwiftUI
import FirebaseAuth

struct DeleteKeychainView: View {
    @State private var message: String = ""
    @State private var navigateToContentView = false // State for navigation

    var body: some View {
        VStack(spacing: 20) {
            Text("Delete Keychain Data")
                .font(.title)
                .bold()

            Button(action: deleteKeychainData) {
                Text("Delete All Stored Keys & Passphrases")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .cornerRadius(10)
                    .shadow(radius: 5)
            }

            Text(message)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding()

            // Button to navigate to ContentView
            Button(action: {
                navigateToContentView = true
            }) {
                Text("Continue to App")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .shadow(radius: 5)
            }

            // Hidden NavigationLink that activates when navigateToContentView is true
            NavigationLink(destination: ContentView(), isActive: $navigateToContentView) {
                EmptyView()
            }
        }
        .padding()
    }

    private func deleteKeychainData() {
        if let userID = Auth.auth().currentUser?.uid {
            KeychainHelper.deletePassphrase(for: userID)
            message = "Deleted Key & Passphrase for user: \(userID)"
        } else {
            message = "No logged-in user found."
        }
    }
}

struct DeleteKeychainView_Previews: PreviewProvider {
    static var previews: some View {
        DeleteKeychainView()
    }
}
