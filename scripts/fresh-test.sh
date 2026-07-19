#!/bin/zsh
# Test the real download → install → first-run experience WITHOUT losing data.
#
#   ./scripts/fresh-test.sh backup    # save + tear down, ready for a clean install
#   ./scripts/fresh-test.sh restore   # put everything back exactly as it was
#
# Note: the truly clean test is a throwaway macOS user account (everything Rewisp
# touches is per-user). Use that if you also want to see the permission prompts
# from scratch — TCC grants for /Applications/Rewisp.app survive a reinstall here.
set -e

STAMP_FILE="$HOME/.rewisp-freshtest-stamp"
DATA="$HOME/Rewisp"
AGENTS="$HOME/Library/LaunchAgents"
UID_N=$(id -u)

usage() { echo "usage: $0 [backup|restore|status]"; exit 1; }

stop_everything() {
    launchctl bootout "gui/$UID_N/com.rewisp.daemon"  2>/dev/null || true
    launchctl bootout "gui/$UID_N/com.rewisp.digest"  2>/dev/null || true
    pkill -f "rewisp daemon" 2>/dev/null || true
    pkill -x Rewisp          2>/dev/null || true
    sleep 1
}

case "${1:-}" in
backup)
    BK="$HOME/Rewisp-backup-$(date +%Y%m%d-%H%M%S)"
    echo "── backing up ──"
    stop_everything

    mkdir -p "$BK"
    if [[ -d "$DATA" ]]; then
        cp -R "$DATA" "$BK/Rewisp-data"
        echo "✓ data  → $BK/Rewisp-data  ($(du -sh "$DATA" | cut -f1))"
    fi
    for p in "$AGENTS"/com.rewisp.*.plist(N); do
        cp "$p" "$BK/" && echo "✓ agent → $(basename "$p")"
    done
    # App preferences (onboarding flag, engine choice, toggles).
    defaults export com.yashmit.rewisp "$BK/prefs.plist" 2>/dev/null && echo "✓ prefs"

    echo "── tearing down for a clean first run ──"
    rm -f "$AGENTS"/com.rewisp.*.plist
    mv "$DATA" "$DATA.freshtest" 2>/dev/null || true   # hidden from the app, kept on disk
    defaults delete com.yashmit.rewisp 2>/dev/null || true   # re-triggers onboarding
    rm -rf /Applications/Rewisp.app

    echo "$BK" > "$STAMP_FILE"
    echo ""
    echo "Ready. Now do the real thing:"
    echo "  1. open https://yashmitb.github.io/Rewisp/ and click Download"
    echo "  2. install it the way a normal person would"
    echo "  3. when you're done:  $0 restore"
    ;;

restore)
    [[ -f "$STAMP_FILE" ]] || { echo "✗ no backup stamp — nothing to restore."; exit 1; }
    BK="$(cat "$STAMP_FILE")"
    [[ -d "$BK" ]] || { echo "✗ backup folder missing: $BK"; exit 1; }
    echo "── restoring from $BK ──"
    stop_everything

    rm -rf "$DATA"
    if [[ -d "$BK/Rewisp-data" ]]; then
        cp -R "$BK/Rewisp-data" "$DATA"; echo "✓ data restored"
    elif [[ -d "$DATA.freshtest" ]]; then
        mv "$DATA.freshtest" "$DATA"; echo "✓ data restored (from set-aside)"
    fi
    rm -rf "$DATA.freshtest"

    for p in "$BK"/com.rewisp.*.plist(N); do
        cp "$p" "$AGENTS/" && echo "✓ agent restored: $(basename "$p")"
    done
    [[ -f "$BK/prefs.plist" ]] && defaults import com.yashmit.rewisp "$BK/prefs.plist" && echo "✓ prefs restored"

    launchctl bootstrap "gui/$UID_N" "$AGENTS/com.rewisp.daemon.plist" 2>/dev/null || true
    launchctl bootstrap "gui/$UID_N" "$AGENTS/com.rewisp.digest.plist" 2>/dev/null || true
    open /Applications/Rewisp.app 2>/dev/null || true
    rm -f "$STAMP_FILE"
    echo ""
    echo "✓ back to normal. Backup kept at: $BK"
    ;;

status)
    echo "data dir:      $([[ -d "$DATA" ]] && du -sh "$DATA" | cut -f1 || echo 'absent')"
    echo "set aside:     $([[ -d "$DATA.freshtest" ]] && echo yes || echo no)"
    echo "agents loaded: $(launchctl list | grep -c rewisp) "
    echo "app installed: $([[ -d /Applications/Rewisp.app ]] && echo yes || echo no)"
    [[ -f "$STAMP_FILE" ]] && echo "pending restore from: $(cat "$STAMP_FILE")" || true
    ;;

*) usage ;;
esac
