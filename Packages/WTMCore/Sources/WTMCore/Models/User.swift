import Foundation

public struct WTMUser: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var displayName: String?
    public var phone: String?
    public var email: String?
    public var avatarURL: URL?
    public var isGuest: Bool

    public init(
        id: UUID,
        displayName: String? = nil,
        phone: String? = nil,
        email: String? = nil,
        avatarURL: URL? = nil,
        isGuest: Bool = false
    ) {
        self.id = id
        self.displayName = displayName
        self.phone = phone
        self.email = email
        self.avatarURL = avatarURL
        self.isGuest = isGuest
    }

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case phone
        case email
        case avatarURL = "avatar_url"
        case isGuest = "is_guest"
    }
}
