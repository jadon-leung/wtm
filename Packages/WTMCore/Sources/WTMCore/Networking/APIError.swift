import Foundation

public enum APIError: LocalizedError, Sendable {
    case notAuthenticated
    case notFound
    case invalidInviteCode
    case underlying(String)

    public var errorDescription: String? {
        switch self {
        case .notAuthenticated: "You need to be signed in to do that."
        case .notFound: "We couldn't find that."
        case .invalidInviteCode: "That invite link isn't valid or has expired."
        case .underlying(let message): message
        }
    }
}
