import Combine
import Photos
import SwiftUI

@MainActor
final class PhotoLibraryViewModel: ObservableObject {
    private static let instantDeleteModeKey = "instantDeleteMode"

    @Published private(set) var assets: [PHAsset] = []
    @Published private(set) var deleteBatch: [PHAsset] = []
    @Published private(set) var swipeHistory: [SwipeRecord] = []
    @Published private(set) var authorizationStatus: PHAuthorizationStatus = .notDetermined
    @Published private(set) var isLoading = false
    @Published private(set) var showSummary = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var undoUnavailableMessage: String?

    @Published var instantDeleteMode: Bool = UserDefaults.standard.bool(forKey: "instantDeleteMode")

    var canUndo: Bool { !swipeHistory.isEmpty }
    var remainingCount: Int { assets.count }
    var deletedCount: Int { deleteBatch.count }
    var showFinishButton: Bool {
        assets.isEmpty && !deleteBatch.isEmpty && !instantDeleteMode
    }

    func requestPhotoAccess() async {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        authorizationStatus = status

        guard status == .authorized || status == .limited else { return }
        await loadAssets()
    }

    func loadAssets() async {
        isLoading = true
        defer { isLoading = false }

        assets = fetchAllMediaAssets()
        swipeHistory = []
        showSummary = false
        deleteBatch = []
    }

    func loadLastN(_ count: Int) async -> Bool {
        guard count > 0 else {
            errorMessage = "Please enter a number greater than zero."
            return false
        }

        isLoading = true
        defer { isLoading = false }

        let fetched = Array(fetchAllMediaAssets().prefix(count))
        return applyFilteredAssets(fetched, clearDeleteBatch: false)
    }

    func loadRandom(_ count: Int) async -> Bool {
        guard count > 0 else {
            errorMessage = "Please enter a number greater than zero."
            return false
        }

        isLoading = true
        defer { isLoading = false }

        let all = fetchAllMediaAssets()
        let limit = min(count, all.count)
        let fetched = Array(all.shuffled().prefix(limit))
        return applyFilteredAssets(fetched, clearDeleteBatch: false)
    }

    func loadDateRange(from startDate: Date, to endDate: Date) async -> Bool {
        let range = normalizedDateRange(from: startDate, to: endDate)
        guard range.start <= range.end else {
            errorMessage = "The start date must be on or before the end date."
            return false
        }

        isLoading = true
        defer { isLoading = false }

        let fetched = fetchAllMediaAssets().filter { asset in
            guard let creationDate = asset.creationDate else { return false }
            return creationDate >= range.start && creationDate <= range.end
        }

        return applyFilteredAssets(fetched, clearDeleteBatch: false)
    }

    func handleSwipeKeep() {
        guard let asset = assets.first else { return }

        assets.removeFirst()
        swipeHistory.append(SwipeRecord(asset: asset, action: .keep, wasInstantDelete: false))
        advanceIfFinished()
    }

    func handleSwipeDelete() {
        guard let asset = assets.first else { return }

        if instantDeleteMode {
            assets.removeFirst()
            Task {
                let success = await deleteAssets([asset])
                if success {
                    swipeHistory.append(
                        SwipeRecord(asset: asset, action: .delete, wasInstantDelete: true)
                    )
                    advanceIfFinished()
                } else {
                    assets.insert(asset, at: 0)
                }
            }
        } else {
            assets.removeFirst()
            deleteBatch.append(asset)
            swipeHistory.append(SwipeRecord(asset: asset, action: .delete, wasInstantDelete: false))
            advanceIfFinished()
        }
    }

    func undoLastSwipe() {
        guard let last = swipeHistory.popLast() else { return }

        switch last.action {
        case .keep:
            assets.insert(last.asset, at: 0)
            showSummary = false

        case .delete where last.wasInstantDelete:
            if assetExists(last.asset) {
                assets.insert(last.asset, at: 0)
                showSummary = false
            } else {
                undoUnavailableMessage =
                    "This photo was already deleted. Check the Recently Deleted album in Photos to restore it."
            }

        case .delete:
            if let index = deleteBatch.firstIndex(where: { $0.localIdentifier == last.asset.localIdentifier }) {
                deleteBatch.remove(at: index)
            }
            assets.insert(last.asset, at: 0)
            showSummary = false
        }
    }

    func confirmBatchDelete() async {
        guard !deleteBatch.isEmpty else { return }

        let assetsToDelete = deleteBatch
        let success = await deleteAssets(assetsToDelete)

        if success {
            deleteBatch.removeAll()
            swipeHistory.removeAll { record in
                record.action == .delete && !record.wasInstantDelete
            }
            showSummary = false
            await loadAssets()
        }
    }

    func dismissSummary() {
        showSummary = false
    }

    func presentSummary() {
        showSummary = true
    }

    func clearUndoUnavailableMessage() {
        undoUnavailableMessage = nil
    }

    func clearErrorMessage() {
        errorMessage = nil
    }

    func setInstantDeleteMode(_ enabled: Bool) {
        instantDeleteMode = enabled
        UserDefaults.standard.set(enabled, forKey: Self.instantDeleteModeKey)
    }

    // MARK: - Private

    private func deleteAssets(_ assetsToDelete: [PHAsset]) async -> Bool {
        await withCheckedContinuation { continuation in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.deleteAssets(assetsToDelete as NSFastEnumeration)
            } completionHandler: { success, error in
                Task { @MainActor in
                    if let error {
                        self.errorMessage = error.localizedDescription
                    }
                    continuation.resume(returning: success)
                }
            }
        }
    }

    private func advanceIfFinished() {
        // Summary is shown manually via the Finish button.
    }

    @discardableResult
    private func applyFilteredAssets(_ fetched: [PHAsset], clearDeleteBatch: Bool) -> Bool {
        guard !fetched.isEmpty else {
            errorMessage = "No photos or videos found for this filter."
            return false
        }

        assets = fetched
        swipeHistory = []
        showSummary = false

        if clearDeleteBatch {
            deleteBatch = []
        }

        return true
    }

    private func fetchAllMediaAssets() -> [PHAsset] {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.predicate = NSPredicate(
            format: "mediaType == %d OR mediaType == %d",
            PHAssetMediaType.image.rawValue,
            PHAssetMediaType.video.rawValue
        )

        let result = PHAsset.fetchAssets(with: fetchOptions)
        var fetched: [PHAsset] = []
        fetched.reserveCapacity(result.count)

        result.enumerateObjects { asset, _, _ in
            fetched.append(asset)
        }

        return fetched
    }

    private func normalizedDateRange(from startDate: Date, to endDate: Date) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endDate) ?? endDate
        return (start, end)
    }

    private func assetExists(_ asset: PHAsset) -> Bool {
        let result = PHAsset.fetchAssets(
            withLocalIdentifiers: [asset.localIdentifier],
            options: nil
        )
        return result.count > 0
    }
}
