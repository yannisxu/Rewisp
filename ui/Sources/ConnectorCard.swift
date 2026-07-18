import SwiftUI
import AppKit

// Settings → Connect agents. Hand Rewisp's memory to Claude Desktop, Claude Code,
// or any MCP client. Live connection status, three setup paths (one-click for
// Desktop), an animated demo, and a copy-paste test prompt.
struct ConnectorSection: View {
    @State private var status: RewispAPI.MCPStatus?
    @State private var method = Method.desktop
    @State private var installedFlash = false
    @State private var exposeVault = false

    enum Method: String, CaseIterable, Identifiable {
        case desktop = "Claude Desktop", code = "Claude Code", manual = "Other client"
        var id: String { rawValue }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            statusBanner
            ConnectorDemo()
            methodCard
            testCard
            privacyCard
        }
        .task {
            await refresh()
            // poll so "Connected" lights up the moment an agent first queries
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(3))
                await refresh()
            }
        }
    }

    @MainActor private func refresh() async {
        if let s = try? await RewispAPI.get("mcp-status", as: RewispAPI.MCPStatus.self) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { status = s }
            exposeVault = s.expose_vault ?? false
        }
    }

    // ── live status ──
    private var statusBanner: some View {
        let connected = status?.connected == true
        return HStack(spacing: 14) {
            ZStack {
                Circle().fill(connected ? Color.green.opacity(0.18) : Color.secondary.opacity(0.12))
                    .frame(width: 44, height: 44)
                Circle().fill(connected ? Color.green : Color.secondary)
                    .frame(width: 12, height: 12)
                    .shadow(color: connected ? .green : .clear, radius: 6)
                if connected {
                    Circle().stroke(Color.green.opacity(0.5), lineWidth: 2)
                        .frame(width: 44, height: 44)
                        .scaleEffect(installedFlash ? 1.25 : 1).opacity(installedFlash ? 0 : 1)
                        .animation(.easeOut(duration: 1.4).repeatForever(autoreverses: false), value: installedFlash)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(connected ? "Connected" : "Not connected yet")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(connected ? .primary : .secondary)
                Text(statusDetail).font(.callout).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .background(.quaternary.opacity(0.28), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16)
            .strokeBorder(connected ? Color.green.opacity(0.35) : Color.white.opacity(0.06)))
        .onAppear { installedFlash = true }
    }

    private var statusDetail: String {
        guard let s = status, s.connected else {
            return "Set up an agent below, then ask it about your memory."
        }
        var bits: [String] = []
        if let c = s.client { bits.append(c) }
        bits.append("\(s.calls ?? 0) queries")
        if let t = s.last_seen { bits.append("last " + relativeAgo(t)) }
        return bits.joined(separator: " · ")
    }

    // ── setup methods ──
    private var methodCard: some View {
        Card {
            CardHeader(title: "Set it up", symbol: "wrench.and.screwdriver.fill")
            Picker("", selection: $method) {
                ForEach(Method.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented).labelsHidden()

            switch method {
            case .desktop: desktopMethod
            case .code: commandMethod(status?.cli_command ?? "loading…",
                                      hint: "Paste in Terminal. Then just talk to Claude Code.")
            case .manual: commandMethod(status?.json_block ?? "loading…",
                                        hint: "Merge into your client's MCP config (mcpServers).", mono: true, tall: true)
            }
        }
    }

    private var desktopMethod: some View {
        VStack(alignment: .leading, spacing: 10) {
            StepRow(1, "Click the button — Rewisp writes the config for you.")
            StepRow(2, "Quit and reopen Claude Desktop.")
            StepRow(3, "It appears under Settings → Connectors as “rewisp.”")
            HStack(spacing: 10) {
                Button {
                    Task { @MainActor in
                        _ = try? await RewispAPI.post("mcp/install-desktop")
                        withAnimation(.spring) { installedFlash = true }
                        await refresh()
                    }
                } label: {
                    Label(status?.desktop_installed == true ? "Re-add to Claude Desktop" : "Add to Claude Desktop",
                          systemImage: "plus.app.fill")
                }
                .buttonStyle(.borderedProminent)
                if status?.desktop_installed == true {
                    Label("Config written", systemImage: "checkmark.circle.fill")
                        .font(.caption).foregroundStyle(.green)
                }
            }
            .padding(.top, 2)
        }
    }

    private func commandMethod(_ text: String, hint: String, mono: Bool = true, tall: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                ScrollView(.horizontal, showsIndicators: false) {
                    Text(text).font(.caption.monospaced())
                        .textSelection(.enabled)
                        .padding(10)
                        .frame(maxWidth: .infinity, minHeight: tall ? 92 : 0, alignment: .topLeading)
                }
                .background(.black.opacity(0.25), in: RoundedRectangle(cornerRadius: 8))
                CopyButton(text: text, label: "Copy")
            }
            Text(hint).font(.caption).foregroundStyle(.tertiary)
        }
    }

    // ── test it ──
    private var testCard: some View {
        Card {
            CardHeader(title: "Test the connection", symbol: "checkmark.seal.fill")
            Text("Once set up, ask your agent something only Rewisp knows:")
                .font(.callout).foregroundStyle(.secondary)
            ForEach(["What did I work on yesterday?",
                     "What have I promised this week?",
                     "What changed on the last page I looked at?"], id: \.self) { q in
                HStack(spacing: 8) {
                    Image(systemName: "quote.opening").font(.caption2).foregroundStyle(Theme.wisp)
                    Text(q).font(.callout).textSelection(.enabled)
                    Spacer()
                    CopyButton(text: q, compact: true)
                }
                .padding(.vertical, 2)
            }
            Text("If it answers from your screen history, you're connected. The banner above turns green the moment it first queries.")
                .font(.caption).foregroundStyle(.tertiary)
        }
    }

    private var privacyCard: some View {
        Card {
            CardHeader(title: "What agents can see", symbol: "lock.shield.fill")
            bullet("Read-only", "Agents can search and read your memory — never write, change, or delete it.")
            bullet("Fully local", "Runs over a local pipe. No network listener, no cloud. It never spends your AI subscriptions.")
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
    }

    private func bullet(_ title: String, _ body: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green).font(.callout)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.callout.weight(.medium))
                Text(body).font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct StepRow: View {
    let n: Int; let text: String
    init(_ n: Int, _ text: String) { self.n = n; self.text = text }
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(n)").font(.caption.weight(.bold)).foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(Circle().fill(Theme.accent))
            Text(text).font(.callout).foregroundStyle(.secondary)
            Spacer()
        }
    }
}

// A looping mini demo: an agent asks, Rewisp's tool lights up, the answer flows.
private struct ConnectorDemo: View {
    @State private var phase = 0   // 0 ask, 1 tool, 2 answer
    private let tools = ["search_memory", "get_promises", "get_context"]
    @State private var toolIdx = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // agent question
            HStack {
                Spacer(minLength: 40)
                Text("What did I promise this week?")
                    .font(.callout).padding(.horizontal, 14).padding(.vertical, 9)
                    .background(Theme.accent.opacity(0.9), in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
            }
            // rewisp tool call
            HStack(spacing: 8) {
                Image(systemName: "point.3.filled.connected.trianglepath.dotted")
                    .foregroundStyle(Theme.wisp)
                Text("rewisp").font(.caption.weight(.semibold))
                Text("· \(tools[toolIdx])").font(.caption.monospaced()).foregroundStyle(.secondary)
                if phase == 1 { ProgressView().controlSize(.small).scaleEffect(0.7) }
                Spacer()
            }
            .opacity(phase >= 1 ? 1 : 0.25)
            .animation(.spring(response: 0.3), value: phase)
            // answer
            if phase >= 2 {
                HStack {
                    Text("You owe Dana the design doc (due Fri) · waiting on Alex's contract.")
                        .font(.callout)
                        .padding(.horizontal, 14).padding(.vertical, 9)
                        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 14))
                    Spacer(minLength: 40)
                }
                .transition(.opacity.combined(with: .offset(y: 6)))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [Theme.accent.opacity(0.08), .clear],
                           startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.white.opacity(0.06)))
        .task {
            while !Task.isCancelled {
                withAnimation { phase = 0 }
                try? await Task.sleep(for: .milliseconds(900))
                withAnimation { phase = 1 }
                try? await Task.sleep(for: .milliseconds(1100))
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { phase = 2 }
                try? await Task.sleep(for: .seconds(3))
                toolIdx = (toolIdx + 1) % tools.count
            }
        }
    }
}

private func relativeAgo(_ iso: String) -> String {
    let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd HH:mm:ss"
    f.timeZone = TimeZone(identifier: "UTC")
    guard let d = f.date(from: iso) else { return "just now" }
    let s = Int(Date().timeIntervalSince(d))
    if s < 60 { return "just now" }
    if s < 3600 { return "\(s/60)m ago" }
    if s < 86400 { return "\(s/3600)h ago" }
    return "\(s/86400)d ago"
}
