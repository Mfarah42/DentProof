import SwiftUI
import SwiftData

struct NewInspectionView: View {
    @Environment(\.modelContext) private var context
    @Binding var path: NavigationPath
    let onCancel: () -> Void

    /// Created up front and inserted immediately so nothing is lost at the curb.
    @State private var inspection = Inspection()
    @State private var inserted = false

    var body: some View {
        @Bindable var inspection = inspection

        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                BriefingHeader(
                    meta: "NEW INSPECTION",
                    title: "Who and what",
                    line: "Just the basics. You can mark the car next.")
                    .padding(.top, 8)

                ACMECard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Customer").acmeMetaRow()
                        DPTextField(title: "Name", text: $inspection.customerName)
                        DPTextField(title: "Phone (optional)",
                                    text: Binding($inspection.customerPhone, default: ""),
                                    keyboard: .phonePad)
                    }
                }

                ACMECard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Vehicle").acmeMetaRow()
                        DPTextField(title: "Make", text: $inspection.vehicleMake)
                        DPTextField(title: "Model", text: $inspection.vehicleModel)
                        DPTextField(title: "Color", text: $inspection.vehicleColor)
                        DPTextField(title: "Plate (optional)",
                                    text: Binding($inspection.vehiclePlate, default: ""),
                                    autocap: .characters)

                        Text("Body style").acmeMetaRow().padding(.top, 4)
                        BodyStylePicker(selection: $inspection.bodyStyle)
                    }
                }

                ClayButton(title: "Continue", icon: "arrow.right") {
                    save()
                    path.append(FlowRoute.walkAround(inspection))
                }

                Spacer(minLength: 30)
            }
            .padding(.horizontal, 20)
        }
        .paperBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    // Drop the empty draft if the user backs out without continuing.
                    if inserted { context.delete(inspection) }
                    onCancel()
                }
            }
        }
        .onAppear {
            guard !inserted else { return }
            context.insert(inspection)
            inserted = true
        }
    }

    private func save() {
        // Trim whitespace so empty-but-spaces fields read as empty.
        inspection.customerName = inspection.customerName.trimmingCharacters(in: .whitespaces)
        inspection.vehicleMake = inspection.vehicleMake.trimmingCharacters(in: .whitespaces)
        inspection.vehicleModel = inspection.vehicleModel.trimmingCharacters(in: .whitespaces)
        inspection.vehicleColor = inspection.vehicleColor.trimmingCharacters(in: .whitespaces)
        try? context.save()
    }
}

// MARK: - Field helpers

struct DPTextField: View {
    let title: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var autocap: TextInputAutocapitalization = .words

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            TextField(title, text: $text)
                .font(.acmeBodyMed)
                .keyboardType(keyboard)
                .textInputAutocapitalization(autocap)
                .autocorrectionDisabled()
                .padding(.vertical, 9)
                .padding(.horizontal, 12)
                .background(Color.paper)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color.hairline, lineWidth: 0.5))
        }
    }
}

struct BodyStylePicker: View {
    @Binding var selection: BodyStyle

    private let columns = [GridItem(.adaptive(minimum: 78), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(BodyStyle.allCases) { style in
                Button {
                    Haptics.light()
                    selection = style
                } label: {
                    Text(style.displayName)
                        .font(.acmeLabel)
                        .foregroundStyle(selection == style ? Color.onClay : Color.inkPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(selection == style ? Color.clayDeep : Color.paper)
                        .clipShape(Capsule())
                        .overlay(Capsule().strokeBorder(Color.hairline,
                                                        lineWidth: selection == style ? 0 : 0.5))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// Bridges an optional String binding to a non-optional one with a default.
extension Binding where Value == String {
    init(_ source: Binding<String?>, default defaultValue: String) {
        self.init(
            get: { source.wrappedValue ?? defaultValue },
            set: { source.wrappedValue = $0.isEmpty ? nil : $0 })
    }
}
