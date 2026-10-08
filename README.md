# Forma

A generic, flexible **form builder for SwiftUI** — forms are described as
**declarative data** (typed rows with string ids, grouped into sections), rendered by a
single view, with all values owned by an observable store you can read, snapshot, validate,
and persist from one place.

Built with the same care for modern SwiftUI practice: native `Form` rendering, stable
identity, no force-unwraps, fully unit-tested.

- ✅ Text, toggle, picker, and button rows
- ✅ Sections with header/footer
- ✅ Conditional visibility (`hidden` rules — no dependency tags needed)
- ✅ Typed `onChange` callbacks
- ✅ Validation rules with inline error display
- ✅ `UserDefaults` persistence helpers
- ✅ Custom rows via a one-method protocol
- ✅ iOS 15+, zero dependencies, Swift 5.9+

---

## Table of contents

- [Features](#features)
- [Installation](#installation)
- [Quick start](#quick-start)
- [Concepts](#concepts)
- [Rows](#rows)
- [Conditional visibility](#conditional-visibility)
- [Reacting to changes](#reacting-to-changes)
- [Validation](#validation)
- [Persistence](#persistence)
- [Custom rows](#custom-rows)
- [Reading values](#reading-values)
- [Presenting from UIKit](#presenting-from-uikit)
- [Requirements](#requirements)
- [Design decisions](#design-decisions)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License](#license)

---

## Features

- **🧩 Declarative Syntax:** Build forms natively using SwiftUI-like Result Builders.
- **⚡ Fully Generic & Flexible:** Works with any data model or custom input component.
- **✅ Real-time Validation:** Built-in and custom field-level validation rules with live state tracking.
- **🧠 State Management:** Automated tracking of "touched" fields, error visibility, and global form validity.
- **🎨 UI Agnostic:** Mix and match native SwiftUI views or custom styled form controls seamlessly.

---

## Installation

### Swift Package Manager

```
https://github.com/marsal-silveira/Forma.git
```

In Xcode: **File → Add Package Dependencies…**, paste the URL, add the `Forma`
product to your target.

Or in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/marsal-silveira/Forma.git", from: "0.1.0")
],
targets: [
    .target(name: "MyApp", dependencies: [
        .product(name: "Forma", package: "Forma")
    ])
]
```

## Quick start

```swift
import Forma
import SwiftUI

struct SettingsView: View {
    @StateObject private var store = FormStore(initialValues: [
        "qualityRow": Quality.automatic
    ])
    private let descriptor: FormDescriptor

    init() {
        let descriptor = FormDescriptor {
            Forma.Section(header: "Video") {
                Forma.TextRow(
                    id: "videoIdRow",
                    title: "Video ID",
                    placeholder: "ID or CDN URL"
                )
                Forma.PickerRow(
                    id: "qualityRow",
                    title: "Quality limit",
                    options: Quality.allCases
                )
                Forma.ToggleRow(id: "mutedRow", title: "Start muted")
            }
            Forma.Section(id: "actions") {
                Forma.ButtonRow(id: "playRow", title: "Play") { store in
                    let videoId: String = store.value(for: "videoIdRow", default: "")
                    print("Playing \(videoId)")
                }
            }
        }
        self.descriptor = descriptor
    }

    var body: some View {
        FormView(descriptor: descriptor, store: store)
            .navigationTitle("Settings")
    }
}

enum Quality: String, CaseIterable, CustomStringConvertible {
    case automatic, low, high
    var description: String { rawValue.capitalized }
}
```

That's a complete, working form — two-way bound, grouped, native-looking.

## Concepts

| Type | Role |
|---|---|
| `FormDescriptor` | The form, described as data. Built once with result builders; held by your view. |
| `FormStore` | `ObservableObject` that owns every value, keyed by row `id`. The single source of truth. |
| `FormView` | Renders a descriptor as a native grouped SwiftUI `Form`. |
| `Forma` | Caseless enum namespacing every row/section type (`Forma.TextRow`, …), so nothing collides with SwiftUI's or third-party types. |
| `Forma.Row` | Protocol your own rows conform to. |

The flow: **descriptor** (what the form is) → **store** (what the values are) →
**FormView** (rendering). Rows never own their values — they read and write through the
store, so the whole form state is inspectable at any moment.

## Rows

Every row takes a stable string `id` that doubles as its storage key and its `ForEach`
identity.

### `Forma.TextRow`

```swift
Forma.TextRow(id: "videoIdRow", title: "Video ID", placeholder: "ID or CDN URL")
```

Bound to a `String` value.

### `Forma.ToggleRow`

```swift
Forma.ToggleRow(id: "mutedRow", title: "Start muted")
```

Bound to a `Bool` value (defaults to `false` until first write).

### `Forma.PickerRow`

```swift
Forma.PickerRow(
    id: "qualityRow",
    title: "Quality limit",
    options: Quality.allCases                  // any Hashable
)
```

Single selection over `[Value: Hashable]`, rendered as a `Menu` showing the current
selection. On iOS 16+, it can be migrated to `.pickerStyle(.navigationLink)`.
Display strings default to `String(describing:)`;
pass `titleForOption:` to customize:

```swift
Forma.PickerRow(id: "envRow", title: "Backend", options: Backend.allCases) { option in
    option.displayName
}
```

### `Forma.ButtonRow`

```swift
Forma.ButtonRow(id: "resetRow", title: "Reset", role: .destructive) { store in
    store.resetValues()
}
```

The action receives the store, so handlers can read or mutate other rows.

### Sections

```swift
Forma.Section(id: "video", header: "Video", footer: "Applied on next play") {
    // rows
}
```

`id` is optional — it defaults to the header text. The builders support `if`, `if/else`,
and `for`, so sections and rows can be composed conditionally:

```swift
Forma.Section(header: "Audio") {
    for language in languages {
        Forma.ToggleRow(id: "audio-\(language.id)", title: language.name)
    }
    if showsAdvanced {
        Forma.ToggleRow(id: "dolbyRow", title: "Dolby")
    }
}
```

## Conditional visibility

No dependency tags are needed: the store republishes on every write, so conditions
re-evaluate automatically for any value they read.

```swift
Forma.ToggleRow(id: "advancedRow", title: "Advanced")
Forma.TextRow(id: "videoIdRow", title: "Video ID")
    .hidden { store in !store.value(for: "advancedRow", default: false) }
```

Also works on whole sections:

```swift
Forma.Section(id: "actions") {
    Forma.ButtonRow(id: "resetRow", title: "Reset", role: .destructive) { $0.resetValues() }
}
.hidden { store in store.values.isEmpty }
```

## Reacting to changes

Per-row, **typed**:

```swift
Forma.PickerRow(id: "qualityRow", title: "Quality", options: Quality.allCases)
    .onChange { (quality: Quality?) in
        print("quality =", quality as Any)
    }
```

Fires on UI edits *and* programmatic `store.setValue`. A store-level hook supports
cross-cutting reactions:

```swift
store.onValueChange = { id, value in
    if id == "environmentRow" { reloadPlayer() }
}
```

`resetValues()` intentionally does **not** fire per-row `onChange` handlers (views
re-render from the emptied store); it fires the store's `onReset` hook instead.

## Validation

Attach a rule per row; return an error message when invalid, `nil` when valid:

```swift
Forma.TextRow(id: "videoIdRow", title: "Video ID")
    .validation { value in                      // typed: String?
        guard let value, !value.isEmpty else { return nil }   // optional row
        return value.count >= 3 ? nil : "ID must have at least 3 characters"
    }
```

Errors are displayed live as a red caption under the failing row. For submit-time checks:

```swift
let errors = descriptor.validationErrors(store: store)   // [rowId: message]
guard errors.isEmpty else { return }
```

> **Chain order matters**: apply typed modifiers (`onChange`, `validation`) **before**
> untyped ones (`hidden`) — once a chain returns `AnyRow`, only the untyped overloads
> remain. `.validation { (v: String?) in ... }.hidden { ... }` ✅

## Persistence

`UserDefaults`-backed save/restore of the whole store:

```swift
let persistence = FormStorePersistence(key: "PlaygroundSettings")

let store = FormStore(initialValues: persistence.load())  // restore
persistence.attach(to: store)                             // auto-save on every change

store.resetValues()   // also clears persisted values
```

- Only **property-list-safe** values are saved (`String`, `Bool`, `Int`, `Double`,
  `Date`, `Data`, and collections of those). Custom types are skipped — map them
  manually if you need them persisted.
- `attach(to:)` **chains** any existing `onValueChange` / `onReset` hooks instead of
  replacing them.
- `UserDefaults` is injectable for tests: `FormStorePersistence(key:userDefaults:)`.

## Custom rows

Conform to `Forma.Row` — one `id`, one method — and your row drops into any section,
with `.hidden`, `.onChange`, and `.validation` available for free:

```swift
struct StepperRow: Forma.Row {
    let id: String
    let title: LocalizedStringKey

    func content(store: FormStore) -> AnyView {
        AnyView(
            Stepper(title, value: store.binding(for: id, default: 0), in: 0...60)
        )
    }
}
```

```swift
Forma.Section(header: "Playback") {
    StepperRow(id: "startAtRow", title: "Start at (s)")
        .hidden { store in store.value(for: "liveRow", default: false) }
}
```

## Reading values

```swift
let videoId: String?  = store.value(for: "videoIdRow")
let muted: Bool       = store.value(for: "mutedRow", default: false)
let snapshot: [String: Any] = store.values

store.setValue("abc123", for: "videoIdRow")         // programmatic write
store.setValue(nil as String?, for: "videoIdRow")   // clear
store.resetValues()                                  // clear everything
```

## Presenting from UIKit

```swift
import UIKit
import SwiftUI
import Forma

let host = UIHostingController(
    rootView: NavigationStack { SettingsView() }   // or NavigationView on iOS 15
)
navigationController?.pushViewController(host, animated: true)
```

## Requirements

- iOS 15+ (iOS 16+ recommended for future `Picker` navigation-link rendering)
- Swift 5.9+, Xcode 15+
- Zero external dependencies

## Design decisions

- **`ObservableObject`, not `@Observable`** — the package supports iOS 15, and
  `@Observable` requires iOS 17. Migration is mechanical once the floor rises.
- **Descriptor as data, store as state** — descriptors are built once (cheap value
  types), never rebuilt per body evaluation. All mutations flow through the store.
- **Stable identity everywhere** — `ForEach` keys come from row/section string ids,
  never indices, so edits animate correctly and row state is preserved.
- **Type erasure at the boundary** — rows erase to `AnyRow` once at descriptor-build
    time. Per-row `AnyView` cost is
  negligible at form scale.
- **`Forma` namespace** — groups row and section types without colliding with
    SwiftUI or third-party types in the same target.

## Roadmap

- [ ] `@Observable` store when the iOS floor reaches 17
- [ ] `.pickerStyle(.navigationLink)` push selector (iOS 16+)
- [ ] Date/time rows (`DatePicker` wrappers)
- [ ] Multi-select rows
- [ ] Reusable validation rule library
- [ ] tvOS support

## Contributing

Issues and PRs are welcome. Please:

1. Keep the public API source-compatible within a minor version.
2. Add tests for behavior changes (Swift Testing — no Quick/Nimble).
3. Run `swiftlint lint --quiet Sources Tests` before opening a PR.

## License

MIT — see [LICENSE](LICENSE).