import Photos
import SwiftUI
import UIKit

struct DeleteSummaryView: View {
    @EnvironmentObject private var viewModel: PhotoLibraryViewModel

    @State private var isDeleting = false

    private let columns = [
        GridItem(.adaptive(minimum: 88), spacing: 8)
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        summaryHeader

                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(viewModel.deleteBatch, id: \.localIdentifier) { asset in
                                SummaryThumbnailView(asset: asset)
                                    .frame(height: 88)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                        }
                    }
                    .padding()
                }

                confirmBar
            }
            .navigationTitle("Review Deletions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Back") {
                        viewModel.dismissSummary()
                    }
                }
            }
        }
    }

    private var summaryHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(viewModel.deleteBatch.count) item\(viewModel.deleteBatch.count == 1 ? "" : "s") selected")
                .font(.title2.weight(.bold))

            Text("These photos and videos will be moved to Recently Deleted in the Photos app. You can recover them there for up to 30 days.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var confirmBar: some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    isDeleting = true
                    await viewModel.confirmBatchDelete()
                    isDeleting = false
                }
            } label: {
                Group {
                    if isDeleting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Confirm Delete")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .disabled(isDeleting || viewModel.deleteBatch.isEmpty)
        }
        .padding()
        .background(.bar)
    }
}

private struct SummaryThumbnailView: View {
    let asset: PHAsset

    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Color(.secondarySystemBackground)
                ProgressView()
            }

            if asset.mediaType == .video {
                Image(systemName: "play.fill")
                    .font(.caption)
                    .padding(6)
                    .background(.ultraThinMaterial, in: Circle())
            }
        }
        .onAppear {
            let scale = UIScreen.main.scale
            _ = PhotoAssetLoader.requestThumbnail(
                for: asset,
                targetSize: CGSize(width: 120 * scale, height: 120 * scale)
            ) { loaded in
                image = loaded
            }
        }
    }
}
