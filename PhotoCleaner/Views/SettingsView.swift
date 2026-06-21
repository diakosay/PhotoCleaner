import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var viewModel: PhotoLibraryViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var dateFrom = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var dateTo = Date()
    @State private var customCount = ""
    @State private var randomCount = "50"
    @State private var isApplyingFilter = false

    private let quickFilterCounts = [10, 20, 30, 100, 200]

    private var instantDeleteBinding: Binding<Bool> {
        Binding(
            get: { viewModel.instantDeleteMode },
            set: { viewModel.setInstantDeleteMode($0) }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                deletionSection
                filterSection
                quickFilterSection
                randomSection
                guideSection
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .disabled(isApplyingFilter)
        }
    }

    private var deletionSection: some View {
        Section {
            Toggle(isOn: instantDeleteBinding) {
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
    }

    private var filterSection: some View {
        Section {
            DatePicker("From", selection: $dateFrom, displayedComponents: .date)
            DatePicker("To", selection: $dateTo, displayedComponents: .date)

            Button {
                applyDateRangeFilter()
            } label: {
                HStack {
                    Text("Apply Date Range")
                    Spacer()
                    if isApplyingFilter {
                        ProgressView()
                    }
                }
            }
        } header: {
            Text("Filter by Date Range")
        } footer: {
            Text("Only photos and videos taken between the selected dates will appear in the card stack.")
        }
    }

    private var quickFilterSection: some View {
        Section {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 8)], spacing: 8) {
                ForEach(quickFilterCounts, id: \.self) { count in
                    Button("Last \(count)") {
                        applyQuickFilter(count: count)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.vertical, 4)

            HStack {
                TextField("Custom number", text: $customCount)
                    .keyboardType(.numberPad)

                Button("Load") {
                    applyCustomQuickFilter()
                }
                .disabled(parsedCount(from: customCount) == nil)
            }
        } header: {
            Text("Quick Filter")
        } footer: {
            Text("Load only the most recent photos and videos from your library.")
        }
    }

    private var randomSection: some View {
        Section {
            HStack {
                Text("Count")
                Spacer()
                TextField("50", text: $randomCount)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 100)
            }

            Button {
                applyRandomFilter()
            } label: {
                HStack {
                    Text("Load Random Photos")
                    Spacer()
                    if isApplyingFilter {
                        ProgressView()
                    }
                }
            }
            .disabled(parsedCount(from: randomCount) == nil)
        } header: {
            Text("Random Selection")
        } footer: {
            Text("Pick a random set of photos and videos from your library to review.")
        }
    }

    private var guideSection: some View {
        Section("How to Swipe") {
            Label("Swipe right to keep", systemImage: "arrow.right.circle.fill")
                .foregroundStyle(.green)
            Label("Swipe left to delete", systemImage: "arrow.left.circle.fill")
                .foregroundStyle(.red)
        }
    }

    private var aboutSection: some View {
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

    private func parsedCount(from text: String) -> Int? {
        guard let value = Int(text.trimmingCharacters(in: .whitespacesAndNewlines)), value > 0 else {
            return nil
        }
        return value
    }

    private func applyDateRangeFilter() {
        isApplyingFilter = true
        Task {
            let success = await viewModel.loadDateRange(from: dateFrom, to: dateTo)
            isApplyingFilter = false
            if success { dismiss() }
        }
    }

    private func applyQuickFilter(count: Int) {
        isApplyingFilter = true
        Task {
            let success = await viewModel.loadLastN(count)
            isApplyingFilter = false
            if success { dismiss() }
        }
    }

    private func applyCustomQuickFilter() {
        guard let count = parsedCount(from: customCount) else { return }
        applyQuickFilter(count: count)
    }

    private func applyRandomFilter() {
        guard let count = parsedCount(from: randomCount) else { return }

        isApplyingFilter = true
        Task {
            let success = await viewModel.loadRandom(count)
            isApplyingFilter = false
            if success { dismiss() }
        }
    }
}
