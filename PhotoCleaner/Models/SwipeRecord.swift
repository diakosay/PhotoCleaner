import Photos

enum SwipeAction {
    case keep
    case delete
}

struct SwipeRecord: Identifiable {
    let id = UUID()
    let asset: PHAsset
    let action: SwipeAction
    let wasInstantDelete: Bool
}
