# Host profiles

Host-specific Home Manager modules live here.

Guideline:
- Prefer toggling existing modules on/off (`aaqa.*.enable`).
- Keep host modules thin.
- Add host-specific settings only when truly required.

Current profiles:
- `powerbook.nix`: macOS laptop profile.
- `linux-desktop.nix`: Linux desktop profile (GUI enabled).
- `linux-server.nix`: Linux server profile (GUI disabled).
