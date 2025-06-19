#!/usr/bin/env bash

 function btail() {
     if [ -z "$1" ]; then
         echo -e "${ARROW} ${YELLOW}Usage: btail [OPTION]... [FILE]...${NC}"
         return 1
     fi
     # tail -f $@ | bat -P -l log # This is the short version
     tail -f $@ | bat --paging=never --language=log
 }


# Utils
# alias c="clear"
# alias cd="z"
# alias tt="gtrash put"
alias bat="batcat" # simplest fix for ubuntu apt installs this sometimes as batcat
alias cat="bat"
# alias nano="micro"
# alias diff="delta --diff-so-fancy --side-by-side"
alias less="bat"
# alias y="yazi"
alias python="python3"
alias py="python3"
# alias ipy="ipython"
# alias icat="kitten icat"
alias dsize="du -hs"
# alias pdf="tdf"
# alias open="xdg-open"
# alias space="ncdu"
# alias man="BAT_THEME='default' batman"
# alias l="eza --icons -a --group-directories-first -1" # EZA_ICON_SPACING=2
# alias ll="eza --icons -a --group-directories-first -1 --no-user --long"
# alias tree="eza --icons --tree --group-directories-first"
alias cddot="cd ~/.dotfiles && tmux attach-session -t dot 2>/dev/null || tmux new-session -s dot"
# NixOS
# alias ns="nom-shell --run zsh"
# alias nix-switch="nh os switch"
# alias nix-update="nh os switch --update"
# alias nix-clean="nh clean all --keep 5"
# alias nix-search="nh search"
# alias nix-test="nh os test"

# Python
alias piv="uv venv && source .venv/bin/activate"
alias pya="source .venv/bin/activate"
alias pyd="deactivate"

# Dotfiles
# alias dotfiles="bash ~/.dotfiles/bin/dotfiles"
