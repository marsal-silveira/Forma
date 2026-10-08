import Foundation
import Testing
@testable import Forma

struct FormStorePersistenceTests {

    private func makePersistence() -> FormStorePersistence {
        let suite = "FormaTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else {
            Issue.record("Failed to create test UserDefaults suite")
            return FormStorePersistence(key: "unused", userDefaults: .standard)
        }
        return FormStorePersistence(key: "formValues", userDefaults: defaults)
    }

    @Test
    func loadReturnsEmptyWhenNothingSaved() {
        let persistence = makePersistence()

        #expect(persistence.load().isEmpty)
    }

    @Test
    func saveAndLoadRoundTripsPlistSafeValues() {
        let persistence = makePersistence()

        persistence.save(values: [
            "videoId": "abc123",
            "muted": true,
            "startAt": 42,
            "ratio": 1.5
        ])

        let loaded = persistence.load()
        #expect(loaded["videoId"] as? String == "abc123")
        #expect(loaded["muted"] as? Bool == true)
        #expect(loaded["startAt"] as? Int == 42)
        #expect(loaded["ratio"] as? Double == 1.5)
    }

    @Test
    func saveFiltersNonPlistSafeValues() {
        let persistence = makePersistence()

        persistence.save(values: [
            "videoId": "abc",
            "custom": NotPlistSafe()
        ])

        let loaded = persistence.load()
        #expect(loaded["videoId"] as? String == "abc")
        #expect(loaded["custom"] == nil)
    }

    @Test
    func resetClearsPersistedValues() {
        let persistence = makePersistence()
        persistence.save(values: ["videoId": "abc"])

        persistence.reset()

        #expect(persistence.load().isEmpty)
    }

    @Test
    func attachAutoSavesOnValueChange() {
        let persistence = makePersistence()
        let store = FormStore()
        persistence.attach(to: store)

        store.setValue("abc", for: "videoId")

        #expect(persistence.load()["videoId"] as? String == "abc")
    }

    @Test
    func attachPreservesExistingChangeHook() {
        let persistence = makePersistence()
        let store = FormStore()
        var hookFired = false
        store.onValueChange = { _, _ in hookFired = true }

        persistence.attach(to: store)
        store.setValue("abc", for: "videoId")

        #expect(hookFired)
        #expect(persistence.load()["videoId"] as? String == "abc")
    }

    @Test
    func attachClearsPersistedValuesOnReset() {
        let persistence = makePersistence()
        let store = FormStore()
        persistence.attach(to: store)
        store.setValue("abc", for: "videoId")

        store.resetValues()

        #expect(persistence.load().isEmpty)
    }

    @Test
    func resetFiresOnResetHook() {
        let store = FormStore(initialValues: ["row": 1])
        var fired = false
        store.onReset = { fired = true }

        store.resetValues()

        #expect(fired)
        #expect(store.values.isEmpty)
    }
}

private class NotPlistSafe {}
