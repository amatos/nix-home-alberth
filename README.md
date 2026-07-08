# nixie-homes

[Home-manager](https://github.com/nix-community/home-manager) configuration for alberth,
usable with or without [nixie](https://github.com/amatos/nixie).

## Standalone usage

On any machine with Nix — no NixOS, no nix-darwin, no `nixie` required:

```bash
home-manager switch --flake github:amatos/nixie-homes#alberth@codex
# or: alberth@darwintron, alberth@gammu
```

`alberth@gammu` is a best-effort subset of what `nixie` actually deploys to `gammu` (missing
`krb5`, `pinentry-tty`, and a syncthing-unit mask normally added by the NixOS-integration
overlay, which needs to run as an actual NixOS home-manager module — see `ARCHITECTURE.md`).

## Integrated usage (via nixie)

`nixie` declares this repo as a flake input and imports individual `homeModules.<name>`
outputs into each host's `home-manager.users.alberth.imports` — see `nixie`'s own
`CLAUDE.md` ("home-manager host overlays"). No action needed here beyond keeping
`alberth/` and `flake.nix`'s `homeModules`/`homeConfigurations` entries in sync when
adding a new host overlay (see `CLAUDE.md` "Layout").

---

## Development shell

A devShell is provided for this repo's own tooling (`nixfmt`, plus the pre-commit hooks below):

```bash
cd /path/to/nixie-homes
nix develop
```

This installs `nixfmt`/`markdownlint-cli2`/`commitlint` pre-commit hooks into `.git/hooks`,
matching nixie's own hook set (`flake.nix`, `.commitlintrc.yaml`, `.markdownlint-cli2.yaml`).
