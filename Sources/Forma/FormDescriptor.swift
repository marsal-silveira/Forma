import SwiftUI

/// A whole form, described as data: an ordered list of sections.
///
/// Build it once (it is a value type) and hand it to ``FormView`` together
/// with a ``FormStore``:
///
/// ```swift
/// let descriptor = FormDescriptor {
///     Forma.Section(header: "Video") {
///         Forma.TextRow(id: "videoId", title: "Video ID")
///         Forma.ToggleRow(id: "restricted", title: "Allow restricted content")
///     }
/// }
/// ```
public struct FormDescriptor {
    public let sections: [Forma.Section]

    public init(@Forma.DescriptorBuilder sections: () -> [Forma.Section] = { [] }) {
        self.sections = sections()
    }

    /// Change callbacks of all rows, keyed by row id. Registered into the
    /// store by ``FormView``.
    var rowCallbacks: [String: (Any?) -> Void] {
        sections.flatMap(\.rows).reduce(into: [:]) { result, row in
            if let handler = row.changeHandler {
                result[row.id] = handler
            }
        }
    }

    /// Current validation errors of all rows, keyed by row id. Valid rows and
    /// rows without a rule are absent. Use for submit-time checks, e.g.
    /// `guard descriptor.validationErrors(store: store).isEmpty else { ... }`.
    public func validationErrors(store: FormStore) -> [String: String] {
        sections.flatMap(\.rows).reduce(into: [:]) { result, row in
            if let error = row.validationError(store: store) {
                result[row.id] = error
            }
        }
    }
}

public extension Forma {

    /// Result builder assembling the sections of a ``FormDescriptor``.
    /// Supports `if`, `if/else` and `for`.
    @resultBuilder
    enum DescriptorBuilder {
        public static func buildBlock(_ components: [Section]...) -> [Section] {
            components.flatMap { $0 }
        }

        public static func buildExpression(_ expression: Section) -> [Section] {
            [expression]
        }

        public static func buildExpression(_ expression: [Section]) -> [Section] {
            expression
        }

        public static func buildOptional(_ component: [Section]?) -> [Section] {
            component ?? []
        }

        public static func buildEither(first component: [Section]) -> [Section] {
            component
        }

        public static func buildEither(second component: [Section]) -> [Section] {
            component
        }

        public static func buildArray(_ components: [[Section]]) -> [Section] {
            components.flatMap { $0 }
        }
    }
}
