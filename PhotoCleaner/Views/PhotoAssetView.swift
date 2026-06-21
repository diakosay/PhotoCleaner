import Photos
import SwiftUI

struct PhotoAssetView: View {
    let asset: PHAsset

    @State private var image: UIImage?
    @State private var requestID: PHImageRequestID?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                } else {
                    Color(.secondarySystemBackground)
                    ProgressView()
                }

                if asset.mediaType == .video {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "play.circle.fill")
                                .font(.title)
                                .symbolRenderingMode(.hierarchical)
                            Text(formatDuration(asset.duration))
                                .font(.subheadline.weight(.semibold))
                        }
                        .padding(10)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding()
                    }
                }
            }
            .onAppear {
                loadThumbnail(size: geometry.size)
            }
            .onDisappear {
                if let requestID {
                    PhotoAssetLoader.cancelRequest(requestID)
                }
            }
            .onChange(of: asset.localIdentifier) { _, _ in
                image = nil
                loadThumbnail(size: geometry.size)
            }
        }
    }

    private func loadThumbnail(size: CGSize) {
        if let requestID {
            PhotoAssetLoader.cancelRequest(requestID)
        }

        let scale = UIScreen.main.scale
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)

        requestID = PhotoAssetLoader.requestThumbnail(for: asset, targetSize: targetSize) { loaded in
            image = loaded
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let total = Int(duration.rounded())
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
