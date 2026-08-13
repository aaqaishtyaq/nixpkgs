# Hosts

Each directory here represents one target machine or runner.

Guideline:
- Keep `default.nix` thin and declarative.
- Put machine-specific system state next to the host that owns it.
- Prefer shared roles and feature toggles over host-local duplication.

Current hosts:
- `powerbook`: primary macOS host.
- `github-macos`: GitHub macOS runner target that mirrors the powerbook app/config surface for cache builds.
- `github-linux`: GitHub Linux runner target.
- `linux-server`: x86_64 Linux Home Manager server target.
- `linux-vm`: x86_64 Linux Home Manager VM target.
- `ubuntu-arm`: aarch64 Linux Home Manager VM target.
- `nixos-vm`: x86_64 NixOS VM target.
- `fedora-cosmic`: x86_64 Linux Home Manager target — Fedora with COSMIC desktop, real hardware.
