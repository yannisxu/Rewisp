import SwiftUI
import AppKit

// Settings → Your data: connect Rewisp's memory to external AI agents over MCP.
// Read-only, local stdio, Vault excluded by default. One copyable command.
struct ConnectorCard: View {
    @State private var exposeVault = false
    @State private var copied = false

    // The daemon package lives in the app bundle (installed) or the source repo.
    private var daemonDir: String {
        if let res = Bundle.main.resourceURL?.appendingPathComponent("daemon"),
           FileManager.default.fileExists(atPath: res.path) {
            return res.path
        }
        return NSHomeDirectory() + "/Code/Rewisp"
    }

    private var command: String {
        "claude mcp add rewisp -e PYTHONPATH=\"\(daemonDir)\" -- python3 -m rewisp mcp"
    }

    var body: some View {
        Card {
            CardHeader(title: "Connect to AI agents", symbol: "point.3.filled.connected.trianglepath.dotted")
            Text("Let Claude Code, Claude Desktop, or any MCP client query your screen memory — search moments, diff pages, read your promises. Read-only, fully local, and it never spends your AI subscriptions.")
                .font(.callout).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Text(command)
                    .font(.caption.monospaced())
                    .lineLimit(1).truncationMode(.middle)
                    .padding(.horizontal, 10).padding(.vertical, 7)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.black.opacity(0.25), in: RoundedRectangle(cornerRadius: 8))
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(command, forType: .string)
                    withAnimation { copied = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { withAnimation { copied = false } }
                } label: {
                    Label(copied ? "Copied" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                        .font(.caption)
                }
                .controlSize(.small)
            }

            Toggle(isOn: $exposeVault) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Also expose the Vault").font(.callout)
                    Text("Off by default — your identity documents (resume, addresses) stay private. Screen memory is always shared.")
                        .font(.caption).foregroundStyle(.tertiary)
                }
            }
            .toggleStyle(.switch)
            .onChange(of: exposeVault) {
                Task { _ = try? await RewispAPI.post("settings", body: ["mcp_expose_vault": exposeVault]) }
            }
        }
        .task {
            if let s = try? await RewispAPI.get("settings", as: RewispAPI.Settings.self) {
                exposeVault = s.mcp_expose_vault ?? false
            }
        }
    }
}
