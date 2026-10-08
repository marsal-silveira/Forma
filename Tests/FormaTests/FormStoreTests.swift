import Testing
@testable import Forma

struct FormStoreTests {

    @Test
    func storesAndReadsTypedValue() {
        let store = FormStore()

        store.setValue("abc123", for: "videoId")

        let read: String? = store.value(for: "videoId")
        #expect(read == "abc123")
    }

    @Test
    func returnsNilForAbsentId() {
        let store = FormStore()

        let read: String? = store.value(for: "missing")

        #expect(read == nil)
    }

    @Test
    func returnsDefaultForAbsentId() {
        let store = FormStore()

        let read: Bool = store.value(for: "restrictedRow", default: false)

        #expect(read == false)
    }

    @Test
    func initialValuesAreReadable() {
        let store = FormStore(initialValues: ["restrictedRow": true])

        let read: Bool = store.value(for: "restrictedRow", default: false)

        #expect(read == true)
    }

    @Test
    func settingNilClearsValue() {
        let store = FormStore(initialValues: ["videoId": "abc"])

        store.setValue(nil as String?, for: "videoId")

        let read: String? = store.value(for: "videoId")
        #expect(read == nil)
    }

    @Test
    func bindingWritesThroughToStore() {
        let store = FormStore()
        let binding = store.binding(for: "restrictedRow", default: false)

        binding.wrappedValue = true

        #expect(store.value(for: "restrictedRow", default: false) == true)
    }

    @Test
    func bindingReadsStoreValue() {
        let store = FormStore(initialValues: ["qualityRow": "high"])
        let binding = store.binding(for: "qualityRow", default: "automatic")

        #expect(binding.wrappedValue == "high")
    }

    @Test
    func valuesSnapshotContainsStoredEntries() {
        let store = FormStore()
        store.setValue("abc", for: "videoId")
        store.setValue(true, for: "restrictedRow")

        let snapshot = store.values

        #expect(snapshot.count == 2)
        #expect(snapshot["videoId"] as? String == "abc")
        #expect(snapshot["restrictedRow"] as? Bool == true)
    }

    @Test
    func resetClearsAllValues() {
        let store = FormStore(initialValues: ["videoId": "abc", "restrictedRow": true])

        store.resetValues()

        #expect(store.values.isEmpty)
    }

    @Test
    func rowCallbackFiresOnValueChange() {
        let store = FormStore()
        var fired: [Any?] = []
        store.replaceRowCallbacks(["qualityRow": { fired.append($0) }])

        store.setValue("high", for: "qualityRow")
        store.setValue(nil as String?, for: "qualityRow")

        #expect(fired.count == 2)
        #expect(fired[0] as? String == "high")
        #expect(fired[1] == nil)
    }

    @Test
    func replaceRowCallbacksDiscardsPreviousHandlers() {
        let store = FormStore()
        var oldFired = false
        var newFired = false
        store.replaceRowCallbacks(["row": { _ in oldFired = true }])
        store.replaceRowCallbacks(["row": { _ in newFired = true }])

        store.setValue(1, for: "row")

        #expect(oldFired == false)
        #expect(newFired == true)
    }

    @Test
    func resetValuesDoesNotFireRowCallbacks() {
        let store = FormStore()
        var fired = false
        store.replaceRowCallbacks(["row": { _ in fired = true }])
        store.setValue(1, for: "row")
        fired = false

        store.resetValues()

        #expect(fired == false)
    }

    @Test
    func changeHookFiresWithIdAndValue() {
        let store = FormStore()
        var fired: [(String, Any?)] = []
        store.onValueChange = { id, value in fired.append((id, value)) }

        store.setValue(42, for: "startAt")
        store.setValue(nil as Int?, for: "startAt")

        #expect(fired.count == 2)
        #expect(fired[0].0 == "startAt")
        #expect(fired[0].1 as? Int == 42)
        #expect(fired[1].0 == "startAt")
        #expect(fired[1].1 == nil)
    }
}
