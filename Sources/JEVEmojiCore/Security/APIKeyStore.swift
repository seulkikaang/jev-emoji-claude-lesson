import Foundation
import Security

/// Storage for the TypeSafe API key. The app uses the Keychain implementation.
public protocol APIKeyStoring: Sendable {
    func hasKey() throws -> Bool
    func readKey() throws -> String?
    func saveKey(_ rawKey: String) throws
    func deleteKey() throws
}

public enum APIKeyValidationError: Error, Equatable, Sendable {
    case empty
    case containsWhitespace
    case tooLong

    public var message: String {
        switch self {
        case .empty: return "API 키를 붙여 넣어 주세요."
        case .containsWhitespace: return "키 중간에 공백이나 줄바꿈이 있어요. 콘솔에서 다시 복사해 주세요."
        case .tooLong: return "키가 너무 길어요. 콘솔에서 키만 다시 복사해 주세요."
        }
    }
}

public enum KeychainError: Error, Equatable, Sendable {
    case unexpectedStatus(OSStatus)
    case invalidData
}

public enum APIKeyValidator {
    public static let maxLength = 512

    /// Returns the trimmed key, or throws if it cannot be a real key.
    public static func validate(_ raw: String) throws -> String {
        let key = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { throw APIKeyValidationError.empty }
        guard !key.contains(where: { $0.isWhitespace }) else { throw APIKeyValidationError.containsWhitespace }
        guard key.count <= maxLength else { throw APIKeyValidationError.tooLong }
        return key
    }
}

/// Keeps the key as a generic password in the user's login Keychain on this Mac.
/// The login Keychain is not synced through iCloud.
public struct KeychainAPIKeyStore: APIKeyStoring {
    public static let defaultService = "local.jevemoji.typesafe"
    public static let defaultAccount = "api-key"

    private let service: String
    private let account: String

    public init(service: String = defaultService, account: String = defaultAccount) {
        self.service = service
        self.account = account
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }

    public func hasKey() throws -> Bool {
        var query = baseQuery
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        switch status {
        case errSecSuccess: return true
        case errSecItemNotFound: return false
        default: throw KeychainError.unexpectedStatus(status)
        }
    }

    public func readKey() throws -> String? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        switch status {
        case errSecSuccess:
            guard let data = item as? Data, let key = String(data: data, encoding: .utf8) else {
                throw KeychainError.invalidData
            }
            return key
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainError.unexpectedStatus(status)
        }
    }

    public func saveKey(_ rawKey: String) throws {
        let data = Data(try APIKeyValidator.validate(rawKey).utf8)

        let updateStatus = SecItemUpdate(
            baseQuery as CFDictionary,
            [kSecValueData as String: data] as CFDictionary
        )
        switch updateStatus {
        case errSecSuccess:
            return
        case errSecItemNotFound:
            var addQuery = baseQuery
            addQuery[kSecValueData as String] = data
            addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            addQuery[kSecAttrLabel as String] = "JEV Emoji TypeSafe API key"
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            guard addStatus == errSecSuccess else { throw KeychainError.unexpectedStatus(addStatus) }
        default:
            throw KeychainError.unexpectedStatus(updateStatus)
        }
    }

    public func deleteKey() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
}
