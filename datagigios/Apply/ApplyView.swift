//
//  ApplyView.swift
//  datagigios
//

import SwiftUI

struct ApplyView: View {
    @State private var viewModel: ApplyViewModel
    @Environment(\.dismiss) private var dismiss

    private let noteCharLimit = 500

    init(gig: GigDetail, session: Session) {
        _viewModel = State(initialValue: ApplyViewModel(gig: gig, session: session))
    }

    var body: some View {
        Form {
            DeviceTypeSection(viewModel: viewModel)

            NoteSection(viewModel: viewModel, noteCharLimit: noteCharLimit)

            if let errorMessage = viewModel.error {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.subheadline)
                }
            }
        }
        .navigationTitle(viewModel.gigTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    Button("Submit") {
                        Task { await viewModel.submit() }
                    }
                    .bold()
                    .disabled(viewModel.isLoading)
                }
            }
        }
        .onChange(of: viewModel.submitted) { _, submitted in
            if submitted { dismiss() }
        }
        .sensoryFeedback(.success, trigger: viewModel.submitted)
        .sensoryFeedback(.error, trigger: viewModel.error) { old, new in
            old == nil && new != nil
        }
        .interactiveDismissDisabled(viewModel.isLoading)
    }
}

// MARK: - DeviceTypeSection

private struct DeviceTypeSection: View {
    @Bindable var viewModel: ApplyViewModel

    var body: some View {
        Section("Device Type") {
            if viewModel.availableDeviceTypes.count == 1 {
                Label(deviceTypeLabel(viewModel.selectedDeviceType), systemImage: deviceTypeIcon(viewModel.selectedDeviceType))
                    .foregroundStyle(.secondary)
            } else {
                Picker("Device Type", selection: $viewModel.selectedDeviceType) {
                    ForEach(viewModel.availableDeviceTypes, id: \.self) { type in
                        Label(deviceTypeLabel(type), systemImage: deviceTypeIcon(type))
                            .tag(type)
                    }
                }
            }
        }
    }

    private func deviceTypeIcon(_ type: String) -> String {
        switch type {
        case "apple_watch": return "applewatch"
        case "generic_android": return "iphone.gen1"
        default: return "iphone"
        }
    }

    private func deviceTypeLabel(_ type: String) -> String {
        switch type {
        case "apple_watch": return "Apple Watch"
        case "generic_android": return "Android"
        default: return "iPhone"
        }
    }
}

// MARK: - NoteSection

private struct NoteSection: View {
    @Bindable var viewModel: ApplyViewModel
    let noteCharLimit: Int

    var body: some View {
        Section {
            ZStack(alignment: .bottomTrailing) {
                TextEditor(text: $viewModel.noteFromUser)
                    .frame(minHeight: 100)
                    .onChange(of: viewModel.noteFromUser) { _, newValue in
                        if newValue.count > noteCharLimit {
                            viewModel.noteFromUser = String(newValue.prefix(noteCharLimit))
                        }
                    }

                Text("\(viewModel.noteFromUser.count) / \(noteCharLimit)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(4)
            }
        } header: {
            Text("Note (Optional)")
        } footer: {
            Text("Add any relevant information for the company.")
        }
    }
}
