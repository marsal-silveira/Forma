import SwiftUI

public extension Forma {

    /// On/off switch bound to a `Bool` value.
    struct ToggleRow: Row {
        public let id: String
        let title: LocalizedStringKey

        public init(id: String, title: LocalizedStringKey) {
            self.id = id
            self.title = title
        }

        public func content(store: FormStore) -> AnyView {
            AnyView(ContentView(row: self, store: store))
        }
    }
}

public extension Forma.ToggleRow {
    /// Typed `onChange`; receives `nil` when the value is cleared.
    /// Shadows the untyped `Row` overload for call-site convenience.
    func onChange(_ handler: @escaping (Bool?) -> Void) -> Forma.AnyRow {
        eraseToAnyRow().onChange { handler($0.flatMap { value in value as? Bool }) }
    }

    /// Typed validation rule; receives `nil` when the value is unset or
    /// cleared. Return an error message when invalid, `nil` when valid.
    /// Shadows the untyped `Row` overload for call-site convenience.
    func validation(_ rule: @escaping (Bool?) -> String?) -> Forma.AnyRow {
        eraseToAnyRow().validation { rule($0.flatMap { value in value as? Bool }) }
    }
}

extension Forma.ToggleRow {

    public struct ContentView: View {
        let row: Forma.ToggleRow
        @ObservedObject var store: FormStore

        public var body: some View {
            Toggle(row.title, isOn: store.binding(for: row.id, default: false))
        }
    }
}
