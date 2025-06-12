#!/usr/bin/env bash

# Parse command-line arguments
while getopts "u:h:c" opt; do
  case $opt in
    u) username="$OPTARG" ;;           # Username
    h) HOST="$OPTARG" ;;               # Host type
    c) skip_confirm=true ;;            # Skip confirmation
    *) echo "Usage: $0 -u <username> -h <host> [-c]"; exit 1 ;;
  esac
done

init() {
    # Vars
    CURRENT_USERNAME='valiantlynx'

    # Colors
    NORMAL=$(tput sgr0)
    WHITE=$(tput setaf 7)
    BLACK=$(tput setaf 0)
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    MAGENTA=$(tput setaf 5)
    CYAN=$(tput setaf 6)
    BRIGHT=$(tput bold)
    UNDERLINE=$(tput smul)
}

confirm() {
    echo -en "[${GREEN}y${NORMAL}/${RED}n${NORMAL}]: "
    read -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
}

print_header() {
    echo -E "$CYAN
 __     __           __  __                       __      __                                                 
|  \   |  \         |  \|  \                     |  \    |  \                                                
| $$   | $$ ______  | $$ \$$  ______   _______  _| $$_   | $$ __    __  _______   __    __                   
| $$   | $$|      \ | $$|  \ |      \ |       \|   $$ \  | $$|  \  |  \|       \ |  \  /  \                  
 \$$\ /  $$ \$$$$$$\| $$| $$  \$$$$$$\| $$$$$$$\\$$$$$$  | $$| $$  | $$| $$$$$$$\ \$$\/  $$                  
  \$$\  $$ /      $$| $$| $$ /      $$| $$  | $$ | $$ __ | $$| $$  | $$| $$  | $$  >$$  $$                   
   \$$ $$ |  $$$$$$$| $$| $$|  $$$$$$$| $$  | $$ | $$|  \| $$| $$__/ $$| $$  | $$ /  $$$$\                   
    \$$$   \$$    $$| $$| $$ \$$    $$| $$  | $$  \$$  $$| $$ \$$    $$| $$  | $$|  $$ \$$\                  
     \$     \$$$$$$$ \$$ \$$  \$$$$$$$ \$$   \$$   \$$$$  \$$ _\$$$$$$$ \$$   \$$ \$$   \$$                  
                                                             |  \__| $$                                      
                                                              \$$    $$                                      
                                                               \$$$$$$                                       
 __    __  __            ______                                 __                __  __                     
|  \  |  \|  \          |      \                               |  \              |  \|  \                    
| $$\ | $$ \$$ __    __  \$$$$$$ _______    _______   ______  _| $$_     ______  | $$| $$  ______    ______  
| $$$\| $$|  \|  \  /  \  | $$  |       \  /       \ |      \|   $$ \   |      \ | $$| $$ /      \  /      \ 
| $$$$\ $$| $$ \$$\/  $$  | $$  | $$$$$$$\|  $$$$$$$  \$$$$$$\\$$$$$$    \$$$$$$\| $$| $$|  $$$$$$\|  $$$$$$\
| $$\$$ $$| $$  >$$  $$   | $$  | $$  | $$ \$$    \  /      $$ | $$ __  /      $$| $$| $$| $$    $$| $$   \$$
| $$ \$$$$| $$ /  $$$$\  _| $$_ | $$  | $$ _\$$$$$$\|  $$$$$$$ | $$|  \|  $$$$$$$| $$| $$| $$$$$$$$| $$      
| $$  \$$$| $$|  $$ \$$\|   $$ \| $$  | $$|       $$ \$$    $$  \$$  $$ \$$    $$| $$| $$ \$$     \| $$      
 \$$   \$$ \$$ \$$   \$$ \$$$$$$ \$$   \$$ \$$$$$$$   \$$$$$$$   \$$$$   \$$$$$$$ \$$ \$$  \$$$$$$$ \$$      
                                                                                                             
                                                                                                             
                                                                                                             

                  $BLUE https://github.com/valiantlynx $RED 
      ! To make sure everything runs correctly DONT run as root ! $GREEN
                        -> '"./install.sh"' $NORMAL

    "
}

get_username() {
    if [[ -z "$username" ]]; then
        echo -en "Enter your ${GREEN}username${NORMAL} [default: ${CURRENT_USERNAME}]: "
        read input_username
        username="${input_username:-$CURRENT_USERNAME}"
    fi
    echo "Using username: ${YELLOW}${username}${NORMAL}"
    if [[ "$skip_confirm" != true ]]; then
        confirm
    fi
}

set_username() {
    sed -i -e "s/${CURRENT_USERNAME}/${username}/g" ./flake.nix
    sed -i -e "s/${CURRENT_USERNAME}/${username}/g" ./modules/home/audacious.nix
}

get_host() {
    if [[ -z "$HOST" ]]; then
        echo -en "Choose a ${GREEN}host${NORMAL} - [${YELLOW}D${NORMAL}]esktop, [${YELLOW}L${NORMAL}]aptop, [${YELLOW}V${NORMAL}]irtual machine (default: desktop): "
        read -n 1 -r input_host
        echo
        case "$input_host" in
            [Dd]|"") HOST="desktop" ;;
            [Ll]) HOST="laptop" ;;
            [Vv]) HOST="vm" ;;
            *)
                echo "${RED}Invalid choice. Please select 'D', 'L', or 'V'.${NORMAL}"
                exit 1
                ;;
        esac
    else
        case "$HOST" in
            [Dd]) HOST="desktop" ;;
            [Ll]) HOST="laptop" ;;
            [Vv]) HOST="vm" ;;
            desktop|laptop|vm) ;;  # If full name is already provided, do nothing
            *)
                echo "${RED}Invalid HOST value provided. Allowed values: 'D', 'L', 'V', 'desktop', 'laptop', 'vm'.${NORMAL}"
                exit 1
                ;;
        esac
    fi
    echo "Using host: ${YELLOW}${HOST}${NORMAL}"
}

install() {
    echo -e "\n${RED}START INSTALL PHASE${NORMAL}\n"
    sleep 0.2

    # Create basic directories
    echo -e "Creating folders:"
    echo -e "    - ${MAGENTA}~/Music${NORMAL}"
    echo -e "    - ${MAGENTA}~/Documents${NORMAL}"
    echo -e "    - ${MAGENTA}~/Pictures/wallpapers/others${NORMAL}"
    mkdir -p ~/Music
    mkdir -p ~/Documents
    mkdir -p ~/Pictures/wallpapers/others
    sleep 0.2

    # Copy the wallpapers
    echo -e "Copying all ${MAGENTA}wallpapers${NORMAL}"
    cp -r wallpapers/wallpaper.png ~/Pictures/wallpapers
    cp -r wallpapers/otherWallpaper/gruvbox/* ~/Pictures/wallpapers/others/
    cp -r wallpapers/otherWallpaper/nixos/* ~/Pictures/wallpapers/others/
    sleep 0.2

    # Get the hardware configuration
    echo -e "Copying ${MAGENTA}/etc/nixos/hardware-configuration.nix${NORMAL} to ${MAGENTA}./hosts/${HOST}/${NORMAL}\n"
    cp /etc/nixos/hardware-configuration.nix hosts/${HOST}/hardware-configuration.nix
    sleep 0.2

    # Last Confirmation
    if [[ "$skip_confirm" != true ]]; then
        echo "You are about to start the system build. Do you want to proceed?"
        confirm
    fi

    # Build the system (flakes + home manager)
    echo -e "\nBuilding the system...\n"
    sudo nixos-rebuild switch --flake .#${HOST}

    sudo /run/current-system/bin/switch-to-configuration boot
}

main() {
    init

    # print_header

    get_username
    set_username
    get_host

    install
}

main && exit 0

