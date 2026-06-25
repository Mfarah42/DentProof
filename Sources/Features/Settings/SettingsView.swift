import SwiftUI
import SwiftData
import PhotosUI

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: StoreManager
    @Query private var profiles: [BusinessProfile]

    @State private var profile: BusinessProfile?
    @State private var logoItem: PhotosPickerItem?
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let profile {
                        let bindable = Bindable(profile)

                        proStatusCard

                        ACMECard {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Business").acmeMetaRow()
                                DPTextField(title: "Business name", text: bindable.name)
                                DPTextField(title: "Phone",
                                            text: Binding(bindable.phone, default: ""),
                                            keyboard: .phonePad)
                                DPTextField(title: "Email",
                                            text: Binding(bindable.email, default: ""),
                                            keyboard: .emailAddress, autocap: .never)
                            }
                        }

                        logoCard(profile)

                        ACMECard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Privacy").acmeMetaRow()
                                Text("DentProof keeps everything on this iPhone. No account, no cloud, no tracking. Your records never leave the device unless you share them yourself.")
                                    .font(.acmeBody)
                                    .foregroundStyle(Color.inkSecondary)
                            }
                        }
                    } else {
                        ProgressView().padding()
                    }
                }
                .padding(20)
            }
            .paperBackground()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { save(); dismiss() }.font(.acmeBodyMed)
                }
            }
            .onAppear(perform: ensureProfile)
            .onChange(of: logoItem) { _, item in loadLogo(item) }
            .onDisappear(perform: save)
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    // MARK: - Pro

    private var proStatusCard: some View {
        ACMECard {
            HStack(spacing: 12) {
                IconTile(systemName: store.isPro ? "checkmark.seal.fill" : "sparkles", size: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(store.isPro ? "DentProof Pro" : "Free plan")
                        .font(.acmeSection)
                        .foregroundStyle(Color.inkPrimary)
                    Text(store.isPro
                         ? "No watermark, your logo, unlimited photos."
                         : "Remove the watermark and add your brand.")
                        .font(.acmeMeta)
                        .foregroundStyle(Color.inkSecondary)
                }
                Spacer()
                if !store.isPro {
                    Button("Upgrade") { showPaywall = true }
                        .font(.acmeLabel)
                        .foregroundStyle(Color.onClay)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Capsule().fill(Color.clayDeep))
                }
            }
            if !store.isPro {
                VStack(spacing: 0) {
                    Divider().overlay(Color.hairline).padding(.vertical, 10)
                    Button("Restore purchases") { Task { await store.restore() } }
                        .font(.acmeMeta)
                        .foregroundStyle(Color.clayDeep)
                }
            }
        }
    }

    @ViewBuilder
    private func logoCard(_ profile: BusinessProfile) -> some View {
        ACMECard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Logo").acmeMetaRow()
                    Spacer()
                    if !store.isPro {
                        Label("Pro", systemImage: "lock.fill")
                            .font(.acmeMeta).foregroundStyle(Color.clayDeep)
                    }
                }
                HStack(spacing: 14) {
                    Group {
                        if let logo = FileStorage.image(atRelative: profile.logoPath) {
                            Image(uiImage: logo).resizable().scaledToFit()
                        } else {
                            Image(systemName: "photo").font(.system(size: 22))
                                .foregroundStyle(Color.inkSecondary)
                        }
                    }
                    .frame(width: 56, height: 56)
                    .background(Color.paper)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.hairline, lineWidth: 0.5))

                    if store.isPro {
                        PhotosPicker(selection: $logoItem, matching: .images) {
                            Text(profile.logoPath == nil ? "Add logo" : "Change")
                                .font(.acmeLabel).foregroundStyle(Color.clayDeep)
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .overlay(Capsule().strokeBorder(Color.clay.opacity(0.5), lineWidth: 0.5))
                        }
                        if profile.logoPath != nil {
                            Button("Remove") {
                                FileStorage.delete(relativePath: profile.logoPath)
                                profile.logoPath = nil
                                save()
                            }
                            .font(.acmeMeta).foregroundStyle(Color.inkSecondary)
                        }
                    } else {
                        Button("Upgrade to add your logo") { showPaywall = true }
                            .font(.acmeLabel).foregroundStyle(Color.clayDeep)
                    }
                }
            }
        }
    }

    // MARK: - Data

    private func ensureProfile() {
        if let existing = profiles.first {
            profile = existing
        } else {
            let p = BusinessProfile()
            context.insert(p)
            try? context.save()
            profile = p
        }
        // Keep cached Pro flag in sync whenever Settings opens.
        profile?.isPro = store.isPro
    }

    private func loadLogo(_ item: PhotosPickerItem?) {
        guard let item, let profile else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data),
               let path = FileStorage.saveLogo(image) {
                FileStorage.delete(relativePath: profile.logoPath)
                profile.logoPath = path
                save()
            }
            logoItem = nil
        }
    }

    private func save() {
        profile?.isPro = store.isPro
        try? context.save()
    }
}
