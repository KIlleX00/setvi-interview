import Foundation

/// `TokenStore` is a class responsible for managing and persisting tokens using the keychain.
class TokenStore: NSObject {

    // MARK: - Properties

    private let secMatchLimit: String! = kSecMatchLimit as String
    private let secReturnData: String! = kSecReturnData as String
    private let secValueData: String! = kSecValueData as String
    private let secAttrAccessible: String! = kSecAttrAccessible as String
    private let secClass: String! = kSecClass as String
    private let secAttrService: String! = kSecAttrService as String
    private let secAttrGeneric: String! = kSecAttrGeneric as String
    private let secAttrAccount: String! = kSecAttrAccount as String

    static let shared = TokenStore()
    
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private let kKeychainServiceName = "com.codeflow.killex.interview.GitHubber"

    private let kAuthorizationToken = "authorizationToken"

    var authorizationToken: String? {
        didSet {
            // Keychain write operation can be expensive, and we can do it asynchronously.
            serialQueue.async(execute: {
                self.setObject(self.authorizationToken, forKey: self.kAuthorizationToken)
            })
        }
    }

    /// The serial queue used for storing tokens to keychain.
    private let serialQueue = DispatchQueue(label: "com.codeflow.authQueue", attributes: [])

    // MARK: - Lifecycle

    /**
     Initializes the `TokenStore` by loading previously stored tokens.
     */
    private override init() {
        super.init()
        reloadTokens()
    }

    func reloadTokens() {
        authorizationToken = objectForKey(kAuthorizationToken)
    }

    // MARK: - Keychain access

    private func objectForKey<T: Codable>(_ keyName: String) -> T? {
        guard let keychainData = dataForKey(keyName) else {
            return nil
        }
        
        return try? decoder.decode(T.self, from: keychainData)
    }

    private func dataForKey(_ keyName: String) -> Data? {
        var keychainQuery = keychainQueryForKey(keyName)

        // Limit search results to one
        keychainQuery[secMatchLimit] = kSecMatchLimitOne

        // Specify we want NSData/CFData returned
        keychainQuery[secReturnData] = kCFBooleanTrue

        var result: AnyObject?
        let status = withUnsafeMutablePointer(to: &result) {
            SecItemCopyMatching(keychainQuery as CFDictionary, UnsafeMutablePointer($0))
        }

        return status == noErr ? result as? Data : nil
    }

    private func setObject<T: Codable>(_ value: T?, forKey keyName: String) {
        if let value = value,
           let data = try? encoder.encode(value) {
            setData(data, forKey: keyName)
        } else if let _: T = objectForKey(keyName) {
            removeObjectForKey(keyName)
        }
    }

    private func removeObjectForKey(_ keyName: String) {
        let keychainQuery = keychainQueryForKey(keyName)

        let status: OSStatus =  SecItemDelete(keychainQuery as CFDictionary);
        if status != errSecSuccess {
            print("Error while deleting '\(keyName)' keychain entry.")
        }
    }

    private func setData(_ value: Data, forKey keyName: String) {
        var keychainQuery = keychainQueryForKey(keyName)

        keychainQuery[secValueData] = value as AnyObject?

        // Protect the keychain entry so it's only available after first device unlocked
        keychainQuery[secAttrAccessible] = kSecAttrAccessibleAfterFirstUnlock

        let status: OSStatus = SecItemAdd(keychainQuery as CFDictionary, nil)

        if status == errSecDuplicateItem {
            updateData(value, forKey: keyName)
        } else if status != errSecSuccess {
            print("Error while creating '\(keyName)' keychain entry.")
        }
    }

    private func updateData(_ value: Data, forKey keyName: String) {
        let keychainQuery = keychainQueryForKey(keyName)

        let status: OSStatus = SecItemUpdate(keychainQuery as CFDictionary, [secValueData: value] as CFDictionary)

        if status != errSecSuccess {
            print("Error while updating '\(keyName)' keychain entry.")
        }
    }

    private func keychainQueryForKey(_ key: String) -> [String : Any] {
        // Setup dictionary to access keychain and specify we are using a generic password (rather than a certificate, internet password, etc)
        var keychainQueryDictionary: [String : Any] = [secClass: kSecClassGenericPassword]

        // Uniquely identify this keychain accessor
        keychainQueryDictionary[secAttrService] = kKeychainServiceName

        // Uniquely identify the account who will be accessing the keychain
        let encodedIdentifier: Data? = key.data(using: String.Encoding.utf8)

        keychainQueryDictionary[secAttrGeneric] = encodedIdentifier
        keychainQueryDictionary[secAttrAccount] = encodedIdentifier

        return keychainQueryDictionary
    }
}
