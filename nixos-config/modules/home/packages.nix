{ inputs, pkgs, ... }: 
{
  home.packages = (with pkgs; [
    # VPN
    eduvpn-client                    # for accessing school resouces using any internet other than eduroam

    ## CLI utility
    ani-cli
    binsider
    caligula                          # User-friendly, lightweight TUI for disk imaging
    dconf-editor
    docfd                             # TUI multiline fuzzy document finder
    eza                               # ls replacement
    entr                              # perform action when file change
    fd                                # find replacement
    ffmpeg
    file                              # Show file information 
    gifsicle                          # gif utility
    gtrash                            # rm replacement, put deleted files in system trash
    imv                               # image viewer
    jq                                # JSON processor
    killall
    lazygit
    libnotify
	  man-pages					            	  # extra man pages
    mimeo
    mpv                               # video player
    ncdu                              # disk space
    nitch                             # systhem fetch util
    nixd                              # nix lsp
    nixfmt-rfc-style                  # nix formatter
    openssl
    onefetch                          # fetch utility for git repo
    pamixer                           # pulseaudio command line mixer
    playerctl                         # controller for media players
    poweralertd
    programmer-calculator
    ripgrep                           # grep replacement
    shfmt                             # bash formatter
    swappy                            # snapshot editing tool
    tdf                               # cli pdf viewer
    treefmt2                          # project formatter
    tldr
    toipe                             # typing test in the terminal
    ttyper                            # cli typing test
    unzip
    valgrind                          # c memory analyzer
    wl-clipboard                      # clipboard utils for wayland (wl-copy, wl-paste)
    wget
    yt-dlp-light
    xdg-utils
    xxd

    ## CLI 
    cbonsai                           # terminal screensaver
    cmatrix
    pipes                             # terminal screensaver
    sl
    tty-clock                         # cli clock

    ## GUI Apps
    audacity
    bleachbit                         # cache cleaner
    gimp
    libreoffice
    nix-prefetch-github
    pavucontrol                       # pulseaudio volume controle (GUI)
    pitivi                            # video editing
    qalculate-gtk                     # calculator
    soundwireserver
    thunderbird
    vlc
    winetricks
    wineWowPackages.wayland
    zenity

    # C / C++
    gcc
    gdb
    gnumake

    # Python
    python3
    python312Packages.ipython

    inputs.alejandra.defaultPackage.${system}
  ]);
}
