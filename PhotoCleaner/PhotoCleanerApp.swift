import SwiftUI

@main
struct PhotoCleanerApp: App {
    @StateObject private var viewModel = PhotoLibraryViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}
