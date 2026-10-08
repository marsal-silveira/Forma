import Testing
@testable import Forma

struct FormValidationTests {

    @Test
    func rowWithoutRuleHasNoError() {
        let row = Forma.TextRow(id: "text", title: "Text").eraseToAnyRow()

        #expect(row.validationError(store: FormStore()) == nil)
    }

    @Test
    func textRowValidationReceivesTypedValue() {
        let store = FormStore()
        let row = Forma.TextRow(id: "videoId", title: "Video ID")
            .validation { value in
                guard let value, !value.isEmpty else { return nil }
                return value.count >= 3 ? nil : "Too short"
            }

        #expect(row.validationError(store: store) == nil)

        store.setValue("ab", for: "videoId")
        #expect(row.validationError(store: store) == "Too short")

        store.setValue("abc", for: "videoId")
        #expect(row.validationError(store: store) == nil)
    }

    @Test
    func toggleRowValidationReceivesTypedValue() {
        let store = FormStore(initialValues: ["toggle": true])
        let row = Forma.ToggleRow(id: "toggle", title: "Toggle")
            .validation { value in value == true ? nil : "Must be on" }

        #expect(row.validationError(store: store) == nil)

        store.setValue(false, for: "toggle")
        #expect(row.validationError(store: store) == "Must be on")
    }

    @Test
    func pickerRowValidationReceivesTypedValue() {
        let store = FormStore()
        let row = Forma.PickerRow(id: "quality", title: "Quality", options: ["a", "b"])
            .validation { value in value == nil ? "Pick one" : nil }

        #expect(row.validationError(store: store) == "Pick one")

        store.setValue("a", for: "quality")
        #expect(row.validationError(store: store) == nil)
    }

    @Test
    func untypedValidationReceivesRawValue() {
        let store = FormStore(initialValues: ["row": 42])
        let row = Forma.ToggleRow(id: "row", title: "Row")
            .validation { (value: Any?) in (value as? Int) == 42 ? nil : "Bad" }

        #expect(row.validationError(store: store) == nil)
    }

    @Test
    func validationChainsWithHiddenAndOnChange() {
        let row = Forma.TextRow(id: "text", title: "Text")
            .hidden { _ in false }
            .onChange { _ in }
            .validation { _ in nil }

        #expect(row.hiddenCondition != nil)
        #expect(row.changeHandler != nil)
        #expect(row.validationRule != nil)
    }

    @Test
    func descriptorCollectsOnlyFailingRows() {
        let store = FormStore(initialValues: ["short": "ab", "fine": "abcdef"])
        let descriptor = FormDescriptor {
            Forma.Section(id: "section") {
                Forma.TextRow(id: "short", title: "Short")
                    .validation { value in
                        (value?.count ?? 0) >= 3 ? nil : "Too short"
                    }
                Forma.TextRow(id: "fine", title: "Fine")
                    .validation { value in
                        (value?.count ?? 0) >= 3 ? nil : "Too short"
                    }
                Forma.TextRow(id: "noRule", title: "No rule")
            }
        }

        let errors = descriptor.validationErrors(store: store)

        #expect(errors == ["short": "Too short"])
    }

    @Test
    func descriptorErrorsClearWhenValueBecomesValid() {
        let store = FormStore(initialValues: ["short": "ab"])
        let descriptor = FormDescriptor {
            Forma.Section(id: "section") {
                Forma.TextRow(id: "short", title: "Short")
                    .validation { value in
                        (value?.count ?? 0) >= 3 ? nil : "Too short"
                    }
            }
        }

        #expect(descriptor.validationErrors(store: store).isEmpty == false)

        store.setValue("abc", for: "short")

        #expect(descriptor.validationErrors(store: store).isEmpty)
    }
}
