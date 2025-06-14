{
  inputs,
  username,
  host,
  ...
}:
{
  imports = [
    ./aseprite/aseprite.nix # pixel art editor
    ./audacious.nix # music player
    ./bat.nix # better cat command
    ./browser.nix # firefox based browser
    ./btop.nix # resouces monitor
    ./cava.nix # audio visualizer
    ./discord/discord.nix # discord with gruvbox
    ./eduvpn.nix # vpn to use school resources
    ./fastfetch.nix # fetch tool
    ./fzf.nix # fuzzy finder
    ./gaming.nix # packages related to gaming
    ./git.nix # version control
    ./gnome.nix # gnome apps
    ./gtk.nix # gtk theme
    ./hyprland # window manager
    ./kitty.nix # terminal
    ./swayosd.nix # brightness / volume wiget
    ./swaync/swaync.nix # notification deamon
    ./micro.nix # nano replacement
    ./nemo.nix # file manager
    ./nvim.nix # neovim editor
    ./logseq.nix # note taking app
    ./p10k/p10k.nix
    ./packages.nix # other packages
    ./retroarch.nix
    ./rofi.nix # launcher
    ./scripts/scripts.nix # personal scripts
    ./spicetify.nix # spotify client
    ./starship.nix # shell prompt
    ./swaylock.nix
    ./tmux.nix # lock screen
    ./uv.nix # python virtual env manager and version manager
    ./viewnior.nix # image viewer
    ./vscode.nix # vscode
    ./waybar # status bar
    ./waypaper.nix # GUI wallpaper picker
    ./xdg-mimes.nix # xdg config
    ./yazi.nix # terminal file manager
    ./zsh # shell
  ];
}
