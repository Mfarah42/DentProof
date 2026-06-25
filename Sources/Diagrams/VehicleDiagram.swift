import SwiftUI

/// Proportions that shape each top-down silhouette. All values are fractions of
/// the drawing rect (front of the car points up).
private struct CarProportions {
    var bodyInsetX: CGFloat       // side margin of the body
    var bodyTop: CGFloat          // nose
    var bodyBottom: CGFloat       // tail
    var noseRadius: CGFloat
    var tailRadius: CGFloat
    var cabinTop: CGFloat         // where the greenhouse starts
    var cabinBottom: CGFloat      // where it ends
    var cabinInsetX: CGFloat      // greenhouse is narrower than body
    var hasBed: Bool              // truck bed
    var bedTop: CGFloat

    static func forStyle(_ style: BodyStyle) -> CarProportions {
        switch style {
        case .sedan:
            return .init(bodyInsetX: 0.20, bodyTop: 0.05, bodyBottom: 0.96,
                         noseRadius: 0.10, tailRadius: 0.09,
                         cabinTop: 0.34, cabinBottom: 0.74, cabinInsetX: 0.27,
                         hasBed: false, bedTop: 0)
        case .coupe:
            return .init(bodyInsetX: 0.21, bodyTop: 0.07, bodyBottom: 0.93,
                         noseRadius: 0.12, tailRadius: 0.11,
                         cabinTop: 0.40, cabinBottom: 0.70, cabinInsetX: 0.28,
                         hasBed: false, bedTop: 0)
        case .suv:
            return .init(bodyInsetX: 0.19, bodyTop: 0.05, bodyBottom: 0.97,
                         noseRadius: 0.08, tailRadius: 0.06,
                         cabinTop: 0.26, cabinBottom: 0.82, cabinInsetX: 0.255,
                         hasBed: false, bedTop: 0)
        case .van:
            return .init(bodyInsetX: 0.18, bodyTop: 0.04, bodyBottom: 0.98,
                         noseRadius: 0.07, tailRadius: 0.05,
                         cabinTop: 0.20, cabinBottom: 0.90, cabinInsetX: 0.24,
                         hasBed: false, bedTop: 0)
        case .truck:
            return .init(bodyInsetX: 0.19, bodyTop: 0.05, bodyBottom: 0.97,
                         noseRadius: 0.08, tailRadius: 0.05,
                         cabinTop: 0.20, cabinBottom: 0.46, cabinInsetX: 0.255,
                         hasBed: true, bedTop: 0.52)
        case .other:
            return .init(bodyInsetX: 0.20, bodyTop: 0.05, bodyBottom: 0.96,
                         noseRadius: 0.10, tailRadius: 0.09,
                         cabinTop: 0.34, cabinBottom: 0.74, cabinInsetX: 0.27,
                         hasBed: false, bedTop: 0)
        }
    }
}

/// Outer body outline (filled).
private struct CarBodyShape: Shape {
    let style: BodyStyle
    func path(in rect: CGRect) -> Path {
        let p = CarProportions.forStyle(style)
        func x(_ f: CGFloat) -> CGFloat { rect.minX + rect.width * f }
        func y(_ f: CGFloat) -> CGFloat { rect.minY + rect.height * f }

        let bodyRect = CGRect(
            x: x(p.bodyInsetX), y: y(p.bodyTop),
            width: x(1 - p.bodyInsetX) - x(p.bodyInsetX),
            height: y(p.bodyBottom) - y(p.bodyTop))

        // Asymmetric corner radii (rounder nose than tail) via two rounded rects
        // blended — simplest robust approach is a single rounded rect using the
        // average, which still reads cleanly at diagram scale.
        let r = (p.noseRadius + p.tailRadius) / 2 * rect.width
        return Path(roundedRect: bodyRect, cornerRadius: r)
    }
}

/// Interior detail lines: greenhouse/cabin, plus a truck bed when present.
private struct CarDetailShape: Shape {
    let style: BodyStyle
    func path(in rect: CGRect) -> Path {
        let p = CarProportions.forStyle(style)
        func x(_ f: CGFloat) -> CGFloat { rect.minX + rect.width * f }
        func y(_ f: CGFloat) -> CGFloat { rect.minY + rect.height * f }

        var path = Path()

        // Cabin / greenhouse
        let cabinRect = CGRect(
            x: x(p.cabinInsetX), y: y(p.cabinTop),
            width: x(1 - p.cabinInsetX) - x(p.cabinInsetX),
            height: y(p.cabinBottom) - y(p.cabinTop))
        path.addRoundedRect(in: cabinRect, cornerSize: CGSize(width: rect.width * 0.06,
                                                              height: rect.width * 0.06))

        // Centerline hint (hood/roof split) above the cabin
        path.move(to: CGPoint(x: rect.midX, y: y(p.bodyTop + 0.04)))
        path.addLine(to: CGPoint(x: rect.midX, y: y(p.cabinTop - 0.02)))

        if p.hasBed {
            let bedRect = CGRect(
                x: x(p.bodyInsetX + 0.02), y: y(p.bedTop),
                width: x(1 - p.bodyInsetX - 0.02) - x(p.bodyInsetX + 0.02),
                height: y(p.bodyBottom - 0.03) - y(p.bedTop))
            path.addRoundedRect(in: bedRect, cornerSize: CGSize(width: rect.width * 0.03,
                                                               height: rect.width * 0.03))
        }
        return path
    }
}

/// Shared width:height ratio for the diagram box. Both the on-screen card and
/// the PDF render use this exact ratio so a marker's normalized (x,y) lands on
/// the same spot of the car in both places.
let kDiagramAspect: CGFloat = 0.6

/// Top-down vehicle silhouette used both on screen and in the PDF.
/// Pure drawing — no markers. Fills its frame (the proportions assume a frame
/// of `kDiagramAspect`), so callers must lock that aspect ratio.
struct VehicleDiagramView: View {
    let style: BodyStyle

    var body: some View {
        ZStack {
            CarBodyShape(style: style)
                .fill(Color.peach.opacity(0.55))
            CarBodyShape(style: style)
                .stroke(Color.clayDeep.opacity(0.55), lineWidth: 1.5)
            CarDetailShape(style: style)
                .stroke(Color.clayDeep.opacity(0.35), style: StrokeStyle(lineWidth: 1, lineJoin: .round))
        }
    }
}

#Preview {
    HStack {
        ForEach(BodyStyle.allCases) { style in
            VStack {
                VehicleDiagramView(style: style)
                    .frame(width: 70, height: 130)
                Text(style.displayName).font(.caption2)
            }
        }
    }
    .padding()
    .background(Color.paper)
}
