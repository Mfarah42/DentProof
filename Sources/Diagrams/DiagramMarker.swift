import SwiftUI

/// A numbered clay marker. Used on the walk-around screen and in the PDF render.
struct DiagramMarker: View {
    let number: Int
    var diameter: CGFloat = 30
    var isSelected: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.clay)
                .overlay(Circle().strokeBorder(Color.onClay, lineWidth: 2))
                .shadow(color: Color.black.opacity(0.18), radius: 3, y: 1)
            Text("\(number)")
                .font(.system(size: diameter * 0.44, weight: .bold))
                .foregroundStyle(Color.onClay)
        }
        .frame(width: diameter, height: diameter)
        .scaleEffect(isSelected ? 1.15 : 1)
    }
}

/// Composes the silhouette with a static set of markers at normalized
/// positions. This exact view is what `ImageRenderer` rasterizes for the PDF,
/// so on-screen and printed diagrams always match.
struct DiagramWithMarkers: View {
    let style: BodyStyle
    /// (index, x, y) with x,y normalized 0…1.
    let markers: [(index: Int, x: Double, y: Double)]
    var markerDiameter: CGFloat = 28

    var body: some View {
        GeometryReader { geo in
            ZStack {
                VehicleDiagramView(style: style)
                ForEach(markers, id: \.index) { m in
                    DiagramMarker(number: m.index, diameter: markerDiameter)
                        .position(x: geo.size.width * m.x,
                                  y: geo.size.height * m.y)
                }
            }
        }
    }
}
