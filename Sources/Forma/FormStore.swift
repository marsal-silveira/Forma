import Combine
import SwiftUI

/// Observable value storage backing a ``FormView``.
///
/// Values are keyed by each row's string `id`.
/// Rows never own their values: they read and write through typed ``Binding``s
/// produced by this store, so the whole form state can be inspected, snapshotted
/// or reset from a single place.
///
/// - Note: `ObservableObject` + `@Published` is used instead of `@Observable`
///   because the Playground deployment floor is iOS 15. Migration to `@Observable`
///   is mechanical once the floor reaches iOS 17.
public final class FormStore: ObservableObject {

    /// Raw storage. `@Published` so views observing the store invalidate on any write.
    @Published private var storage: [String: Any]

    /// Optional hook fired after every write, with the row `id` and the new value
    /// (`nil` when the value was cleared).
    public var onValueChange: ((String, Any?) -> Void)?

    /// Optional hook fired by ``resetValues()``, after storage is emptied.
    /// Used by ``FormStorePersistence`` to clear persisted values.
    public var onReset: (() -> Void)?

    /// Per-row change callbacks, keyed by row id. ``FormView`` registers these
    /// from the descriptor; fired by ``setValue(_:for:)`` before `onValueChange`.
    private var rowCallbacks: [String: (Any?) -> Void] = [:]

    public init(initialValues: [String: Any] = [:]) {
        self.storage = initialValues
    }

    /// Replaces all per-row change callbacks. Called by ``FormView`` whenever
    /// it is (re)created with a descriptor; replacement is idempotent and does
    /// not publish a change.
    public func replaceRowCallbacks(_ callbacks: [String: (Any?) -> Void]) {
        rowCallbacks = callbacks
    }

    /// Snapshot of all non-nil values currently held by the store.
    /// Provides a snapshot of the store's current values.
    public var values: [String: Any] {
        storage
    }

    /// Typed read. Returns `nil` when the id is absent or holds another type.
    public func value<Value>(for id: String) -> Value? {
        storage[id] as? Value
    }

    /// Untyped read. Used by validation, which operates on the raw value
    /// before casting inside typed rule closures.
    public func rawValue(for id: String) -> Any? {
        storage[id]
    }

    /// Typed read with a fallback for absent values.
    public func value<Value>(for id: String, default defaultValue: Value) -> Value {
        value(for: id) ?? defaultValue
    }

    /// Writes a value. Passing `nil` clears the entry.
    /// Fires the row's `onChange` callback (if any) and then `onValueChange`.
    public func setValue<Value>(_ value: Value?, for id: String) {
        storage[id] = value
        rowCallbacks[id]?(value)
        onValueChange?(id, value)
    }

    /// Two-way binding used by row views. Reads fall back to `defaultValue`
    /// until the first write.
    public func binding<Value>(for id: String, default defaultValue: Value) -> Binding<Value> {
        Binding(
            get: { [weak self] in
                self?.value(for: id) ?? defaultValue
            },
            set: { [weak self] newValue in
                self?.setValue(newValue, for: id)
            }
        )
    }

    /// Clears every stored value. Intentionally does **not** fire change
    /// callbacks — views re-render from the emptied store, but `onChange`
    /// handlers only fire on explicit writes. Fires `onReset` afterwards.
    public func resetValues() {
        storage.removeAll()
        onReset?()
    }
}
