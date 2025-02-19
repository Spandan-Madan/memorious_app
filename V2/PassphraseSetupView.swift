import SwiftUI
import FirebaseAuth
import UIKit

struct PassphraseSetupView: View {
    let userID: String
    let onPassphraseSaved: () -> Void  // Add this property

    @State private var passphrase: String = ""
    @State private var confirmPassphrase: String = ""
    @State private var errorMessage: String = ""
    @State private var isPassphraseVisible: Bool = false
    @State private var isConfirmPassphraseVisible: Bool = false
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        VStack {
            Form {
                Section(header:
                    Text("Security Notice")
                        .font(.headline)
                        .foregroundColor(.blue)
                ) {
                    Text("Your passphrase ensures that only you can access your data. Not even Memorious employees. Keep it safe, as it cannot be recovered.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                
                Section(header: Text("Set Your Passphrase")) {
                    HStack {
                        if isPassphraseVisible {
                            TextField("Enter passphrase", text: $passphrase)
                        } else {
                            SecureField("Enter passphrase", text: $passphrase)
                        }
                        Button {
                            isPassphraseVisible.toggle()
                        } label: {
                            Image(systemName: isPassphraseVisible ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    HStack {
                        if isConfirmPassphraseVisible {
                            TextField("Confirm passphrase", text: $confirmPassphrase)
                        } else {
                            SecureField("Confirm passphrase", text: $confirmPassphrase)
                        }
                        Button {
                            isConfirmPassphraseVisible.toggle()
                        } label: {
                            Image(systemName: isConfirmPassphraseVisible ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .bold()
                        .padding(.vertical, 4)
                }
                
                Button(action: savePassphrase) {
                    Text("Save Passphrase")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .font(.headline)
                }
                .padding(.vertical)
            }
            
            Spacer()
        }
        .navigationTitle("Passphrase Setup")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .padding()
    }
    
    private func savePassphrase() {
        guard !passphrase.isEmpty, !confirmPassphrase.isEmpty else {
            errorMessage = "Both fields are required."
            return
        }
        
        guard passphrase == confirmPassphrase else {
            errorMessage = "Passphrases do not match."
            return
        }
        
        // Store the passphrase in Keychain
        KeychainHelper.storePassphrase(passphrase, for: userID)
        errorMessage = ""
        
        // Notify RootView that setup is complete
        onPassphraseSaved()
    }
}


#if DEBUG
struct PassphraseSetupView_Previews: PreviewProvider {
    static var previews: some View {
        PassphraseSetupView(userID: "12345", onPassphraseSaved: {})
            .environmentObject(AuthViewModel())
    }
}
#endif
