# Changelog

All notable changes to this project will be documented in this file.

## Unreleased

### Added

- Repo scaffolded: `CLAUDE.md`, `ARCHITECTURE.md`, `README.md`,
  `LICENSE.md` (BSD 2-Clause), `CHANGELOG.md`
- `flake.nix`/`flake.lock` — pre-commit tooling (`nixpkgs`,
  `pre-commit-hooks`); same `nixfmt`/`markdownlint-cli2`/`commitlint` hook
  set as nixie, installed via `nix develop`
- `.commitlintrc.yaml`/`.markdownlint-cli2.yaml` — copied from nixie so the
  new hooks have rules to enforce
- `.gitignore` — `/.direnv`, `/result`, `/.pre-commit-config.yaml`,
  `/.claude`, matching nixie's
- `alberth/` — nixie's `home/alberth` migrated here (flattened, dropping
  the redundant `home/` prefix), with its full git history carried over
  via `git filter-repo --path home/alberth/ --path-rename
  home/alberth/:alberth/` and merged in with `--allow-unrelated-histories`
- `flake.nix` — added `home-manager`, `nix-secrets` (`flake = false`),
  `nvf`, `qmd`, `stylix` inputs (previously pre-commit-tooling-only),
  making this a real, standalone-usable flake
- `users.nix` — local `description`/`email`/`gpgSigningKey` metadata;
  `alberth/default.nix`, `alberth/common/{git,gpg,shells}.nix` repointed
  at it instead of nixie's own `users.nix` (which they could no longer
  reach once migrated into a separate repo)
- `flake.nix` — `homeModules.<name>` outputs (`alberth`, `alberth-darwin`,
  `alberth-nixos`, `alberth-nvf`, `alberth-codex`, `alberth-darwintron`,
  `alberth-gammu`) for nixie (or any flake) to import, and
  `homeConfigurations."alberth@{codex,darwintron,gammu}"` for standalone
  `home-manager switch --flake` use, independent of nixie.
  `alberth@gammu` omits `alberth/nixos.nix` (needs `osConfig`, only
  defined when home-manager runs as a NixOS/darwin module), so it's a
  best-effort subset of nixie's actual `gammu` deploy

### Changed

- `CLAUDE.md` — populated (was empty): project directives adapted from
  nixie's own `CLAUDE.md` — standalone-vs-integrated usage, the one-way
  dependency rule (never reach back into nixie), the current `alberth/`
  layout, `homeModules` output naming rationale, and commit/release
  conventions matching nixie
- `ARCHITECTURE.md` — populated (was empty, then a placeholder): now
  documents the two usage modes, the one-way dependency rule, the
  `osConfig`/NixOS-integration caveat, and the flake outputs table —
  nixie's own `ARCHITECTURE.md` remains the authoritative cross-repo
  picture, this is a thinner self-focused view
- `README.md` — documents standalone (`home-manager switch --flake`) and
  integrated (via nixie) usage, replacing the earlier scaffold notice
