import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var viewModel: PhotoLibraryViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle(isOn: $viewModel.instantDeleteMode) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Instant Delete Mode")
                                .font(.body.weight(.semibold))
                            Text("When enabled, swiping left deletes each item immediately using the system prompt.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Deletion Behavior")
                } footer: {
                    Text("When disabled, deleted items are batched and reviewed on a summary screen before permanent deletion.")
                }

                Section("How to Swipe") {
                    Label("Swipe right to keep", systemImage: "arrow.right.circle.fill")
                        .foregroundStyle(.green)
                    Label("Swipe left to delete", systemImage: "arrow.left.circle.fill")
                        .foregroundStyle(.red)
                }

                Section("About") {
                    HStack {
                        Text("Remaining")
                        Spacer()
                        Text("\(viewModel.remainingCount)")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Marked for deletion")
                        Spacer()
                        Text("\(viewModel.deletedCount)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
