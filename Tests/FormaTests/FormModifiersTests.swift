import Testing
@testable import Forma

struct FormModifiersTests {

    // MARK: - Hidden rules

    @Test
    func rowIsVisibleByDefault() {
        let row = Forma.ToggleRow(id: "toggle", title: "Toggle").eraseToAnyRow()

        #expect(row.isHidden(store: FormStore()) == false)
    }

    @Test
    func hiddenConditionIsEvaluatedAgainstStore() {
        let store = FormStore(initialValues: ["advancedRow": false])
        let row = Forma.TextRow(id: "videoId", title: "Video ID")
            .hidden { store in !store.value(for: "advancedRow", default: false) }

        #expect(row.isHidden(store: store) == true)

        store.setValue(true, for: "advancedRow")

        #expect(row.isHidden(store: store) == false)
    }

    @Test
    func chainedModifiersKeepBothBehaviors() {
        let row = Forma.ToggleRow(id: "toggle", title: "Toggle")
            .hidden { _ in false }
            .onChange { _ in }

        #expect(row.hiddenCondition != nil)
        #expect(row.changeHandler != nil)
    }

    @Test
    func sectionIsVisibleByDefault() {
        let section = Forma.Section(id: "section") {
            Forma.ToggleRow(id: "toggle", title: "Toggle")
        }

        #expect(section.isHidden(store: FormStore()) == false)
    }

    @Test
    func sectionHiddenRuleIsEvaluatedAgainstStore() {
        let store = FormStore()
        let section = Forma.Section(id: "actions") {
            Forma.ToggleRow(id: "toggle", title: "Toggle")
        }
        .hidden { store in store.values.isEmpty }

        #expect(section.isHidden(store: store) == true)

        store.setValue(true, for: "toggle")

        #expect(section.isHidden(store: store) == false)
    }

    // MARK: - onChange callbacks

    @Test
    func toggleRowOnChangeReceivesTypedValue() {
        var received: [Bool?] = []
        let row = Forma.ToggleRow(id: "toggle", title: "Toggle")
            .onChange { received.append($0) }

        row.changeHandler?(true)
        row.changeHandler?(nil)

        #expect(received.count == 2)
        #expect(received[0] == true)
        #expect(received[1] == nil)
    }

    @Test
    func textRowOnChangeReceivesTypedValue() {
        var received: [String?] = []
        let row = Forma.TextRow(id: "text", title: "Text")
            .onChange { received.append($0) }

        row.changeHandler?("abc")

        #expect(received == ["abc"])
    }

    @Test
    func pickerRowOnChangeReceivesTypedValue() {
        var received: [String?] = []
        let row = Forma.PickerRow(id: "picker", title: "Picker", options: ["a", "b"])
            .onChange { received.append($0) }

        row.changeHandler?("b")

        #expect(received == ["b"])
    }

    @Test
    func untypedOnChangeReceivesRawValue() {
        var received: [Any?] = []
        let row = Forma.ToggleRow(id: "toggle", title: "Toggle")
            .onChange { (value: Any?) in received.append(value) }

        row.changeHandler?(true)

        #expect(received.count == 1)
        #expect(received[0] as? Bool == true)
    }

    // MARK: - Descriptor collection

    @Test
    func descriptorCollectsRowCallbacks() {
        let descriptor = FormDescriptor {
            Forma.Section(id: "section") {
                Forma.ToggleRow(id: "toggle", title: "Toggle").onChange { _ in }
                Forma.TextRow(id: "text", title: "Text")
            }
        }

        #expect(descriptor.rowCallbacks.count == 1)
        #expect(descriptor.rowCallbacks["toggle"] != nil)
    }
}
