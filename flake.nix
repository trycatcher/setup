# ~/setup/flake.nix

{
  description = "My system configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager }:
    let
      configuration = { pkgs, ... }: {

        services.nix-daemon.enable = true;
        # Necessary for using flakes on this system.
        nix.settings.experimental-features = "nix-command flakes";

        system.configurationRevision = self.rev or self.dirtyRev or null;

        # Used for backwards compatibility. please read the changelog
        # before changing: `darwin-rebuild changelog`.
        system.stateVersion = 4;

        # The platform the configuration will be used on.
        # If you're on an Intel system, replace with "x86_64-darwin"
        nixpkgs.hostPlatform = "aarch64-darwin";

        # Allow unfree packages
        nixpkgs.config.allowUnfree = true;

        # Declare the user that will be running `nix-darwin`.
        users.users.trycatcher = {
          name = "trycatcher";
          home = "/Users/trycatcher";
        };

        # Create /etc/zshrc that loads the nix-darwin environment.
        programs.zsh.enable = true;

        environment.systemPackages = with pkgs; [ nixfmt-rfc-style ];

        homebrew = {
          enable = true;
          onActivation = {
            autoUpdate = true;
            cleanup = "zap";
          };
          taps = [ "homebrew/cask-fonts" "railwaycat/emacsmacport" ];
          casks = [
            "emacs-mac"
            "dropbox"
            "wezterm"
            "font-fira-code"
            "font-iosevka"
            "microsoft-excel"
            "anki"
            "obsidian"
            "bitwarden"
            "calibre"
            "spotify"
            "netnewswire"
            "zotero"
            "slack"
            "zulip"
            "discord"
            "element"
            "firefox"
            "google-chrome"
            "zed"
            "whatsapp"
            "zoom"
            "telegram"
            "docker"
            "cursor"
          ];

        };

        security.pam.enableSudoTouchIdAuth = true;
      };
      homeconfig = { pkgs, config, ... }: {
        # this is internal compatibility configuration 
        # for home-manager, don't change this!
        home.stateVersion = "23.05";
        # Let home-manager install and manage itself.
        programs.home-manager.enable = true;

        programs.neovim = {
          enable = true;
          viAlias = true;
          vimAlias = true;
        };

        programs.zsh = {
          enable = true;
          shellAliases = {
            rebuild-setup = "darwin-rebuild switch --flake ~/setup";
          };
        };

        programs.git = {
          enable = true;
          userName = "Abhik Khanra";
          userEmail = "abhik@abhikrk.in";
          ignores = [ ".DS_Store" ];
          extraConfig = {
            init.defaultBranch = "main";
            push.autoSetupRemote = true;
          };
        };

        home.file = {
          "./.config/nvim/init.lua".source = config.lib.file.mkOutOfStoreSymlink
            "${config.home.homeDirectory}/dotfiles/neovim/config.lua";
          ".wezterm.lua".source = config.lib.file.mkOutOfStoreSymlink
            "${config.home.homeDirectory}/dotfiles/wezterm/config.lua";
          "./.config/tmuxp/session.yaml".source =
            config.lib.file.mkOutOfStoreSymlink
            "${config.home.homeDirectory}/dotfiles/tmuxp/config.yaml";
          "./.emacs.d".source = config.lib.file.mkOutOfStoreSymlink
            "${config.home.homeDirectory}/dotfiles/emacs";
        };

        home.packages = with pkgs; [
          wget
          tree
          neofetch
          ledger
          ripgrep
          tmux
          tmuxp
          postgresql
          tarsnap
          gh
          multimarkdown
          pandoc
          tectonic
          hugo
          go
          nodejs
          temurin-jre-bin-11
          maven
          clojure
          magic-wormhole
          shellcheck
          shfmt
          gnupg
          aerc
          direnv
        ];

        home.sessionVariables.EDITOR = "nvim";
      };
    in {
      darwinConfigurations."maclatakan" = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.verbose = true;
            home-manager.users.trycatcher = homeconfig;
          }
        ];
      };
    };
}
