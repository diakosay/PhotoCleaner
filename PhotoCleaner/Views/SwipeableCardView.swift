import Photos
import SwiftUI

struct SwipeableCardView: View {
    let asset: PHAsset
    let isInteractive: Bool
    let onSwipeKeep: () -> Void
    let onSwipeDelete: () -> Void

    @State private var offset: CGSize = .zero
    @State private var isDragging = false

    private let swipeThreshold: CGFloat = 120

    private var swipeProgress: CGFloat {
        min(abs(offset.width) / swipeThreshold, 1)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.18), radius: 12, y: 8)

            PhotoAssetView(asset: asset)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            swipeOverlay

            VStack {
                HStack {
                    metadataBadge
                    Spacer()
                    if asset.mediaType == .video {
                        Label("Video", systemImage: "video.fill")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                }
                .padding(14)
                Spacer()
            }
        }
        .offset(x: offset.width, y: offset.height * 0.15)
        .rotationEffect(.degrees(Double(offset.width / 18)))
        .scaleEffect(isDragging ? 1.02 : 1)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isDragging)
        .gesture(dragGesture)
        .allowsHitTesting(isInteractive)
    }

    @ViewBuilder
    private var swipeOverlay: some View {
        if offset.width > 20 {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.green.opacity(0.25 * swipeProgress))
                .overlay(alignment: .leading) {
                    keepLabel
                        .padding(.leading, 24)
                        .opacity(Double(swipeProgress))
                }
        } else if offset.width < -20 {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.red.opacity(0.25 * swipeProgress))
                .overlay(alignment: .trailing) {
                    deleteLabel
                        .padding(.trailing, 24)
                        .opacity(Double(swipeProgress))
                }
        }
    }

    private var keepLabel: some View {
        Label("KEEP", systemImage: "checkmark.circle.fill")
            .font(.title2.weight(.heavy))
            .foregroundStyle(.green)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().stroke(.green, lineWidth: 2))
    }

    private var deleteLabel: some View {
        Label("DELETE", systemImage: "trash.fill")
            .font(.title2.weight(.heavy))
            .foregroundStyle(.red)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().stroke(.red, lineWidth: 2))
    }

    private var metadataBadge: some View {
        Text(PhotoAssetLoader.formattedFileSize(for: asset))
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                isDragging = true
                offset = value.translation
            }
            .onEnded { value in
                isDragging = false

                if value.translation.width > swipeThreshold {
                    completeSwipe(direction: 1, action: onSwipeKeep)
                } else if value.translation.width < -swipeThreshold {
                    completeSwipe(direction: -1, action: onSwipeDelete)
                } else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        offset = .zero
                    }
                }
            }
    }

    private func completeSwipe(direction: CGFloat, action: @escaping () -> Void) {
        withAnimation(.easeOut(duration: 0.22)) {
            offset = CGSize(width: direction * 600, height: offset.height)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            action()
            offset = .zero
        }
    }
}
