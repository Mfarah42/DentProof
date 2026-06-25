import SwiftUI
import SwiftData

/// Routes inside a single inspection's create/open flow.
enum FlowRoute: Hashable {
    case walkAround(Inspection)
    case signature(Inspection)
    case report(Inspection)
}

/// Container presented as a full-screen cover. Wraps the whole
/// create → mark → sign → report journey in one NavigationStack so the back
/// button and the "Continue" pushes behave naturally.
struct InspectionFlowView: View {
    enum Start {
        case new
        case open(Inspection)   // resumes a draft at the walk-around, or opens a signed report
    }

    let start: Start
    @Environment(\.dismiss) private var dismiss
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            rootView
                .navigationDestination(for: FlowRoute.self) { route in
                    switch route {
                    case .walkAround(let inspection):
                        WalkAroundView(inspection: inspection, path: $path)
                    case .signature(let inspection):
                        SignatureView(inspection: inspection, path: $path)
                    case .report(let inspection):
                        ReportView(inspection: inspection, onClose: { dismiss() })
                    }
                }
        }
    }

    @ViewBuilder
    private var rootView: some View {
        switch start {
        case .new:
            NewInspectionView(path: $path, onCancel: { dismiss() })
        case .open(let inspection):
            // A signed inspection opens straight to its report; a draft resumes
            // at the walk-around.
            if inspection.status == .signed {
                ReportView(inspection: inspection, onClose: { dismiss() })
            } else {
                WalkAroundView(inspection: inspection, path: $path)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Close") { dismiss() }
                        }
                    }
            }
        }
    }
}
