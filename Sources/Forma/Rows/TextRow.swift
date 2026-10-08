import SwiftUI

public extension Forma {

    /// Single-line text entry bound to a `String` value.
    struct TextRow: Row {
        public let id: String
        let title: LocalizedStringKey
        let placeholder: LocalizedStringKey?

        public init(id: String, title: LocalizedStringKey, placeholder: LocalizedStringKey? = nil) {
            self.id = id
            self.title = title
            self.placeholder = placeholder
        }

        public func content(store: FormStore) -> AnyView {
            AnyView(ContentView(row: self, store: store))
        }
    }
}

public extension Forma.TextRow {
    /// Typed `onChange`; receives `nil` when the value is cleared.
    /// Shadows the untyped `Row` overload for call-site convenience.
    func onChange(_ handler: @escaping (String?) -> Void) -> Forma.AnyRow {
        eraseToAnyRow().onChange { handler($0.flatMap { value in value as? String }) }
    }

    /// Typed validation rule; receives `nil` when the value is unset or
    /// cleared. Return an error message when invalid, `nil` when valid.
    /// Shadows the untyped `Row` overload for call-site convenience.
    func validation(_ rule: @escaping (String?) -> String?) -> Forma.AnyRow {
        eraseToAnyRow().validation { rule($0.flatMap { value in value as? String }) }
    }
}

extension Forma.TextRow {

    public struct ContentView: View {
        let row: Forma.TextRow
        @ObservedObject var store: FormStore

        public var body: some View {
            TextField(
                row.title,
                text: store.binding(for: row.id, default: ""),
                prompt: row.placeholder.map { Text($0) }
            )
        }
    }
}
