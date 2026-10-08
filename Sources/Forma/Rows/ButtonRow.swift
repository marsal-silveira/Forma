import SwiftUI

public extension Forma {

    /// Tappable row performing an action.
    ///
    /// The action receives the ``FormStore`` so handlers can read or mutate
    /// other rows (e.g. a "Reset" row calling ``FormStore/resetValues()``).
    struct ButtonRow: Row {
        public let id: String
        let title: LocalizedStringKey
        let role: ButtonRole?
        let action: (FormStore) -> Void

        public init(
            id: String,
            title: LocalizedStringKey,
            role: ButtonRole? = nil,
            action: @escaping (FormStore) -> Void
        ) {
            self.id = id
            self.title = title
            self.role = role
            self.action = action
        }

        public func content(store: FormStore) -> AnyView {
            AnyView(ContentView(row: self, store: store))
        }
    }
}

extension Forma.ButtonRow {

    public struct ContentView: View {
        let row: Forma.ButtonRow
        let store: FormStore

        public var body: some View {
            Button(role: row.role) {
                row.action(store)
            } label: {
                Text(row.title)
            }
        }
    }
}
