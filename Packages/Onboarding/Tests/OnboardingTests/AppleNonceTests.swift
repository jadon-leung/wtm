import Testing
@testable import Onboarding

@Suite
struct AppleNonceTests {
    @Test
    func randomStringHasRequestedLength() {
        #expect(AppleNonce.randomString(length: 24).count == 24)
    }

    @Test
    func sha256IsDeterministic() {
        #expect(AppleNonce.sha256("hello") == AppleNonce.sha256("hello"))
        #expect(AppleNonce.sha256("hello") != AppleNonce.sha256("world"))
    }
}
