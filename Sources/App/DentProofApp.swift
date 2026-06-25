import SwiftUI
import SwiftData

@main
struct DentProofApp: App {
    @StateObject private var store = StoreManager()

    /// Single local SwiftData container for all models.
    let modelContainer: ModelContainer = {
        let schema = Schema([
            BusinessProfile.self,
            Inspection.self,
            DamageMark.self,
            InspectionPhoto.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .tint(Color.clayDeep)
                .task {
                    await store.loadProducts()
                }
        }
        .modelContainer(modelContainer)
    }
}
