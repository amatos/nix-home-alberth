# Architecture

This is a thinner, self-focused view. [nixie](https://github.com/amatos/nixie)'s own
`ARCHITECTURE.md` has the authoritative cross-repo picture (all four repos, the
security/reuse reasoning, invariants); this document only covers how nixie-homes
itself is put together and how it's consumed.

## Two ways to use this repo

1. **Standalone** — `home-manager switch --flake github:amatos/nixie-homes#<user>@<host>`
   on any machine with Nix. No NixOS, no nix-darwin, no `nixie` required. Uses the
   `homeConfigurations."<user>@<host>"` flake output, built with this repo's own
   `nixpkgs`/`home-manager`/`nvf`/`qmd`/`stylix` inputs and `nix-secrets` (`flake =
   false`, for the age identity file).
2. **Integrated into `nixie`** — `nixie` declares this repo as a real flake input
   (`inputs.nixie-homes`, with `nixpkgs`/`home-manager`/`nix-secrets`/`nvf`/`qmd`/
   `stylix` all `.follows`-pinned to its own), and imports individual
   `homeModules.<name>` outputs into `home-manager.users.alberth.imports` on each
   host. `nixie` never touches this repo's raw files by path — only its named flake
   outputs.

Both modes build from the exact same `alberth/` source; there's no fork or
duplication between them.

## The one-way dependency

`nixie` depends on `nixie-homes`; `nixie-homes` never depends on `nixie`. Concretely:

- No relative-path import in `alberth/` crosses the repo boundary (e.g. no
  `../../nixie/users.nix`). This repo has its own local `users.nix` for
  `email`/`gpgSigningKey`/`description` instead — see `CLAUDE.md` "What this is" for
  why that's duplicated on purpose rather than shared.
- If a module here needs data only `nixie` has, it gets threaded through
  `extraSpecialArgs` from `nixie`'s own `home-manager.extraSpecialArgs` (the consuming
  side) — never by this repo reaching backward into `nixie`.
- `nixie-homes` can be fetched, evaluated, and built with zero knowledge of `nixie`
  existing at all (verify with `nix build
  '.#homeConfigurations."alberth@codex".activationPackage' --dry-run` from a fresh
  checkout).

## `osConfig` and the NixOS/darwin-integration modules

`alberth/nixos.nix` reads `osConfig.networking.hostName` to auto-import a matching
`alberth/<hostname>.nix` overlay. `osConfig` is a special arg only defined when
home-manager runs as a NixOS/darwin module (`useGlobalPkgs`/`useUserPackages`) — it
does not exist in a plain `home-manager.lib.homeManagerConfiguration`. Consequences:

- `alberth/nixos.nix` is exposed as `homeModules.alberth-nixos` for `nixie` to import,
  but is **never** included in this repo's own `homeConfigurations` (it would fail to
  evaluate standalone).
- Standalone `homeConfigurations."alberth@gammu"` is therefore a best-effort subset of
  what `nixie` actually deploys to `gammu` — missing `krb5`, `pinentry-tty`, and the
  syncthing-user-unit mask that `alberth/nixos.nix` normally adds. `alberth/gammu.nix`
  itself has no `osConfig` dependency, so it works standalone; only the NixOS-overlay
  piece is skipped.
- `alberth/darwin/` (darwin-integration overlay: pinentry-mac, Ghostty) has no
  `osConfig` dependency and works identically standalone or integrated.

## Flake outputs

| Output | Purpose |
| --- | --- |
| `homeModules.<name>` | Importable building blocks for any consuming flake |
| `homeConfigurations."<user>@<host>"` | Ready-to-use standalone configs |
| `checks` / `devShells.default` / `formatter` | Pre-commit tooling (nixfmt, markdownlint-cli2, commitlint) — same hook set as `nixie` |

See `CLAUDE.md` "Layout" for the current `homeModules`/`homeConfigurations` entries.
