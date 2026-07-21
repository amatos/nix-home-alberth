# Changelog

All notable changes to this project will be documented in this file.

## Unreleased

### Added

- `alberth/scripts/update-flake.py`, deployed to `~/.local/bin/update-flake.py`
  — resets a repo's `flake-update` branch to the tip of `origin/main`,
  updates one flake input (2nd arg) or all of them (no 2nd arg), and
  commits and force-pushes `flake.lock` only if it changed, restoring the
  previous branch and any stashed changes afterward. Defaults to the `nixie`
  repo (`~/Projects/nixie`, `github:amatos/nixie`); an optional 1st arg targets
  any other `~/Projects/<repo>` checkout of `github:amatos/<repo>` instead.
  `flake-update` is reset (not merged) from `origin/main` and force-pushed
  on every run — a disposable single-commit branch, not an accumulating
  history; a future CI workflow will trigger on pushes to it and merge into
  `main` once checks pass.
- `alberth/common/zed/settings.json` — `agent_servers` entries for `gemini`,
  `github-copilot-cli`, and `codex-acp` (all `registry`-sourced), alongside
  the existing `claude-acp` entry, so Zed's Agent Panel can drive those ACP
  agents too.

### Changed

- `alberth/scripts/npbs-all.sh` — added `muninn` to the list of remote hosts.
- `alberth/common/shells.nix` — `nixflakeup` alias renamed to `nixieflakeup`
  and now calls `update-flake.py nixie` instead of an inline `nix flake
  update` one-liner; see "Added" above.
- `alberth/common/packages.nix` — added `python3` (needed by
  `update-flake.py`).
- `alberth/common/atuin.nix` — `ai.enabled = false` in `programs.atuin.settings`,
  disabling atuin's `?`-at-empty-prompt keybind (Atuin AI / natural language
  mode) that atuin's shell integration binds by default.

### Removed

- `alberth/codex.nix` — removed the `muninn` SSH `Host` stanza; the old muninn host is
  retired and its name is being recycled for a new, unrelated host.

---

## 26.07.04

### Added

- `.github/workflows/ci.yml` — new CI, `verify-signed-commits` job fails the
  build if any commit in a push/PR has no GPG signature (`git log
  --pretty=%G?`).

### Changed

- `CLAUDE.md` "Conventions" — now requires GPG-signed commits, matching
  nixie's requirement (previously only release tags were documented as
  signed), and documents the new CI enforcement.

---

## 26.07.03

### Removed

- `alberth/common/shells.nix` — dropped the `ragenix` shell alias
  (`ragenix -i ~/.config/age/yubikey-identity.txt`) from `home.shellAliases`,
  applied fleet-wide across bash/zsh/fish.

### Added

- `alberth/common/shells.nix` — `ll`/`llt`/`lls`/`ll@` (eza), `ta`/`tl`/`tn`
  (tmux), and `tgz` shell aliases, folded in from a hand-maintained
  `~/.config/zsh/aliases.zsh` that wasn't actually sourced by the managed
  `.zshrc`/`.zshenv` and was therefore dead. eza/tmux are enabled fleet-wide
  (`tools.nix`), so the original file's existence guards were dropped.
- `alberth/darwin/default.nix` — `tailscale` alias (assumes `/Applications`,
  so it lives here rather than in the cross-platform `shells.nix`).
- `alberth/common/latexmk.nix` — deploys `~/.config/latexmk/latexmkrc` via
  `xdg.configFile` (latexmk has no home-manager module of its own).
- `alberth/common/git.nix` — ports the remaining dotfiles-era git config
  into `programs.git`: the ~90-alias set (`programs.git.settings.alias`),
  the Dracula `[color]`/`[color "branch"]`/etc. blocks (plain git
  coloring, not delta — see Fixed below), and `commit.template` (via a new
  `xdg.configFile."git/gitmessage"`). `programs.git.ignores`/`attributes`
  now also carry the full pattern sets previously in the unmanaged
  `gitignore`/`gitattributes` files. Not ported: `config.delta-themes`, a
  513-line vendored copy of delta's own community `themes.gitconfig` (no
  "dracula" theme among its 17); delta isn't installed or enabled anywhere
  in the fleet, so it was dead weight. If delta gets enabled later, source
  its theme from draculatheme.com/delta directly instead, matching this
  project's other Dracula theming.
- `alberth/common/zed.nix` — deploys `~/.config/zed/settings.json` as an
  out-of-store symlink (`config.lib.file.mkOutOfStoreSymlink`) to
  `alberth/common/zed/settings.json` in this repo's working copy, instead
  of a plain `xdg.configFile` `text =` block. Zed settings are normally
  hand-edited via the app itself (command palette: "zed: open settings");
  a store symlink would make that read-only. Requires nix-home-alberth
  checked out at `~/Projects/nix-home-alberth` on any machine consuming
  this module.
- `alberth/default.nix` — deploys `~/.local/bin/$` and `~/.local/bin/extract`
  (`alberth/scripts/dollar.sh`/`extract.sh`), and `~/.editorconfig`, ported
  from the dotfiles-era chezmoi repo.
- `alberth/darwin/default.nix` — deploys `~/.local/bin/control-dock.sh`
  (dock autohide toggle) and `~/Library/Application Scripts/
  com.sindresorhus.Velja/open.sh` (Velja's URL-open handler), both
  macOS-only, ported from the dotfiles-era chezmoi repo.
- `alberth/common/gpg.nix` — ports the remaining settings from the
  dotfiles-era `~/.gnupg/gpg.conf` (drduh/YubiKey-Guide) not already
  covered by home-manager's `programs.gpg` built-in defaults: `charset`,
  `no-greeting`, `require-secmem`, `armor`, `use-agent`,
  `auto-key-locate`, `auto-key-retrieve`, and `default-key`/`trusted-key`
  (wired to `user.gpgSigningKey` rather than a hardcoded fingerprint). The
  original file's `throw-keyids` was deliberately *not* ported — it
  strips recipient key IDs from encrypted messages, which also breaks
  Mailvelope, and isn't needed.

### Changed

- `alberth/common/starship.nix` — replaced the `mantle` color with `comment`
- `alberth/gammu.nix` — renamed the `steamup` systemd user unit to `steam`
  (`systemd.user.services.steam`); update any `systemctl --user
  start/stop/restart steamup` / `journalctl --user -u steamup` usage to
  `steam`.

### Fixed

- `alberth/common/starship.nix` — the `dracula` palette's `crust`/`base`/
  `mantle` entries (`#11111b`/`#1e1e2e`/`#181825`) were Catppuccin Mocha
  values, not Dracula's — likely copy-pasted from another palette block.
  Replaced with the actual palette from
  `github.com/dracula/starship/starship.theme.toml`: renamed `crust` to
  `background` (`#282a36`, Dracula's real background shade) and updated
  every `fg:crust` segment reference; dropped `base`, `mantle`, and `blue`
  (`#644ac9`, not part of the official palette), all three unused outside
  the palette declaration itself.
- `alberth/common/git.nix` — the old hand-placed `~/.config/git/gitignore`
  and `gitattributes` files were misnamed relative to git's actual default
  lookup paths, `~/.config/git/ignore` and `~/.config/git/attributes`
  (no leading `git`), so neither file was ever actually read by git. Also
  dropped a duplicate `ls`/`las` alias pair: both were defined twice with
  different meanings, and git's ini parser silently let the second
  (unrelated) definition win, so the first pair was already dead in
  practice.
- `alberth/common/stylix.nix` — disabled `stylix.targets.vencord`. Vencord
  isn't installed anywhere in the fleet (BetterDiscord is the Discord mod
  actually used), so this target only ever produced an orphaned theme file
  under `~/.config/Vencord` with nothing to consume it.

---

## 26.07.02

### Added

- `.envrc` (`use flake`) — direnv now loads the devShell automatically on
  `cd`; documented in README "Development shell".
- `direnv-instant` flake input (`github:Mic92/direnv-instant`), added to
  `sharedHomeModules` and enabled via `programs.direnv-instant.enable = true`
  in `alberth/common/tools.nix` — runs direnv in a background daemon so the
  shell prompt returns immediately instead of blocking on `.envrc`.
- `alberth/nixify` — empty bash script scaffold for future work.

### Changed

- `alberth/common/tools.nix` — disabled `programs.direnv`'s own
  bash/zsh/fish/nushell shell hook integrations (`nix-direnv` itself stays
  enabled); `direnv-instant` now owns the shell hook for all four shells.
- `flake.nix` — dropped the unused `self` function arg flagged by nixd.

---

## 26.07.01

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

- `flake.nix` — dropped `x86_64-darwin` from `supportedSystems`; that
  platform/architecture combination is being deprecated. No
  `homeConfigurations` entry ever targeted it, so this only affects the
  dev-tooling matrix (`devShells`/`checks`/`formatter`)
- `alberth/common/starship.nix` — updated prompt format to use `╭─`/`╰─`
  line breaks and `mantle` palette for a consistent look across terminals
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
