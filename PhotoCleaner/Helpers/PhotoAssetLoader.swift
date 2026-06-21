import Photos
import UIKit

enum PhotoAssetLoader {
    private static let imageManager = PHCachingImageManager()

    static func requestThumbnail(
        for asset: PHAsset,
        targetSize: CGSize,
        contentMode: PHImageContentMode = .aspectFill,
        completion: @escaping (UIImage?) -> Void
    ) -> PHImageRequestID {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true

        return imageManager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: contentMode,
            options: options
        ) { image, _ in
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }

    static func cancelRequest(_ requestID: PHImageRequestID) {
        imageManager.cancelImageRequest(requestID)
    }

    static func formattedFileSize(for asset: PHAsset) -> String {
        let resources = PHAssetResource.assetResources(for: asset)
        let totalBytes = resources.reduce(Int64(0)) { partial, resource in
            partial + (resource.value(forKey: "fileSize") as? Int64 ?? 0)
        }

        guard totalBytes > 0 else { return "—" }

        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalBytes)
    }
}
