import AppKit
import Foundation

// Where the app is running FROM matters more here than in a normal Mac app,
// because Rewisp writes launchd plists that hard-code the path to its bundled
// Python. Launch the copy sitting inside the mounted DMG and those plists point
// at "/Volumes/Rewisp 4/…" — a mount point that disappears on eject and never
// comes back. The helper then dies for good, and because macOS ties Screen
// Recording grants to a binary's path, the permission the user already granted
// does not carry over to the copy they later drag into Applications.
//
// So: refuse to set up shop anywhere but /Applications, and offer to move there.
enum InstallLocation {

    static var bundleURL: URL { Bundle.main.bundleURL }
    static var path: String { bundleURL.path }

    /// Gatekeeper runs quarantined apps from a read-only shadow mount under
    /// /private/var/folders/…/AppTranslocation/. The app cannot see its own real
    /// location from there, and nothing written about that path stays valid.
    static var isTranslocated: Bool { path.contains("/AppTranslocation/") }

    /// Running straight out of a mounted disk image.
    static var isOnMountedVolume: Bool { path.hasPrefix("/Volumes/") }

    static var isInApplications: Bool {
        path.hasPrefix("/Applications/")
            || path.hasPrefix(NSHomeDirectory() + "/Applications/")
    }

    /// Only distributed builds are policed. A dev build (`swiftc` output with no
    /// bundled runtime) legitimately runs from the repo, and nagging there would
    /// make the app unusable to develop on.
    static var shouldEnforce: Bool { Setup.selfContained && !isInApplications }

    static let destination = URL(fileURLWithPath: "/Applications/Rewisp.app")

    /// Ask to relocate, then do it and relaunch. Returns true when the app is on
    /// its way out (moved and relaunching, or the user chose to quit), meaning the
    /// caller must stop initializing — in particular it must NOT provision the
    /// helper, or it writes the very paths this exists to prevent.
    @MainActor
    static func enforceIfNeeded() -> Bool {
        guard shouldEnforce else { return false }

        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "Move Rewisp to Applications?"
        alert.informativeText = """
        Rewisp is running from \(placeDescription). It needs to live in your \
        Applications folder to keep working: its background helper is started by \
        macOS from wherever the app sits, and \(breakageDescription)

        Rewisp can move itself there now and reopen.
        """
        alert.addButton(withTitle: "Move to Applications")
        alert.addButton(withTitle: "Quit")
        alert.alertStyle = .warning

        guard alert.runModal() == .alertFirstButtonReturn else {
            NSApp.terminate(nil)
            return true
        }

        do {
            try moveToApplications()
        } catch {
            let fail = NSAlert()
            fail.messageText = "Couldn't move Rewisp automatically"
            fail.informativeText = """
            \(error.localizedDescription)

            Drag Rewisp into your Applications folder yourself, then open it \
            from there.
            """
            fail.addButton(withTitle: "OK")
            fail.runModal()
            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: "/Applications")
            NSApp.terminate(nil)
            return true
        }

        relaunchFromApplications()
        return true
    }

    private static var placeDescription: String {
        if isTranslocated { return "a temporary read-only location" }
        if isOnMountedVolume { return "the disk image you downloaded" }
        return "outside your Applications folder"
    }

    private static var breakageDescription: String {
        isOnMountedVolume || isTranslocated
            ? "that location disappears as soon as you eject the disk image."
            : "moving the app later would break it."
    }

    private static func moveToApplications() throws {
        let fm = FileManager.default

        // Replace any previous install. Copy rather than move: the source may be
        // a read-only disk image, and leaving the DMG untouched is what people
        // expect anyway.
        if fm.fileExists(atPath: destination.path) {
            try fm.removeItem(at: destination)
        }
        try fm.copyItem(at: bundleURL, to: destination)

        // Strip the download quarantine flag so the copy opens without a second
        // Gatekeeper block — the user already cleared it to get this far.
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
        p.arguments = ["-dr", "com.apple.quarantine", destination.path]
        p.standardOutput = FileHandle.nullDevice
        p.standardError = FileHandle.nullDevice
        try? p.run()
        p.waitUntilExit()
    }

    private static func relaunchFromApplications() {
        let cfg = NSWorkspace.OpenConfiguration()
        cfg.createsNewApplicationInstance = true
        NSWorkspace.shared.openApplication(at: destination, configuration: cfg) { _, _ in
            DispatchQueue.main.async { NSApp.terminate(nil) }
        }
    }
}
