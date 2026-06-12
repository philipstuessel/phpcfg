alias php74="phpcfg -php 7.4"
alias php80="phpcfg -php 8.0"
alias php8="phpcfg -php 8.0"
alias php81="phpcfg -php 8.1"
alias php82="phpcfg -php 8.2"
alias php83="phpcfg -php 8.3"
alias php84="phpcfg -php 8.4"
alias php85="phpcfg -php 8.5"
alias php86="phpcfg -php 8.6"

phpcfg_v="v0.4.1"
PHPVERSIONS=(7.4 8.0 8.1 8.2 8.3 8.4 8.5 8.6)

phpcfg_JAP_ROOT="${JAP_FOLDER%/}"
if [[ -n "$phpcfg_JAP_ROOT" ]]; then
    phpcfg_JAP_ROOT="${phpcfg_JAP_ROOT}/"
fi

phpcfg_CONFIG_FOLDER="${phpcfg_JAP_ROOT}plugins/packages/phpcfg/config/"
phpcfg_CONFIG_FILE="${phpcfg_CONFIG_FOLDER}phpcfg.config.json"
phpcfg_PACKAGE_DIR="${phpcfg_JAP_ROOT}plugins/packages/phpcfg"

phpcfg_set_composer_root() {
    local composer_path="$1"
    local tmp_file="tmp.$$.json"
    if jq -e '.composerRoot' "$phpcfg_CONFIG_FILE" >/dev/null; then
        jq --arg composer_path "$composer_path" '.composerRoot = $composer_path' "$phpcfg_CONFIG_FILE" > "$tmp_file" && mv "$tmp_file" "$phpcfg_CONFIG_FILE"
    else
        jq --arg composer_path "$composer_path" '. + {composerRoot: $composer_path}' "$phpcfg_CONFIG_FILE" > "$tmp_file" && mv "$tmp_file" "$phpcfg_CONFIG_FILE"
    fi
}

phpcfg_install_composer() {
    local composer_phar="${phpcfg_PACKAGE_DIR}/composer.phar"
    local installer_file
    local php_bin
    local direct_url="https://getcomposer.org/download/latest-stable/composer.phar"
    
    if [[ -z "$phpcfg_PACKAGE_DIR" || "$phpcfg_PACKAGE_DIR" == "/" ]]; then
        echo -e "${RED}Invalid package path:${NC} $phpcfg_PACKAGE_DIR"
        return 1
    fi
    
    mkdir -p "$phpcfg_PACKAGE_DIR" || {
        echo -e "${RED}Could not create package directory:${NC} $phpcfg_PACKAGE_DIR"
        return 1
    }
    
    # Fast path: download composer.phar directly.
    echo -e "${YELLOW}Composer is downloading...${NC}"
    if command -v curl >/dev/null 2>&1; then
        if curl --progress-bar -fL "$direct_url" -o "$composer_phar"; then
            chmod +x "$composer_phar"
            phpcfg_set_composer_root "$composer_phar"
            echo -e "${GREEN}Composer installed:${NC} $composer_phar"
            return 0
        fi
        elif command -v wget >/dev/null 2>&1; then
        if wget --show-progress -q -O "$composer_phar" "$direct_url"; then
            chmod +x "$composer_phar"
            phpcfg_set_composer_root "$composer_phar"
            echo -e "${GREEN}Composer installed:${NC} $composer_phar"
            return 0
        fi
    fi
    
    php_bin=$(command -v php)
    if [[ -z "$php_bin" ]]; then
        echo -e "${RED}PHP not found in PATH.${NC}"
        return 1
    fi
    
    installer_file="$(mktemp)"
    if command -v curl >/dev/null 2>&1; then
        curl --progress-bar -fL "https://getcomposer.org/installer" -o "$installer_file" || {
            rm -f "$installer_file"
            echo -e "${RED}Failed to download Composer installer.${NC}"
            return 1
        }
        elif command -v wget >/dev/null 2>&1; then
        wget --show-progress -q -O "$installer_file" "https://getcomposer.org/installer" || {
            rm -f "$installer_file"
            echo -e "${RED}Failed to download Composer installer.${NC}"
            return 1
        }
    else
        rm -f "$installer_file"
        echo -e "${RED}Neither curl nor wget found.${NC}"
        return 1
    fi
    
    "$php_bin" "$installer_file" --install-dir="$phpcfg_PACKAGE_DIR" --filename="composer.phar"
    local install_rc=$?
    rm -f "$installer_file"
    
    if [[ $install_rc -ne 0 || ! -f "$composer_phar" ]]; then
        echo -e "${RED}Composer installation failed.${NC}"
        return 1
    fi
    
    chmod +x "$composer_phar"
    phpcfg_set_composer_root "$composer_phar"
    echo -e "${GREEN}Composer installed:${NC} $composer_phar"
    return 0
}

phpcfg_composer_link() {
    local composer_phar="${phpcfg_PACKAGE_DIR}/composer.phar"
    local uname_s uname_m
    local link_dir=""
    local candidates=()
    
    if [[ ! -f "$composer_phar" ]]; then
        echo -e "${RED}composer.phar not found at:${NC} $composer_phar"
        echo -e "Run ${CYAN}phpcfg install composer${NC} first."
        return 1
    fi
    
    uname_s="$(uname -s)"
    uname_m="$(uname -m)"
    
    if [[ "$uname_s" == "Darwin" ]]; then
        if [[ "$uname_m" == "arm64" ]]; then
            candidates=(/opt/homebrew/bin /usr/local/bin "$HOME/.local/bin")
        else
            candidates=(/usr/local/bin /opt/homebrew/bin "$HOME/.local/bin")
        fi
        elif [[ "$uname_s" == "Linux" ]]; then
        candidates=(/usr/local/bin "$HOME/.local/bin")
    else
        candidates=("$HOME/.local/bin")
    fi
    
    for dir in "${candidates[@]}"; do
        if [[ -d "$dir" && -w "$dir" ]]; then
            link_dir="$dir"
            break
        fi
    done
    
    if [[ -z "$link_dir" ]]; then
        link_dir="$HOME/.local/bin"
        mkdir -p "$link_dir" || {
            echo -e "${RED}Could not create link directory:${NC} $link_dir"
            return 1
        }
    fi
    
    ln -sf "$composer_phar" "$link_dir/composer" || {
        echo -e "${RED}Failed to create symlink:${NC} $link_dir/composer"
        return 1
    }
    
    phpcfg_set_composer_root "$composer_phar"
    echo -e "${GREEN}Composer linked:${NC} $link_dir/composer -> $composer_phar"
    if [[ ":$PATH:" != *":$link_dir:"* ]]; then
        echo -e "${YELLOW}Note:${NC} $link_dir is not in PATH."
    fi
    return 0
}

phpcfg_update_composer() {
    local composer_phar="${phpcfg_PACKAGE_DIR}/composer.phar"
    local php_bin
    local do_link=0
    local update_args=()
    local arg
    
    if [[ ! -f "$composer_phar" ]]; then
        echo -e "${RED}composer.phar not found at:${NC} $composer_phar"
        echo -e "Run ${CYAN}phpcfg install composer${NC} first."
        return 1
    fi
    
    php_bin=$(command -v php)
    if [[ -z "$php_bin" ]]; then
        echo -e "${RED}PHP not found in PATH.${NC}"
        return 1
    fi
    
    for arg in "$@"; do
        if [[ "$arg" == "-link" || "$arg" == "--link" ]]; then
            do_link=1
        else
            update_args+=("$arg")
        fi
    done
    
    "$php_bin" "$composer_phar" self-update "${update_args[@]}"
    local update_rc=$?
    if [[ $update_rc -ne 0 ]]; then
        echo -e "${RED}Composer update failed.${NC}"
        return $update_rc
    fi
    
    echo -e "${GREEN}Composer updated:${NC} $composer_phar"
    if [[ $do_link -eq 1 ]]; then
        phpcfg_composer_link
        return $?
    fi
    return 0
}

gphp=$(jq -r '.global' $phpcfg_CONFIG_FILE)
if [[ ! -z $gphp ]]; then
    alias php="phpcfg -php $gphp"
fi

phpcfg() {
    if [[ "$1" == "-v" || "$1" == "-version" || "$1" == "v" ]]; then
        echo -e "${BLUE}phpcfg$NC$BLUE$BOLD $phpcfg_v $NC"
        echo -e "${YELLOW}JAP plugin${NC}"
        return
    fi
    
    if [[ "$1" == "install" && "$2" == "composer" ]]; then
        phpcfg_install_composer
        return $?
    fi
    
    if [[ "$1" == "composer" && "$2" == "link" ]]; then
        phpcfg_composer_link
        return $?
    fi
    
    if [[ "$1" == "composer" && "$2" == "update" ]]; then
        shift 2
        phpcfg_update_composer "$@"
        return $?
    fi
    
    if [[ "$1" == "-php" ]]; then
        local version="$2"
        local command="$3"
        
        local root=$(jq -r '.phpRoot' "$phpcfg_CONFIG_FILE")
        local phpcmd=${root//"!v"/$version}
        
        if [[ ! -e "$phpcmd" ]]; then
            echo -e "${RED}The PHP version is not installed.$NC"
            return 1
        fi
        
        if [[ $command == "composer" ]]; then
            if ! jq -e '.composerRoot' "$phpcfg_CONFIG_FILE" >/dev/null; then
                jq '. + {composerRoot: ""}' "$phpcfg_CONFIG_FILE" > tmp.$$.json && mv tmp.$$.json "$phpcfg_CONFIG_FILE"
            fi
            
            local composer_root=$(jq -r '.composerRoot' "$phpcfg_CONFIG_FILE")
            if [[ -z "$composer_root" ]]; then
                composer_cmd=$(command -v composer)
            else
                composer_cmd="$composer_root"
            fi
            
            if [[ -z "$composer_cmd" ]]; then
                echo -e "${RED}Composer not found in PATH$NC"
                return 1
            fi
            shift 3
            "$phpcmd" "$composer_cmd" "$@"
            return $?
        else
            if [[ "$3" == "-r" ]]; then
                args=("${@:4}")
                code="${(j: :)args}"
                $phpcmd -r "$code"
                if [[ $? -ne 0 ]]; then
                    return 1
                else
                    return 0
                fi
            else
                shift 2
                $phpcmd "$@"
                if [[ $? -ne 0 ]]; then
                    return 1
                else
                    return 0
                fi
            fi
        fi
    fi
    
    if [[ "$1" == "e" ]]; then
        e "$phpcfg_CONFIG_FILE"
        return
    fi
    
    if [[ "$1" == "--list" || "$1" == "list" || "$1" == "-list" || "$1" == "--all" || "$1" == "all" || "$1" == "-all" ]]; then
        phplist "$1"
        return
    fi
    
    if [[ "$1" == "--help" || "$1" == "help" || "$1" == "-help" || "$1" == "" ]]; then
        echo -e "${BOLD}phpcfg commands:${NC}"
        echo -e "  ${CYAN}phpcfg -php <version> [command] [args]${NC}  Run PHP of specified version. Optionally run a command (like composer) with arguments."
        echo -e "  ${CYAN}phpcfg install composer${NC}                 Install composer.phar in plugins/packages/phpcfg."
        echo -e "  ${CYAN}phpcfg composer link${NC}                    Link composer.phar as 'composer' into a suitable bin directory."
        echo -e "  ${CYAN}phpcfg composer update [-link]${NC}          Update composer.phar; with -link also run composer link."
        echo -e "  ${CYAN}phpcfg --list [all]${NC}                     List available PHP versions and their paths. Use 'all' to show all versions."
        echo -e "  ${CYAN}phpcfg e${NC}                                Edit the phpcfg configuration file."
        echo -e "  ${CYAN}phpcfg -v${NC}                               Show version information."
        return
    fi
    
    if [[ ! -z "$1" ]]; then
        echo -e "${RED}Unknown command: $1${NC}"
        echo -e "Use '${CYAN}phpcfg --help${NC}' to see available commands."
        return 1
    fi
}

phplist() {
    if [[  "$1" == "--all" || "$1" == "all" || "$1" == "-all"  ]];then
        TABLE="${BOLD}V\tPaths${NC}"
        for v in "${PHPVERSIONS[@]}"; do
            root=$(jq -r '.phpRoot' $phpcfg_CONFIG_FILE)
            phpcmd=${root//"!v"/$v}
            if [[ -e $phpcmd ]]; then
                TABLE+="\n${BLUE}${BOLD}$v${NC}\t$phpcmd"
            else
                TABLE+="\n${RED}${BOLD}$v${NC}\t${RED}$phpcmd${NC}"
            fi
        done
    else
        TABLE="${BOLD}V\tCMD\tBehind it${NC}"
        phplive=$(type php 2>/dev/null)
        phplive=${phplive//"php is "/""}
        phplive=${phplive//"an alias for "/""}
        TABLE+="\n${MAGENTA}${BOLD}$(php -v | head -n 1 | awk '{print $2}' | awk -F '.' '{print $1"."$2}')${NC}\t${CYAN}php${NC}\t${BOLD}${phplive}${NC}"
        for v in "${PHPVERSIONS[@]}"; do
            root=$(jq -r '.phpRoot' $phpcfg_CONFIG_FILE)
            phpcmd=${root//"!v"/$v}
            phpcfgcode=${v//"."/""}
            if [[ -e $phpcmd ]]; then
                TABLE+="\n${BLUE}${BOLD}$v${NC}\t${CYAN}php$phpcfgcode${NC}\t$phpcmd"
            fi
        done
    fi
    echo -e $TABLE
}
