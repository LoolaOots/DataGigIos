import SwiftUI

struct GigRecordingsLibraryView: View {
    let detail: ApplicationDetail
    let accessToken: String
    @State private var viewModel: GigRecordingsLibraryViewModel
    @Environment(SubmissionService.self) private var submissionService
    @State private var showUploadError = false
    @State private var uploadErrorMessage = ""
    @State private var permissionsManager = PermissionsManager()
    @State private var showCollection = false
    @State private var showPermissionsDenied = false
    @State private var showDeleteConfirmation = false
    @State private var recordingToDelete: GigRecordingSession? = nil
    @State private var showDeleteSelectedConfirmation = false

    init(detail: ApplicationDetail, accessToken: String) {
        self.detail = detail
        self.accessToken = accessToken
        _viewModel = State(wrappedValue: GigRecordingsLibraryViewModel(
            assignmentCode: detail.assignmentCode ?? "",
            gigTitle: detail.gigDetail.title,
            companyName: detail.gigDetail.companyName
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.sessions.isEmpty {
                EmptyStateView(
                    permissionsManager: permissionsManager,
                    showCollection: $showCollection,
                    showPermissionsDenied: $showPermissionsDenied
                )
            } else {
                SessionListView(
                    viewModel: viewModel,
                    submissionService: submissionService,
                    accessToken: accessToken,
                    showUploadError: $showUploadError,
                    uploadErrorMessage: $uploadErrorMessage,
                    showDeleteConfirmation: $showDeleteConfirmation,
                    recordingToDelete: $recordingToDelete
                )
            }
        }
        .navigationTitle("\(viewModel.gigTitle) - \(viewModel.companyName)")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(viewModel.isSelectMode)
        .toolbar { toolbarContent }
        .safeAreaInset(edge: .bottom) {
            if viewModel.isSelectMode {
                BottomBarView(
                    viewModel: viewModel,
                    submissionService: submissionService,
                    accessToken: accessToken,
                    showUploadError: $showUploadError,
                    uploadErrorMessage: $uploadErrorMessage,
                    showDeleteSelectedConfirmation: $showDeleteSelectedConfirmation
                )
            }
        }
        .onAppear { viewModel.load() }
        .navigationDestination(isPresented: $showCollection) {
            GigCollectionView(viewModel: GigCollectionViewModel(detail: detail), accessToken: accessToken)
        }
        .navigationDestination(isPresented: $showPermissionsDenied) {
            PermissionsDeniedView(
                onGranted: {
                    showPermissionsDenied = false
                    showCollection = true
                },
                onBack: { showPermissionsDenied = false }
            )
        }
        .alert("Upload Error", isPresented: $showUploadError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(uploadErrorMessage)
        }
        .alert("Delete Recording?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let session = recordingToDelete {
                    viewModel.delete(session: session)
                    recordingToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) {
                recordingToDelete = nil
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .alert("Delete Recording?", isPresented: $showDeleteSelectedConfirmation) {
            Button("Delete", role: .destructive) {
                viewModel.deleteSelected()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if viewModel.isSelectMode {
            ToolbarItem(placement: .principal) {
                Text("\(viewModel.selectedIDs.count) Selected").bold()
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    viewModel.clearSelection()
                    viewModel.isSelectMode = false
                }
            }
        } else if !viewModel.sessions.isEmpty {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Select") { viewModel.isSelectMode = true }
            }
        }
    }
}

// MARK: - Empty State

private struct EmptyStateView: View {
    let permissionsManager: PermissionsManager
    @Binding var showCollection: Bool
    @Binding var showPermissionsDenied: Bool

    var body: some View {
        VStack(spacing: 16) {
            ContentUnavailableView(
                "No Recordings",
                systemImage: "waveform.slash",
                description: Text("Record a label to see it here.")
            )
            Button {
                permissionsManager.check { result in
                    switch result {
                    case .granted: showCollection = true
                    case .denied:  showPermissionsDenied = true
                    }
                }
            } label: {
                Label("Start Collecting Data", systemImage: "record.circle")
                    .font(.headline)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }
}

// MARK: - Session List

private struct SessionListView: View {
    @Bindable var viewModel: GigRecordingsLibraryViewModel
    @Bindable var submissionService: SubmissionService
    let accessToken: String
    @Binding var showUploadError: Bool
    @Binding var uploadErrorMessage: String
    @Binding var showDeleteConfirmation: Bool
    @Binding var recordingToDelete: GigRecordingSession?

    var body: some View {
        List {
            Section(header: Text("Available Recordings").textCase(.none).font(.subheadline).foregroundStyle(.secondary)) {
                ForEach(viewModel.sessions) { session in
                    SessionRowView(viewModel: viewModel, session: session)
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                recordingToDelete = session
                                showDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                Task {
                                    do {
                                        try await submissionService.submit(session: session, accessToken: accessToken)
                                    } catch {
                                        uploadErrorMessage = error.localizedDescription
                                        showUploadError = true
                                    }
                                }
                            } label: {
                                Label("Submit", systemImage: "arrow.up.circle")
                            }
                            .tint(.blue)
                            .disabled(submissionService.isSubmitting || submissionService.submittedSessionIds.contains(session.id))
                        }
                }
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Session Row

private struct SessionRowView: View {
    @Bindable var viewModel: GigRecordingsLibraryViewModel
    let session: GigRecordingSession

    var body: some View {
        if viewModel.isSelectMode {
            let isSelected = viewModel.selectedIDs.contains(session.id)
            Button { viewModel.toggleSelect(session.id) } label: {
                SessionRowBodyView(viewModel: viewModel, session: session)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(session.labelName) recording, \(session.startTime.formatted(date: .abbreviated, time: .shortened))")
            .accessibilityValue(isSelected ? "Selected" : "Not selected")
            .accessibilityHint("Double-tap to \(isSelected ? "deselect" : "select")")
        } else {
            SessionRowBodyView(viewModel: viewModel, session: session)
        }
    }
}

private struct SessionRowBodyView: View {
    @Bindable var viewModel: GigRecordingsLibraryViewModel
    let session: GigRecordingSession

    var body: some View {
        HStack(spacing: 10) {
            if viewModel.isSelectMode {
                SelectCircleView(id: session.id, selectedIDs: viewModel.selectedIDs)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(session.startTime, style: .date) + Text(", ") + Text(session.startTime, style: .time)
                    LabelTagView(name: session.labelName)
                }
                .font(.subheadline).bold()
                Text("\(session.frames.count) frames captured")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Spacer()

            if !viewModel.isSelectMode {
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, 12)
        .background(viewModel.selectedIDs.contains(session.id) ? Color.green.opacity(0.08) : Color.clear)
        .contentShape(Rectangle())
    }
}

// MARK: - Label Tag

private struct LabelTagView: View {
    let name: String

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "tag.fill")
                .font(.caption2)
            Text(name.uppercased())
                .font(.caption2).bold()
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(.blue, in: Capsule())
    }
}

// MARK: - Select Circle

private struct SelectCircleView: View {
    let id: UUID
    let selectedIDs: Set<UUID>

    var body: some View {
        let selected = selectedIDs.contains(id)
        ZStack {
            Circle()
                .fill(selected ? Color.green : Color.clear)
                .overlay(Circle().stroke(selected ? Color.green : Color.gray, lineWidth: 2))
                .frame(width: 22, height: 22)
            if selected {
                Image(systemName: "checkmark")
                    .font(.caption2).bold()
                    .foregroundStyle(.black)
            }
        }
    }
}

// MARK: - Bottom Bar

private struct BottomBarView: View {
    @Bindable var viewModel: GigRecordingsLibraryViewModel
    @Bindable var submissionService: SubmissionService
    let accessToken: String
    @Binding var showUploadError: Bool
    @Binding var uploadErrorMessage: String
    @Binding var showDeleteSelectedConfirmation: Bool

    var body: some View {
        HStack {
            Button("Delete (\(viewModel.selectedIDs.count))", systemImage: "trash", role: .destructive) {
                showDeleteSelectedConfirmation = true
            }
            .font(.subheadline).bold()
            .disabled(viewModel.selectedIDs.isEmpty)

            Spacer()

            Button {
                let selectedSessions = viewModel.sessions.filter { viewModel.selectedIDs.contains($0.id) }
                Task {
                    var hadError = false
                    for session in selectedSessions {
                        guard !submissionService.submittedSessionIds.contains(session.id) else { continue }
                        do {
                            try await submissionService.submit(session: session, accessToken: accessToken)
                        } catch {
                            uploadErrorMessage = error.localizedDescription
                            showUploadError = true
                            hadError = true
                            break
                        }
                    }
                    if !hadError {
                        viewModel.clearSelection()
                        viewModel.isSelectMode = false
                    }
                }
            } label: {
                if submissionService.isSubmitting {
                    ProgressView()
                        .progressViewStyle(.circular)
                } else {
                    Label("Submit (\(viewModel.selectedIDs.count))", systemImage: "arrow.up.circle")
                }
            }
            .font(.subheadline).bold()
            .disabled(viewModel.selectedIDs.isEmpty || submissionService.isSubmitting)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(.regularMaterial)
    }
}
