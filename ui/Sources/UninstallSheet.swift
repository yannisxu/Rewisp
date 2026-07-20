import SwiftUI

// The uninstall confirmation.
//
// Deliberately not a one-click button: this can delete months of screen history.
// It states exactly what will be removed, defaults to KEEPING the data (so an
// uninstall-and-reinstall doesn't silently cost you your memory), and everything
// goes to the Trash rather than being unlinked.
struct UninstallSheet: View {
    let onClose: () -> Void

    @State private var deleteData = false
    @State private var running = false
    @State private var report: Uninstall.Report?
    @State private var dataSize = "…"
    @ObservedObject private var status = StatusModel.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let report {
                finished(report)
            } else {
                confirm
            }
        }
        .frame(width: 460)
        .task { dataSize = Uninstall.dataSize() }
    }

    // MARK: - before

    private var confirm: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "trash")
                    .font(.system(size: 24))
                    .foregroundStyle(.red)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Uninstall Rewisp").font(.title3.weight(.semibold))
                    Text("Everything goes to the Trash, so you can change your mind.")
                        .font(.callout).foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 9) {
                item("Stop and remove the background helper", always: true)
                item("Give back the Screen Recording permission", always: true)
                item("Reset your settings", always: true)
                item("Move Rewisp to the Trash", always: true)
            }
            .padding(13)
            .background(.quaternary.opacity(0.3),
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            Divider()

            Toggle(isOn: $deleteData) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Also delete my memories")
                        .font(.callout.weight(.medium))
                    Text(memoryLine)
                        .font(.caption).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .toggleStyle(.checkbox)

            if !deleteData {
                Label("Your memories stay in ~/Rewisp. Reinstall later and Rewisp picks up exactly where it left off.",
                      systemImage: "checkmark.shield")
                    .font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Label("Going to the Trash, not erased — you can still recover it until you empty the Trash.",
                      systemImage: "exclamationmark.triangle.fill")
                    .font(.caption).foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack {
                Button("Cancel") { onClose() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button(role: .destructive) {
                    running = true
                    Task {
                        let r = await Uninstall.perform(
                            .init(deleteData: deleteData, deleteApp: true))
                        report = r
                        running = false
                    }
                } label: {
                    if running {
                        HStack(spacing: 7) {
                            ProgressView().controlSize(.small)
                            Text("Uninstalling…")
                        }
                    } else {
                        Text("Uninstall Rewisp")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(running)
            }
        }
        .padding(22)
    }

    private var memoryLine: String {
        let count = status.status?.captures_total
        let wisps = count.map { "\($0) wisps" } ?? "Your wisps"
        return "\(wisps), your Vault, and everything Rewisp learned about you — \(dataSize) in ~/Rewisp."
    }

    private func item(_ text: String, always: Bool) -> some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "circle.fill")
                .font(.system(size: 5))
                .foregroundStyle(.secondary)
                .padding(.top, 6)
            Text(text).font(.callout)
            Spacer()
        }
    }

    // MARK: - after

    private func finished(_ r: Uninstall.Report) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: r.everythingWorked ? "checkmark.circle.fill"
                                                     : "exclamationmark.triangle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(r.everythingWorked ? .green : .orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text(r.everythingWorked ? "Rewisp is uninstalled" : "Mostly uninstalled")
                        .font(.title3.weight(.semibold))
                    Text(r.everythingWorked
                         ? "Thanks for trying it."
                         : "A couple of things need doing by hand.")
                        .font(.callout).foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 7) {
                done("Background helper stopped", r.stoppedHelper)
                done("Startup items removed", r.removedAgents > 0)
                done("Screen Recording permission released", r.resetPermissions)
                if r.dataTrashed { done("Memories moved to the Trash", true) }
                done("Rewisp moved to the Trash", r.appTrashed)
            }
            .padding(13)
            .background(.quaternary.opacity(0.3),
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            ForEach(r.failures, id: \.self) { f in
                Label(f, systemImage: "exclamationmark.triangle")
                    .font(.caption).foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(r.dataTrashed
                 ? "Rewisp will quit now. Empty the Trash when you're sure."
                 : "Rewisp will quit now. Your memories are still in ~/Rewisp if you come back.")
                .font(.caption).foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Spacer()
                Button("Quit Rewisp") { NSApp.terminate(nil) }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(22)
    }

    private func done(_ text: String, _ ok: Bool) -> some View {
        HStack(spacing: 9) {
            Image(systemName: ok ? "checkmark.circle.fill" : "xmark.circle")
                .foregroundStyle(ok ? .green : .secondary)
                .font(.callout)
            Text(text).font(.callout)
            Spacer()
        }
    }
}
