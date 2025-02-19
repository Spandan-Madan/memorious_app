import Security
import Foundation

struct KeychainHelper {
    static func storePassphrase(_ passphrase: String, for userID: String) {
        guard let data = passphrase.data(using: .utf8) else { return }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: userID,
            kSecAttrService as String: "Memorious.passphrase",
            kSecValueData as String: data as Data
        ]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        print("Keychain save status: \(status)")
    }
    
    static func getPassphrase(for userID: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: userID,
            kSecAttrService as String: "Memorious.passphrase",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess,
           let data = dataTypeRef as? Data,
           let passphrase = String(data: data, encoding: .utf8) {
            return passphrase
        }
        return nil
    }
    
    static func deletePassphrase(for userID: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: userID,
            kSecAttrService as String: "Memorious.passphrase"
        ]
        SecItemDelete(query as CFDictionary)
    }
}
