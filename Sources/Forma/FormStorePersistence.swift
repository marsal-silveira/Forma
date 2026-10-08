import Foundation

/// UserDefaults-backed persistence for a ``FormStore``.
/// The Playground's `FormPersistanceHelper` analog.
///
/// Only property-list-safe values are saved (`String`, `Bool`, `Int`,
/// `Double`, `Date`, `Data`, and arrays/dictionaries of those). Custom types
/// (e.g. the Playground's `VideoInfo` or `CLLocation`) are skipped — apps map
/// those manually, the same way `FormPersistanceHelper` does today.
///
/// ```swift
/// let persistence = FormStorePersistence(key: "PlaygroundSettings")
/// let store = FormStore(initialValues: persistence.load())
/// persistence.attach(to: store)   // auto-saves on change, clears on reset
/// ```
public struct FormStorePersistence {

    /// UserDefaults key under which the values dictionary is stored.
    public let key: String

    public let userDefaults: UserDefaults

    public init(key: String, userDefaults: UserDefaults = .standard) {
        self.key = key
        self.userDefaults = userDefaults
    }

    /// Previously saved values, or an empty dictionary when none exist.
    /// Feed into `FormStore(initialValues:)`.
    public func load() -> [String: Any] {
        userDefaults.dictionary(forKey: key) ?? [:]
    }

    /// Saves the property-list-safe subset of `values`.
    public func save(values: [String: Any]) {
        let safe = values.filter { Self.isPropertyListSafe($0.value) }
        userDefaults.set(safe, forKey: key)
    }

    /// Removes the persisted values.
    public func reset() {
        userDefaults.removeObject(forKey: key)
    }

    /// Wires auto-save into the store: every write persists the current
    /// values, and ``FormStore/resetValues()`` clears the persisted values.
    /// Chains any `onValueChange`/`onReset` hooks already set on the store.
    public func attach(to store: FormStore) {
        let previousChange = store.onValueChange
        store.onValueChange = { id, value in
            previousChange?(id, value)
            self.save(values: store.values)
        }
        let previousReset = store.onReset
        store.onReset = {
            previousReset?()
            self.reset()
        }
    }

    private static func isPropertyListSafe(_ value: Any) -> Bool {
        PropertyListSerialization.propertyList(["value": value], isValidFor: .binary)
    }
}
