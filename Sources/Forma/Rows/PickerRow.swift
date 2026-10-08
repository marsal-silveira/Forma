import SwiftUI

public extension Forma {

    /// Single-selection row over a list of options.
    ///
    /// Rendered as a `Menu` showing the current selection, which is the closest
    /// iOS 15-safe equivalent of a push selector. Once the deployment floor is
    /// iOS 16+, this can switch to `.pickerStyle(.navigationLink)` for true
    /// push behavior.
    struct PickerRow<Value: Hashable>: Row {
        public let id: String
        let title: LocalizedStringKey
        let options: [Value]
        let titleForOption: (Value) -> String

        public init(
            id: String,
            title: LocalizedStringKey,
            options: [Value],
            titleForOption: @escaping (Value) -> String = { String(describing: $0) }
        ) {
            self.id = id
            self.title = title
            self.options = options
            self.titleForOption = titleForOption
        }

        public func content(store: FormStore) -> AnyView {
            AnyView(ContentView(row: self, store: store))
        }
    }
}

public extension Forma.PickerRow {
    /// Typed `onChange`; receives `nil` when the value is cleared.
    /// Shadows the untyped `Row` overload for call-site convenience.
    func onChange(_ handler: @escaping (Value?) -> Void) -> Forma.AnyRow {
        eraseToAnyRow().onChange { handler($0.flatMap { value in value as? Value }) }
    }

    /// Typed validation rule; receives `nil` when the value is unset or
    /// cleared. Return an error message when invalid, `nil` when valid.
    /// Shadows the untyped `Row` overload for call-site convenience.
    func validation(_ rule: @escaping (Value?) -> String?) -> Forma.AnyRow {
        eraseToAnyRow().validation { rule($0.flatMap { value in value as? Value }) }
    }
}

extension Forma.PickerRow {

    public struct ContentView: View {
        let row: Forma.PickerRow<Value>
        @ObservedObject var store: FormStore

        private var selection: Binding<Value?> {
            Binding(
                get: { store.value(for: row.id) },
                set: { store.setValue($0, for: row.id) }
            )
        }

        public var body: some View {
            Menu {
                ForEach(row.options, id: \.self) { option in
                    Button {
                        selection.wrappedValue = option
                    } label: {
                        if selection.wrappedValue == option {
                            Label(row.titleForOption(option), systemImage: "checkmark")
                        } else {
                            Text(row.titleForOption(option))
                        }
                    }
                }
            } label: {
                HStack {
                    Text(row.title)
                    Spacer()
                    Text(selection.wrappedValue.map(row.titleForOption) ?? "")
                        .foregroundColor(.secondary)
                }
                .contentShape(Rectangle())
            }
        }
    }
}
