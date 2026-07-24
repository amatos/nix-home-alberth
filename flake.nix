{
  description = "nix-home-alberth — standalone home-manager configurations, usable with or without nixie";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1"; # Unstable Nixpkgs (use 0 for stable)
    nixpkgs-stable.url = "https://flakehub.com/f/NixOS/nixpkgs/0"; # Stable Nixpkgs (use 0.1 for unstable)

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05"; # pin to same release as nixpkgs
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-secrets = {
      url = "github:amatos/nix-secrets";
      flake = false; # plain git repo, not a flake
    };

    nvf = {
      url = "github:notashelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    qmd = {
      url = "github:tobi/qmd";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    direnv-instant = {
      url = "github:Mic92/direnv-instant";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      nixpkgs-stable,
      home-manager,
      nix-secrets,
      nvf,
      qmd,
      stylix,
      direnv-instant,
      pre-commit-hooks,
      ...
    }:
    let
      inherit (nixpkgs) lib;

      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = lib.genAttrs supportedSystems;

      # Shared home-manager plugin modules — matches nixie's own
      # modules/nixos/home-manager.nix / hosts/darwin/common-darwin.nix
      # sharedModules list, so integrated and standalone use behave the same.
      sharedHomeModules = [
        nvf.homeManagerModules.default
        qmd.homeModules.default
        stylix.homeModules.stylix
        direnv-instant.homeModules.direnv-instant
      ];

      # Ready-to-use standalone `home-manager switch --flake .#<name>` configs
      # for real machines. alberth/nixos.nix is deliberately excluded here: it
      # reads `osConfig`, a special arg only provided when home-manager runs
      # as a NixOS/darwin module (as nixie does) — plain
      # `homeManagerConfiguration` never defines it, so including that module
      # here would fail to evaluate. Standalone `alberth@gammu` is therefore
      # a best-effort subset of what nixie actually deploys (missing krb5,
      # pinentry-tty, and the syncthing-user-unit mask that nixos.nix adds),
      # not a full mirror.
      mkHome =
        {
          system,
          hostModule,
          darwin ? false,
          # Matches this host's channel in nixie's own flake.nix — gammu/codex
          # track nixpkgs (unstable), everything else tracks nixpkgs-stable.
          nixpkgsSource ? nixpkgs-stable,
        }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgsSource {
            inherit system;
            config.allowUnfree = true; # 1Password, etc. — nixie sets this via
            # nixpkgs.config.allowUnfree at the NixOS/darwin module level,
            # which has no effect in a standalone homeManagerConfiguration.
          };
          extraSpecialArgs = { inherit nix-secrets; };
          modules =
            sharedHomeModules
            ++ [
              ./alberth
              ./alberth/nvf.nix
            ]
            ++ lib.optional darwin ./alberth/darwin
            ++ [ hostModule ];
        };

      # Pre-commit hooks — shared between checks output and devShell shellHook.
      # Running `nix develop` installs the hooks into .git/hooks automatically.
      # Kept in sync with nixie's own flake.nix hook set (nixfmt, markdownlint-cli2,
      # commitlint) — see nixie's CLAUDE.md/ARCHITECTURE.md for the shared-conventions
      # rationale.
      preCommitCheck = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            nixfmt = {
              enable = true;
              package = pkgs.nixfmt;
            };

            markdownlint-cli2 = {
              enable = true;
              name = "markdownlint-cli2";
              entry = "${pkgs.markdownlint-cli2}/bin/markdownlint-cli2 **/*.md";
              language = "system";
              pass_filenames = false;
              always_run = true;
            };

            commitlint = {
              enable = true;
              name = "commitlint";
              entry = "${pkgs.commitlint}/bin/commitlint --edit";
              language = "system";
              stages = [ "commit-msg" ];
              pass_filenames = false;
            };
          };
        }
      );
    in
    {
      # Importable building blocks — consumed by nixie's own
      # home-manager.users.<user>.imports, or by any other flake/system.
      # Naming matches DeterminateSystems' flake-schemas convention
      # (nixosModules/darwinModules/homeModules), not nvf's older
      # homeManagerModules name (deprecated by stylix in favor of
      # homeModules — see CLAUDE.md "Layout").
      homeModules = {
        alberth = ./alberth; # cross-platform base
        alberth-darwin = ./alberth/darwin; # darwin-integration overlay
        alberth-nixos = ./alberth/nixos.nix; # NixOS-integration overlay (needs osConfig)
        alberth-nvf = ./alberth/nvf.nix; # neovim via nvf
        alberth-codex = ./alberth/codex.nix; # codex host overlay
        alberth-darwintron = ./alberth/darwintron.nix; # darwintron host overlay
        alberth-gammu = ./alberth/gammu.nix; # gammu host overlay
      };

      homeConfigurations = {
        "alberth@codex" = mkHome {
          system = "aarch64-darwin";
          hostModule = ./alberth/codex.nix;
          darwin = true;
          nixpkgsSource = nixpkgs;
        };
        "alberth@darwintron" = mkHome {
          system = "aarch64-darwin";
          hostModule = ./alberth/darwintron.nix;
          darwin = true;
        };
        "alberth@gammu" = mkHome {
          system = "x86_64-linux";
          hostModule = ./alberth/gammu.nix;
          nixpkgsSource = nixpkgs;
        };
      };

      # Canonical formatter — enables `nix fmt` and `nix run .#formatter -- --check`
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);

      # Expose pre-commit check so `nix flake check` verifies formatting too
      checks = forAllSystems (system: {
        pre-commit = preCommitCheck.${system};
      });

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            name = "nix-home-alberth";
            packages = [ pkgs.nixfmt ];
            # Installs git hooks into .git/hooks when entering the devShell
            inherit (preCommitCheck.${system}) shellHook;
          };
        }
      );
    };
}
