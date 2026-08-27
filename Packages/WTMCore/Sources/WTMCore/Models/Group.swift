import Foundation

public enum GroupStatus: String, Codable, Sendable {
    case forming
    case active
    case completed
    case archived
}

public struct WTMGroup: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var name: String
    public var status: GroupStatus
    public var createdBy: UUID
    public var inviteCode: String
    public var createdAt: Date

    public init(
        id: UUID,
        name: String,
        status: GroupStatus = .forming,
        createdBy: UUID,
        inviteCode: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.status = status
        self.createdBy = createdBy
        self.inviteCode = inviteCode
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case status
        case createdBy = "created_by"
        case inviteCode = "invite_code"
        case createdAt = "created_at"
    }
}

public enum GroupMemberRole: String, Codable, Sendable {
    case owner
    case member
}

public struct GroupMember: Identifiable, Codable, Sendable, Hashable {
    public var id: String { "\(groupID)-\(userID)" }
    public var groupID: UUID
    public var userID: UUID
    public var role: GroupMemberRole
    public var joinedAt: Date

    public init(groupID: UUID, userID: UUID, role: GroupMemberRole = .member, joinedAt: Date = .now) {
        self.groupID = groupID
        self.userID = userID
        self.role = role
        self.joinedAt = joinedAt
    }

    enum CodingKeys: String, CodingKey {
        case groupID = "group_id"
        case userID = "user_id"
        case role
        case joinedAt = "joined_at"
    }
}
