import Photos
import SwiftUI

struct CardStackView: View {
    let assets: [PHAsset]
    let onSwipeKeep: () -> Void
    let onSwipeDelete: () -> Void

    var body: some View {
        ZStack {
            ForEach(Array(visibleAssets.enumerated()), id: \.element.localIdentifier) { index, asset in
                let isTop = index == visibleAssets.count - 1

                SwipeableCardView(
                    asset: asset,
                    isInteractive: isTop,
                    onSwipeKeep: onSwipeKeep,
                    onSwipeDelete: onSwipeDelete
                )
                .scaleEffect(scale(for: index, total: visibleAssets.count))
                .offset(y: yOffset(for: index, total: visibleAssets.count))
                .zIndex(Double(index))
                .allowsHitTesting(isTop)
            }
        }
        .padding(.horizontal, 20)
    }

    private var visibleAssets: [PHAsset] {
        Array(assets.prefix(3))
    }

    private func scale(for index: Int, total: Int) -> CGFloat {
        let depth = total - 1 - index
        return 1 - (CGFloat(depth) * 0.04)
    }

    private func yOffset(for index: Int, total: Int) -> CGFloat {
        let depth = total - 1 - index
        return CGFloat(depth) * 10
    }
}
