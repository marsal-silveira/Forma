import SwiftUI

public extension Forma {

    /// A form row descriptor: a small value type that knows its identity and how
    /// to render itself against a ``FormStore``.
    ///
    /// Rows are descriptors, not views — they are built once, held by the parent,
    /// and turned into views by ``FormView``. Conform to this protocol to add
    /// custom rows.
    ///
    /// The requirement returns `AnyView` (instead of an associated type) so the
    /// protocol stays flat: SwiftLint's `nesting` rule counts associated types
    /// as an extra nesting level.
    protocol Row {

        /// Stable identity. Doubles as the storage key in ``FormStore``
        /// and as the `ForEach` identity when rendering.
        var id: String { get }

        /// Produces the row's view. Implementations should read and write
        /// values exclusively through `store`.
        func content(store: FormStore) -> AnyView
    }

    /// Type-erased row so heterogeneous rows can live in a single section array.
    /// Also carries the behavior modifiers (`.hidden`, `.onChange`). Erasure
    /// happens once per row at descriptor-build time.
    struct AnyRow: Identifiable {
        public let id: String

        /// Evaluated on every store change; the row is hidden while it returns
        /// `true`. Set via `.hidden(_:)`.
        public private(set) var hiddenCondition: ((FormStore) -> Bool)?

        /// Called with the new value (`nil` when cleared) whenever the row's
        /// value changes. Set via `.onChange(_:)`.
        public private(set) var changeHandler: ((Any?) -> Void)?

        /// Validation rule: receives the current value (`nil` when unset or of
        /// another type) and returns an error message, or `nil` when valid.
        /// Set via `.validation(_:)`. Named `validationRule` so the stored
        /// property doesn't shadow the `.validation(_:)` modifier in chains.
        public private(set) var validationRule: ((Any?) -> String?)?

        private let render: (FormStore) -> AnyView

        public init<R: Row>(_ row: R) {
            self.id = row.id
            self.render = row.content
        }

        public func isHidden(store: FormStore) -> Bool {
            hiddenCondition?(store) ?? false
        }

        /// The current validation error, or `nil` when the row is valid
        /// (or has no rule).
        public func validationError(store: FormStore) -> String? {
            validationRule?(store.rawValue(for: id))
        }

        public func content(store: FormStore) -> AnyView {
            render(store)
        }
    }
}

public extension Forma.AnyRow {

    /// Hides the row while `condition` returns `true`. Dependencies don't need
    /// to be declared — the form re-evaluates all conditions whenever any
    /// value in the store changes, so anything read inside the closure acts
    /// as a dependency.
    func hidden(_ condition: @escaping (FormStore) -> Bool) -> Self {
        var copy = self
        copy.hiddenCondition = condition
        return copy
    }

    /// Untyped change callback. Concrete rows provide typed overloads.
    func onChange(_ handler: @escaping (Any?) -> Void) -> Self {
        var copy = self
        copy.changeHandler = handler
        return copy
    }

    /// Untyped validation rule: return an error message when invalid, `nil`
    /// when valid. Concrete rows provide typed overloads.
    ///
    /// - Note: In modifier chains, apply typed overloads (on concrete rows)
    ///   *before* untyped ones — once a chain returns `AnyRow`, only the
    ///   untyped overload remains: `.validation { (v: String?) in }.hidden { }`.
    func validation(_ rule: @escaping (Any?) -> String?) -> Self {
        var copy = self
        copy.validationRule = rule
        return copy
    }
}

public extension Forma.Row {
    /// Convenience to erase any row without spelling the wrapper type.
    func eraseToAnyRow() -> Forma.AnyRow {
        Forma.AnyRow(self)
    }

    /// Hides the row while `condition` returns `true`. Re-evaluated whenever
    /// any value in the store changes.
    ///
    /// ```swift
    /// Forma.TextRow(id: "videoId", title: "Video ID")
    ///     .hidden { store in !store.value(for: "advancedRow", default: false) }
    /// ```
    func hidden(_ condition: @escaping (FormStore) -> Bool) -> Forma.AnyRow {
        eraseToAnyRow().hidden(condition)
    }

    /// Untyped change callback; receives the raw value (`nil` when cleared).
    /// Prefer the typed overloads on concrete rows (`TextRow`, `ToggleRow`,
    /// `PickerRow`), which shadow this one.
    func onChange(_ handler: @escaping (Any?) -> Void) -> Forma.AnyRow {
        eraseToAnyRow().onChange(handler)
    }

    /// Untyped validation rule: return an error message when invalid, `nil`
    /// when valid. Prefer the typed overloads on concrete rows (`TextRow`,
    /// `ToggleRow`, `PickerRow`), which shadow this one.
    func validation(_ rule: @escaping (Any?) -> String?) -> Forma.AnyRow {
        eraseToAnyRow().validation(rule)
    }
}
