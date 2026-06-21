import Photos
import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject private var viewModel: PhotoLibraryViewModel

    @State private var showSettings = false

    private var summaryBinding: Binding<Bool> {
        Binding(
            get: { viewModel.showSummary },
            set: { newValue in
                if newValue {
                    viewModel.presentSummary()
                } else {
                    viewModel.dismissSummary()
                }
            }
        )
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.authorizationStatus {
                case .authorized, .limited:
                    mainInterface

                case .denied, .restricted:
                    permissionDeniedView

                case .notDetermined:
                    requestingAccessView

                @unknown default:
                    requestingAccessView
                }
            }
            .navigationTitle("Photo Cleaner")
            .toolbar { toolbarContent }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(viewModel)
            }
            .fullScreenCover(isPresented: summaryBinding) {
                DeleteSummaryView()
                    .environmentObject(viewModel)
            }
            .alert(
                "Unable to Undo",
                isPresented: Binding(
                    get: { viewModel.undoUnavailableMessage != nil },
                    set: { if !$0 { viewModel.clearUndoUnavailableMessage() } }
                )
            ) {
                Button("OK", role: .cancel) {
                    viewModel.clearUndoUnavailableMessage()
                }
            } message: {
                Text(viewModel.undoUnavailableMessage ?? "")
            }
            .alert(
                "Error",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.clearErrorMessage() } }
                )
            ) {
                Button("OK", role: .cancel) {
                    viewModel.clearErrorMessage()
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
        .task {
            await viewModel.requestPhotoAccess()
        }
    }

    @ViewBuilder
    private var mainInterface: some View {
        VStack(spacing: 16) {
            statsBar

            ZStack {
                if viewModel.isLoading {
                    ProgressView("Loading library…")
                } else if viewModel.assets.isEmpty && !viewModel.showSummary {
                    emptyStateView
                } else if !viewModel.assets.isEmpty {
                    CardStackView(
                        assets: viewModel.assets,
                        onSwipeKeep: { viewModel.handleSwipeKeep() },
                        onSwipeDelete: { viewModel.handleSwipeDelete() }
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            actionHints
        }
        .padding(.bottom, 8)
    }

    private var statsBar: some View {
        HStack {
            statPill(title: "Remaining", value: viewModel.remainingCount)
            Spacer()
            if !viewModel.instantDeleteMode {
                statPill(title: "To Delete", value: viewModel.deletedCount, tint: .red)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private func statPill(title: String, value: Int, tint: Color = .primary) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(value)")
                .font(.title3.weight(.semibold))
                .foregroundStyle(tint)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var actionHints: some View {
        HStack(spacing: 28) {
            Label("Delete", systemImage: "arrow.left")
                .foregroundStyle(.red)
            Button {
                viewModel.undoLastSwipe()
            } label: {
                Label("Undo", systemImage: "arrow.uturn.backward")
            }
            .disabled(!viewModel.canUndo)
            Label("Keep", systemImage: "arrow.right")
                .foregroundStyle(.green)
        }
        .font(.subheadline.weight(.semibold))
        .padding(.horizontal, 20)
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green)
            Text("All caught up!")
                .font(.title2.weight(.bold))
            Text(viewModel.deleteBatch.isEmpty
                 ? "No more photos or videos in this session."
                 : "Review your deletion batch to finish.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            if !viewModel.deleteBatch.isEmpty {
                Button("Review Deletions") {
                    viewModel.presentSummary()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
        }
        .padding()
    }

    private var requestingAccessView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Requesting photo library access…")
                .foregroundStyle(.secondary)
        }
    }

    private var permissionDeniedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Photo Access Needed")
                .font(.title2.weight(.bold))
            Text("Enable photo library access in Settings to clean up your library.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            Button("Open Settings") {
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(url)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
            }
            .accessibilityLabel("Settings")
        }

        if viewModel.canUndo {
            ToolbarItem(placement: .topBarLeading) {
                Button("Undo") {
                    viewModel.undoLastSwipe()
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(PhotoLibraryViewModel())
}
