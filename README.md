# DentProof

A free, single-purpose iOS app that lets a solo detailer document a vehicle's
**pre-existing condition** — mark damage on a car diagram, attach photos, capture
the customer's signature, and generate a branded PDF in under 60 seconds.

Fully on-device. No backend, no accounts, no cloud. *"Data not collected."*

---

## Requirements

- **Xcode 15.3+** (iOS 17 SDK)
- **iOS 17.0+** target device or simulator
- [**XcodeGen**](https://github.com/yonaskolb/XcodeGen) to generate the project

## Generate & open

This repo ships source + a declarative `project.yml` (no checked-in `.xcodeproj`,
so there are no merge conflicts). Generate the project once:

```bash
brew install xcodegen      # if you don't have it
cd DentProof
xcodegen generate          # creates DentProof.xcodeproj
open DentProof.xcodeproj
```

Then in Xcode:

1. Select the **DentProof** target → **Signing & Capabilities** → choose your Team
   (or set `DEVELOPMENT_TEAM` in `project.yml` and re-run `xcodegen`).
2. Build & run on a device or simulator.

### StoreKit testing (paywall)

To exercise the paywall without App Store Connect:

1. Edit the **DentProof** scheme → **Run → Options → StoreKit Configuration** →
   select `DentProof.storekit`.
2. Run. The Free/Pro flows, watermark removal, and photo caps will all work
   against the local config. Product IDs:
   `com.dentproof.pro.monthly`, `com.dentproof.pro.yearly`.

For production, create the matching auto-renewable subscription group in App
Store Connect using those same product IDs.

---

## Architecture

| Layer | Tech |
|---|---|
| UI | SwiftUI (light + dark, ACME "warm paper" design system) |
| Persistence | SwiftData (local only) |
| Photos | `PhotosPicker` + `UIImagePickerController`, compressed to ~1600px JPEG on disk |
| Markers | Tap / drag overlays with **normalized (0…1)** coordinates |
| Signature | PencilKit `PKCanvasView` → PNG on disk |
| PDF | `ImageRenderer` (diagram) → `UIGraphicsPDFRenderer` (US Letter layout) |
| Location | CoreLocation one-shot, When-In-Use, fully optional |
| Payments | StoreKit 2, single subscription group, entitlement mirrored to `BusinessProfile.isPro` |

Binary assets (photos, signatures, logo) live as files in Documents; the
SwiftData store keeps only relative paths. Marker positions are normalized so
the on-screen diagram and the PDF render line up exactly (`kDiagramAspect`
locks the same aspect ratio in both places).

### Source map

```
Sources/
  App/                 App entry, Info.plist
  DesignSystem/        ACME colors (light+dark), fonts, components
  Models/              SwiftData models + enums
  Services/            FileStorage, ImageCompression, Location, Notifications,
                       StoreManager, PDFReportGenerator, Camera/Share/Message
  Diagrams/            Vehicle silhouettes + numbered markers
  Features/
    Root/              Tab shell + inspection flow coordinator
    Today/ Jobs/ Report/ Alerts/      The four tabs
    NewInspection/ WalkAround/ Signature/   The create → mark → sign journey
    Settings/ Paywall/                Business profile + Pro
```

---

## Scope (v1)

In: document pre-existing condition → mark → photo → sign → PDF → share.

**Deliberately out of v1:** scheduling, invoicing, customer accounts, cloud
sync, teams, and before/after comparison. v1.1 adds a **Before/After Studio**
(Labs). Keeping the app to one job done fast is the entire product.

---

## Before you submit

- Replace the placeholder app icon in `Resources/Assets.xcassets/AppIcon.appiconset`
  with a 1024×1024 PNG.
- Set your `DEVELOPMENT_TEAM` and a real bundle ID if `com.dentproof.app` is taken.
- Confirm the Info.plist usage strings read the way you want (camera, photos, location).
- App Store privacy label: **Data not collected.**
