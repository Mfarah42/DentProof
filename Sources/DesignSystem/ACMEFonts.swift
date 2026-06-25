import SwiftUI

extension Font {
    /// Editorial serif (system "New York") — used for titles only.
    static let acmeTitle   = Font.system(size: 26, weight: .regular, design: .serif)
    static let acmeSection = Font.system(size: 22, weight: .regular, design: .serif)

    /// Functional SF text.
    static let acmeBody    = Font.system(size: 13, weight: .regular)
    static let acmeBodyMed = Font.system(size: 14, weight: .medium)
    static let acmeMeta    = Font.system(size: 11, weight: .regular)
    static let acmeLabel   = Font.system(size: 12, weight: .medium)
}

extension Text {
    /// Tiny uppercase context/meta row used at the top of every briefing.
    func acmeMetaRow() -> some View {
        self
            .font(.acmeMeta)
            .tracking(1.2)
            .textCase(.uppercase)
            .foregroundStyle(Color.inkSecondary)
    }
}
