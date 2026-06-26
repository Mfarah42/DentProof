# DentProof

**Document a vehicle's pre-existing condition in under 60 seconds.**

DentProof is a native iOS app (SwiftUI + SwiftData) that lets a solo auto
detailer or valet protect themselves from false damage claims: mark existing
damage on a car diagram, attach photos, capture the customer's signature, and
generate a branded PDF report — all on-device, with no backend, no accounts,
and no cloud.

> Built with SwiftUI, SwiftData, PencilKit, CoreLocation, StoreKit 2, and
> PDF generation via `ImageRenderer` + `UIGraphicsPDFRenderer`. 100% on-device —
> *"Data not collected."*

---

## What it does

The core journey is **create → mark → photo → sign → PDF → share**:

1. **Start an inspection** — capture the vehicle and customer details.
2. **Walk-around marking** — tap a car diagram to drop numbered markers exactly
   where existing damage is, and drag to reposition.
3. **Photo evidence** — attach compressed photos to each marker.
4. **Customer signature** — the customer signs on-screen to acknowledge the
   recorded condition.
5. **Branded PDF** — generate a clean, US-Letter report (diagram + markers +
   photos + signature + business info) and share it via Messages, email, or any
   share target — in under a minute.

The app is organized into four tabs — **Today**, **Jobs**, **Reports**, and
**Alerts** — with a Settings area for the detailer's business profile and Pro
subscription.

---

## Technical highlights

These are the parts worth talking through:

- **Pixel-perfect markers via normalized coordinates.** Damage markers are stored
  as normalized `(0…1)` positions rather than screen pixels. A shared aspect-ratio
  constant (`kDiagramAspect`) locks the on-screen diagram and the rendered PDF to
  the same geometry, so a marker placed on the phone lands in the exact same spot
  on the printed report — regardless of device size.
- **On-device PDF pipeline.** The diagram is rasterized with SwiftUI's
  `ImageRenderer`, then composed into a multi-section US-Letter document with
  `UIGraphicsPDFRenderer` — diagram, photo grid, signature, and business header,
  all generated locally.
- **Signature capture.** PencilKit's `PKCanvasView` captures the signature and
  exports it to a PNG stored on disk.
- **File-backed persistence.** Binary assets (photos, signatures, logo) live as
  files in the Documents directory; the SwiftData store keeps only relative
  paths. Photos are compressed to ~1600px JPEG to keep storage lean.
- **StoreKit 2 paywall.** A single auto-renewable subscription group gates Pro
  features (watermark removal, higher photo caps). The entitlement is mirrored to
  `BusinessProfile.isPro`, and a bundled `.storekit` config allows full paywall
  testing without App Store Connect.
- **Privacy by design.** No network calls, no analytics, no accounts. CoreLocation
  is a one-shot, When-In-Use, fully optional convenience. App Store privacy label:
  **Data not collected.**

---

## Architecture

| Layer | Tech |
|---|---|
| UI | SwiftUI (light + dark, "warm paper" design system) |
| Persistence | SwiftData (local only) |
| Photos | `PhotosPicker` + `UIImagePickerController`, compressed to ~1600px JPEG |
| Markers | Tap / drag overlays with **normalized (0…1)** coordinates |
| Signature | PencilKit `PKCanvasView` → PNG on disk |
| PDF | `ImageRenderer` (diagram) → `UIGraphicsPDFRenderer` (US Letter) |
| Location | CoreLocation one-shot, When-In-Use, optional |
| Payments | StoreKit 2, single subscription group, entitlement → `BusinessProfile.isPro` |

### Source map

```
Sources/
  App/                 App entry, Info.plist
  DesignSystem/        Colors (light+dark), fonts, components
  Models/              SwiftData models + enums
  Services/            FileStorage, ImageCompression, Location, Notifications,
                       StoreManager, PDFReportGenerator, Camera/Share/Message
  Diagrams/            Vehicle silhouettes + numbered markers
  Features/
    Root/              Tab shell + inspection flow coordinator
    Today/ Jobs/ Report/ Alerts/        The four tabs
    NewInspection/ WalkAround/ Signature/   The create → mark → sign journey
    Settings/ Paywall/                  Business profile + Pro
```

---

## Build & run

This repo ships source plus a declarative `project.yml` — **no checked-in
`.xcodeproj`**, so there are no merge conflicts. Generate the project once with
[XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
brew install xcodegen      # if you don't have it
cd DentProof
xcodegen generate          # creates DentProof.xcodeproj
open DentProof.xcodeproj
```

Then in Xcode select the **DentProof** target → **Signing & Capabilities** →
choose your Team, then build & run.

**Requirements:** Xcode 15.3+ (iOS 17 SDK), iOS 17.0+ device or simulator.

### StoreKit testing (paywall)

Edit the **DentProof** scheme → **Run → Options → StoreKit Configuration** →
select `DentProof.storekit`. The Free/Pro flows, watermark removal, and photo
caps run against the local config. Product IDs:
`com.dentproof.pro.monthly`, `com.dentproof.pro.yearly`.

---

## Scope (v1)

**In:** document pre-existing condition → mark → photo → sign → PDF → share.

**Deliberately out of v1:** scheduling, invoicing, customer accounts, cloud
sync, and teams. Keeping the app to one job done fast is the entire product.
v1.1 adds a **Before/After Studio** (Labs).

---

*DentProof is a single-purpose tool: fast, private, and built to do one job well.*
