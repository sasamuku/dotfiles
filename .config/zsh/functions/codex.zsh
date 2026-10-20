# Keep the executable lookup separate from the functions to avoid recursion.
codex() {
    if [[ ! -f "$HOME/.config/codex-accounts/accounts.json" ]]; then
        command codex "$@"
        return $?
    fi
    python3 "$HOME/.local/bin/cxs" run "${commands[codex]:?codex executable not found}" "$@"
}

cxs() {
    python3 "$HOME/.local/bin/cxs" switch "${commands[codex]:?codex executable not found}" "$@"
}
