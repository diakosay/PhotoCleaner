# Photo Cleaner

A lightweight native iOS app built with SwiftUI and the Photos framework. Swipe through your photo library to quickly keep or delete photos and videos.

## Features

- **Photo access** — Requests read/write library permission on launch via `PHPhotoLibrary`
- **Swipe stack** — Card stack UI with async thumbnail loading for photos and videos
- **Swipe right** — Keep (advance to next item)
- **Swipe left** — Delete (batch or instant, depending on settings)
- **Visual feedback** — Green KEEP / red DELETE overlays while dragging
- **Undo** — Restores the last swiped item (batch mode fully; instant mode if deletion was cancelled)
- **Settings** — Gear icon with **Instant Delete Mode** toggle
- **Batch review** — Summary screen with **Confirm Delete** when instant mode is off

## Requirements

- Xcode 15 or later
- iOS 17.0+ (SwiftUI `NavigationStack`, `@AppStorage`, modern Photos API)
- A physical iPhone or iPad is recommended (Simulator has limited photo library behavior)

## Setup in Xcode

### 1. Create the project

1. Open **Xcode** → **File** → **New** → **Project**
2. Choose **iOS** → **App**
3. Product Name: `PhotoCleaner`
4. Interface: **SwiftUI**
5. Language: **Swift**
6. Save anywhere you like (or clone/copy this folder)

### 2. Add the source files

Copy everything from this repo’s `PhotoCleaner/` folder into your Xcode project group:

```
PhotoCleaner/
├── PhotoCleanerApp.swift
├── ContentView.swift
├── Info.plist
├── Models/
│   └── SwipeRecord.swift
├── ViewModels/
│   └── PhotoLibraryViewModel.swift
├── Views/
│   ├── CardStackView.swift
│   ├── SwipeableCardView.swift
│   ├── PhotoAssetView.swift
│   ├── SettingsView.swift
│   └── DeleteSummaryView.swift
└── Helpers/
    └── PhotoAssetLoader.swift
```

In Xcode: **File** → **Add Files to "PhotoCleaner"…** → select the folders/files → ensure your app target is checked.

Delete Xcode’s default `ContentView.swift` if it conflicts (keep the one from this repo).

### 3. Configure privacy strings

Either use the included `Info.plist` or add these keys in the target **Info** tab:

| Key | Value |
|-----|-------|
| `Privacy - Photo Library Usage Description` | Photo Cleaner needs access to your photo library so you can review and remove photos and videos. |
| `Privacy - Photo Library Additions Usage Description` | Photo Cleaner needs photo library access to manage your media. |

### 4. Enable Photos capability

1. Select the **PhotoCleaner** target
2. **Signing & Capabilities** → **+ Capability**
3. No special entitlement is required beyond the usage descriptions for basic library read/write

### 5. Set deployment target

Target → **General** → **Minimum Deployments** → **iOS 17.0**

### 6. Build and run

1. Connect your iPhone or pick a simulator with sample photos
2. **Product** → **Run** (⌘R)
3. Grant photo library access when prompted

## How it works

### View model (`PhotoLibraryViewModel`)

- Loads `PHAsset` items (images + videos), newest first
- Maintains `assets` (remaining stack), `deleteBatch`, and `swipeHistory` for undo
- `instantDeleteMode` persisted with `@AppStorage`
- Batch deletion uses `PHPhotoLibrary.shared().performChanges`

### Undo behavior

| Mode | Swipe | Undo |
|------|-------|------|
| Batch (default) | Left → added to batch | Removes from batch, restores card |
| Batch | Right → keep | Restores card |
| Instant | Left → system delete prompt | Works if delete was cancelled; if confirmed, item is in Recently Deleted (see alert) |

### Instant Delete Mode

- **OFF (default):** Left swipes queue items; when the stack is empty, the summary screen appears
- **ON:** Each left swipe calls `performChanges` immediately for that asset (Apple’s deletion confirmation)

## Project structure

| File | Role |
|------|------|
| `PhotoCleanerApp.swift` | App entry, shared view model |
| `ContentView.swift` | Main screen, permissions, toolbar |
| `PhotoLibraryViewModel.swift` | Library loading, swipe logic, batch/instant delete |
| `SwipeableCardView.swift` | Drag gesture, KEEP/DELETE overlays |
| `CardStackView.swift` | 3-card depth stack |
| `PhotoAssetView.swift` | Async thumbnail/video badge |
| `SettingsView.swift` | Instant Delete toggle |
| `DeleteSummaryView.swift` | Grid preview + Confirm Delete |

## Notes

- Deletions move items to **Recently Deleted** in the Photos app (standard iOS behavior), not immediate permanent erasure
- Large libraries load metadata first; thumbnails load asynchronously per card
- For `.limited` photo access, iOS may restrict which assets appear

## License

MIT — use and modify freely.
