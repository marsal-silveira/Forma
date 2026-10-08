import SwiftUI

/// Renders a ``FormDescriptor`` as a native grouped SwiftUI `Form`.
///
/// Section and row identity come from their stable string ids (never indices),
/// so edits animate correctly and row state is preserved. The store is observed
/// here and by each row view; with `ObservableObject` any write invalidates
/// observing rows — acceptable at form scale, and the migration to
/// `@Observable` (iOS 17+) restores per-property granularity later.
public struct FormView: View {
    private let descriptor: FormDescriptor
    @ObservedObject private var store: FormStore

    public init(descriptor: FormDescriptor, store: FormStore) {
        self.descriptor = descriptor
        self.store = store
        store.replaceRowCallbacks(descriptor.rowCallbacks)
    }

    public var body: some View {
        Form {
            ForEach(descriptor.sections) { section in
                if !section.isHidden(store: store) {
                    Section {
                        ForEach(section.rows) { row in
                            if !row.isHidden(store: store) {
                                VStack(alignment: .leading) {
                                    row.content(store: store)
                                    if let error = row.validationError(store: store) {
                                        Text(error)
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                        }
                    } header: {
                        if let header = section.header {
                            Text(header)
                        }
                    } footer: {
                        if let footer = section.footer {
                            Text(footer)
                        }
                    }
                }
            }
        }
    }
}
