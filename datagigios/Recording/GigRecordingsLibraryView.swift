import SwiftUI

struct GigRecordingsLibraryView: View {
    let detail: ApplicationDetail
    @State private var viewModel: GigRecordingsLibraryViewModel
    @State private var showUploadAlert = false
    @State private var activePopoverID: UUID?
    @State private var permissionsManager = PermissionsManager()
    @State private var showCollection = false
    @State private var showPermissionsDenied = false

    init(detail: ApplicationDetail) {
        self.detail = detail
        _viewModel = State(wrappedValue: GigRecordingsLibraryViewModel(
            assignmentCode: detail.assignmentCode ?? "",
            gigTitle: detail.gigDetail.title,
            companyName: detail.gigDetail.companyName
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.sessions.isEmpty {
                emptyState
            } else {
                sessionList
            }
        }
        .navigationTitle("\(viewModel.gigTitle) - \(viewModel.companyName)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .safeAreaInset(edge: .bottom) {
            if viewModel.isSelectMode { bottomBar }
        }
        .onAppear { viewModel.load() }
        .navigationDestination(isPresented: $showCollection) {
            GigCollectionView(viewModel: GigCollectionViewModel(detail: detail))
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
        .alert("Upload Coming Soon", isPresented: $showUploadAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Uploading recordings will be available in a future update.")
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
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

    // MARK: - Session List

    private var sessionList: some View {
        List {
            Section(header: Text("Available Recordings").textCase(.none).font(.subheadline).foregroundStyle(.secondary)) {
                ForEach(viewModel.sessions) { session in
                    sessionRow(session: session)
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                }
            }
        }
        .listStyle(.plain)
    }

    @ViewBuilder
    private func sessionRow(session: GigRecordingSession) -> some View {
        if viewModel.isSelectMode {
            Button { viewModel.toggleSelect(session.id) } label: { rowBody(session: session) }
                .buttonStyle(.plain)
        } else {
            rowBody(session: session)
        }
    }

    private func rowBody(session: GigRecordingSession) -> some View {
        HStack(spacing: 10) {
            if viewModel.isSelectMode {
                selectCircle(id: session.id)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(session.startTime, style: .date) + Text(", ") + Text(session.startTime, style: .time)
                    labelTag(session.labelName)
                }
                .font(.subheadline).bold()
                Text("\(session.frames.count) frames captured")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Spacer()

            if !viewModel.isSelectMode {
                Button {
                    activePopoverID = activePopoverID == session.id ? nil : session.id
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundStyle(.blue)
                }
                .popover(isPresented: Binding(
                    get: { activePopoverID == session.id },
                    set: { if !$0 { activePopoverID = nil } }
                )) {
                    popoverMenu(session: session)
                }

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 12)
        .background(viewModel.selectedIDs.contains(session.id) ? Color.green.opacity(0.08) : Color.clear)
        .contentShape(Rectangle())
    }

    private func labelTag(_ name: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: "tag.fill")
                .font(.system(size: 8))
            Text(name.uppercased())
                .font(.system(size: 10, weight: .bold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(.blue, in: Capsule())
    }

    private func selectCircle(id: UUID) -> some View {
        let selected = viewModel.selectedIDs.contains(id)
        return ZStack {
            Circle()
                .fill(selected ? Color.green : Color.clear)
                .overlay(Circle().stroke(selected ? Color.green : Color.gray, lineWidth: 2))
                .frame(width: 22, height: 22)
            if selected {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.black)
            }
        }
    }

    private func popoverMenu(session: GigRecordingSession) -> some View {
        VStack(spacing: 0) {
            Button {
                activePopoverID = nil
                showUploadAlert = true
            } label: {
                Label("Submit", systemImage: "arrow.up.circle")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            Divider()
            Button(role: .destructive) {
                activePopoverID = nil
                viewModel.delete(session: session)
            } label: {
                Label("Delete", systemImage: "trash")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
        }
        .frame(minWidth: 160)
        .presentationCompactAdaptation(.popover)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if viewModel.isSelectMode {
            ToolbarItem(placement: .topBarLeading) {
                Button("Select All") { viewModel.selectAll() }
            }
            ToolbarItem(placement: .principal) {
                Text("\(viewModel.selectedIDs.count) Selected").bold()
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { viewModel.clearSelection() }
            }
        } else if !viewModel.sessions.isEmpty {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Select") { viewModel.isSelectMode = true }
            }
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack {
            Button(role: .destructive) {
                viewModel.deleteSelected()
            } label: {
                Label("Delete (\(viewModel.selectedIDs.count))", systemImage: "trash")
                    .font(.subheadline).bold()
            }
            .disabled(viewModel.selectedIDs.isEmpty)

            Spacer()

            Button {
                showUploadAlert = true
            } label: {
                Label("Submit (\(viewModel.selectedIDs.count))", systemImage: "arrow.up.circle")
                    .font(.subheadline).bold()
            }
            .disabled(viewModel.selectedIDs.isEmpty)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(.regularMaterial)
    }
}
