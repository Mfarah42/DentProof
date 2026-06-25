import SwiftUI

// MARK: - Card

/// Cream surface with a hairline border, used for every grouped module.
struct ACMECard<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cream)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.hairline, lineWidth: 0.5)
            )
    }
}

// MARK: - Buttons

/// Primary clay capsule button.
struct ClayButton: View {
    let title: String
    var icon: String? = nil
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                }
                Text(title)
                    .font(.acmeBodyMed)
            }
            .foregroundStyle(Color.onClay)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.clayDeep)
            .clipShape(Capsule())
            .opacity(isEnabled ? 1 : 0.4)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

/// Transparent capsule with a hairline border.
struct SecondaryButton: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                }
                Text(title)
                    .font(.acmeBodyMed)
            }
            .foregroundStyle(Color.inkPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .overlay(Capsule().strokeBorder(Color.hairline, lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Icon tile

/// Peach circle with a clayDeep glyph — the warmth-carrying motif.
struct IconTile: View {
    let systemName: String
    var size: CGFloat = 28

    var body: some View {
        ZStack {
            Circle().fill(Color.peach)
            Image(systemName: systemName)
                .symbolRenderingMode(.monochrome)
                .font(.system(size: size * 0.46, weight: .semibold))
                .foregroundStyle(Color.clayDeep)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Briefing header

/// The shared layout pattern at the top of every screen:
/// meta row → serif title → one plain-English line.
struct BriefingHeader: View {
    let meta: String
    let title: String
    let line: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(meta).acmeMetaRow()
            Text(title)
                .font(.acmeTitle)
                .foregroundStyle(Color.inkPrimary)
            Text(line)
                .font(.acmeBody)
                .foregroundStyle(Color.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Section title

struct SectionTitle: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.acmeSection)
            .foregroundStyle(Color.inkPrimary)
    }
}

// MARK: - Background helper

/// Paper canvas applied to a whole screen.
struct PaperBackground: ViewModifier {
    func body(content: Content) -> some View {
        content.background(Color.paper.ignoresSafeArea())
    }
}

extension View {
    func paperBackground() -> some View { modifier(PaperBackground()) }
}
