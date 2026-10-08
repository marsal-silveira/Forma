import Testing
@testable import Forma

struct FormDescriptorTests {

    @Test
    func buildsSectionsAndRowsInOrder() {
        let descriptor = FormDescriptor {
            Forma.Section(id: "video") {
                Forma.TextRow(id: "videoId", title: "Video ID")
                Forma.ToggleRow(id: "restrictedRow", title: "Restricted")
            }
            Forma.Section(id: "audio") {
                Forma.PickerRow(id: "audioRow", title: "Audio", options: ["en", "pt"])
            }
        }

        #expect(descriptor.sections.map(\.id) == ["video", "audio"])
        #expect(descriptor.sections[0].rows.map(\.id) == ["videoId", "restrictedRow"])
        #expect(descriptor.sections[1].rows.map(\.id) == ["audioRow"])
    }

    @Test
    func supportsConditionalRows() {
        let includeToggle = false
        let descriptor = FormDescriptor {
            Forma.Section(id: "video") {
                Forma.TextRow(id: "videoId", title: "Video ID")
                if includeToggle {
                    Forma.ToggleRow(id: "restrictedRow", title: "Restricted")
                }
            }
        }

        #expect(descriptor.sections[0].rows.map(\.id) == ["videoId"])
    }

    @Test
    func supportsForLoopsInRows() {
        let ids = ["a", "b", "c"]
        let descriptor = FormDescriptor {
            Forma.Section(id: "generated") {
                for id in ids {
                    Forma.ToggleRow(id: id, title: "Toggle")
                }
            }
        }

        #expect(descriptor.sections[0].rows.map(\.id) == ["a", "b", "c"])
    }

    @Test
    func sectionFallsBackToHeaderAsId() {
        let section = Forma.Section(header: "Video") {
            Forma.ToggleRow(id: "row", title: "Toggle")
        }

        #expect(section.id.isEmpty == false)
    }

    @Test
    func rowIdentityMatchesStorageKey() {
        let row = Forma.TextRow(id: "videoId", title: "Video ID")
        let erased = row.eraseToAnyRow()

        #expect(erased.id == "videoId")
    }
}
