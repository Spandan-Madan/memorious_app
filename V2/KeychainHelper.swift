import Security
import Foundation

struct KeychainHelper {
    
    static func generateRandomKey() -> Data {
        var key = [UInt8](repeating: 0, count: 32) // 256-bit key
        let result = SecRandomCopyBytes(kSecRandomDefault, key.count, &key)
        return result == errSecSuccess ? Data(key) : Data()
    }
    
    static func storeKey(_ key: Data, for userID: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: userID,
            kSecAttrService as String: "com.yourapp.secretkey",
            kSecAttrSynchronizable as String: true, // ✅ Enables iCloud Keychain Sync
            kSecValueData as String: key
        ]
        
        SecItemDelete(query as CFDictionary) // Ensure no duplicate
        SecItemAdd(query as CFDictionary, nil)
    }

    
    static func getKey(for userID: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: userID,
            kSecAttrService as String: "com.yourapp.secretkey",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess {
            return dataTypeRef as? Data
        }
        return nil
    }
}
