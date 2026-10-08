import SwiftUI

public extension Forma {

    /// A group of rows with an optional header and footer, rendered as a native
    /// grouped `Form` section.
    struct Section: Identifiable {
        public let id: String
        public let header: LocalizedStringKey?
        public let footer: LocalizedStringKey?
        public let rows: [AnyRow]

        /// Evaluated on every store change; the whole section is hidden while
        /// it returns `true`. Set via `.hidden(_:)`.
        public private(set) var hiddenCondition: ((FormStore) -> Bool)?

        /// - Parameters:
        ///   - id: Stable identity. Defaults to the header text when present,
        ///     which keeps call sites short while remaining unique per form.
        ///   - rows: Row descriptors built with ``RowsBuilder``.
        public init(
            id: String? = nil,
            header: LocalizedStringKey? = nil,
            footer: LocalizedStringKey? = nil,
            @RowsBuilder rows: () -> [AnyRow] = { [] }
        ) {
            self.id = id ?? header.map { String(describing: $0) } ?? UUID().uuidString
            self.header = header
            self.footer = footer
            self.rows = rows()
        }

        public func isHidden(store: FormStore) -> Bool {
            hiddenCondition?(store) ?? false
        }

        /// Hides the section while `condition` returns `true`. Evaluated
        /// whenever any value in the store changes.
        public func hidden(_ condition: @escaping (FormStore) -> Bool) -> Section {
            var copy = self
            copy.hiddenCondition = condition
            return copy
        }
    }
}

public extension Forma {

    /// Result builder assembling the rows of a ``Section``. Supports `if`,
    /// `if/else` and `for` so sections can be composed conditionally.
    @resultBuilder
    enum RowsBuilder {
        public static func buildBlock(_ components: [AnyRow]...) -> [AnyRow] {
            components.flatMap { $0 }
        }

        public static func buildExpression<R: Row>(_ expression: R) -> [AnyRow] {
            [expression.eraseToAnyRow()]
        }

        public static func buildExpression(_ expression: AnyRow) -> [AnyRow] {
            [expression]
        }

        public static func buildOptional(_ component: [AnyRow]?) -> [AnyRow] {
            component ?? []
        }

        public static func buildEither(first component: [AnyRow]) -> [AnyRow] {
            component
        }

        public static func buildEither(second component: [AnyRow]) -> [AnyRow] {
            component
        }

        public static func buildArray(_ components: [[AnyRow]]) -> [AnyRow] {
            components.flatMap { $0 }
        }
    }
}
