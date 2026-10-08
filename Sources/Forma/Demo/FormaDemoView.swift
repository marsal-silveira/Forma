import SwiftUI

/// Standalone demo of the form builder, replicating a slice of the
/// Playground-iOS settings form (Video section) plus a live value dump.
///
/// Deliberately not wired into the Playground navigation yet — present it
/// ad hoc (e.g. from a debug entry point) to try the component.
public struct FormaDemoView: View {
    private let persistence: FormStorePersistence
    @StateObject private var store: FormStore
    private let descriptor: FormDescriptor

    public init() {
        // Restore persisted values, then auto-save on every change.
        let persistence = FormStorePersistence(key: "FormaDemo")
        let store = FormStore(initialValues: persistence.load())
        persistence.attach(to: store)
        self.persistence = persistence
        self._store = StateObject(wrappedValue: store)

        // Mirrors the Playground's "videoAdvanced" section switch: rows stay
        // hidden until the toggle is on. No dependency tags needed — conditions
        // re-evaluate on every store change.
        let videoSection = Forma.Section(id: "video", header: "Video") {
            Forma.ToggleRow(id: "advancedRow", title: "Advanced")
                .onChange { (advanced: Bool?) in
                    print("[Demo] advanced =", advanced ?? false)
                }
            Forma.TextRow(id: "videoId", title: "Video ID", placeholder: "ID or CDN URL")
                // Typed modifiers first: once the chain reaches AnyRow,
                // only the untyped overloads remain.
                .validation { value in
                    // Empty is fine (row is optional); too short is not.
                    guard let value, !value.isEmpty else { return nil }
                    return value.count >= 3 ? nil : "ID must have at least 3 characters"
                }
                .hidden { store in !store.value(for: "advancedRow", default: false) }
            Forma.ToggleRow(id: "restrictedRow", title: "Allow restricted content")
                .hidden { store in !store.value(for: "advancedRow", default: false) }
            Forma.PickerRow(id: "qualityRow", title: "Quality limit", options: VideoQuality.demoValues)
                .onChange { (quality: VideoQuality?) in
                    print("[Demo] quality =", quality as Any)
                }
        }

        // Section-level hidden rule: appears only once something is set.
        let actionsSection = Forma.Section(id: "actions") {
            Forma.ButtonRow(id: "resetRow", title: "Reset", role: .destructive) { store in
                store.resetValues()   // also clears persisted values via attach
            }
        }
        .hidden { store in store.values.isEmpty }

        let stateSection = Forma.Section(id: "state", header: "Current values") {
            ValuesDumpRow(id: "valuesDumpRow")
        }

        descriptor = FormDescriptor {
            videoSection
            actionsSection
            stateSection
        }
    }

    public var body: some View {
        FormView(descriptor: descriptor, store: store)
            .navigationTitle("Form Builder")
    }
}

// MARK: - Demo option type

/// Mirrors the Playground's quality options with a `CustomStringConvertible`
/// description, the same shape `VideoQuality` has there.
enum VideoQuality: String, CaseIterable, CustomStringConvertible {
    case automatic
    case low
    case high

    var description: String { rawValue.capitalized }

    static var demoValues: [VideoQuality] { allCases }
}

// MARK: - Custom row example

/// Custom row proving the extension point: renders the store's live snapshot.
/// The Playground's "Custom Form Cells" equivalent for the SwiftUI builder.
struct ValuesDumpRow: Forma.Row {
    let id: String

    func content(store: FormStore) -> AnyView {
        AnyView(ContentView(store: store))
    }

    struct ContentView: View {
        @ObservedObject var store: FormStore

        var body: some View {
            if store.values.isEmpty {
                Text("No values yet")
                    .foregroundColor(.secondary)
            } else {
                ForEach(store.values.keys.sorted(), id: \.self) { key in
                    HStack {
                        Text(key)
                        Spacer()
                        Text(String(describing: store.values[key] ?? ""))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

struct FormaDemoViewPreview: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FormaDemoView()
        }
    }
}
