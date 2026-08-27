import Foundation
import Observation
import WTMCore

@MainActor
@Observable
public final class ProfileViewModel {
    public var displayName: String
    public var phone: String
    public var email: String
    public var isSaving = false
    public var errorMessage: String?

    private var user: WTMUser
    private let profileService: any ProfileServicing

    public init(user: WTMUser, profileService: any ProfileServicing) {
        self.user = user
        self.displayName = user.displayName ?? ""
        self.phone = user.phone ?? ""
        self.email = user.email ?? ""
        self.profileService = profileService
    }

    @discardableResult
    public func save() async -> Bool {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        user.displayName = displayName.isEmpty ? nil : displayName
        user.phone = phone.isEmpty ? nil : phone
        user.email = email.isEmpty ? nil : email

        do {
            try await profileService.update(user)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
