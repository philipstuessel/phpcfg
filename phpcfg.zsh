alias php74="phpcfg -php 7.4"
alias php80="phpcfg -php 8.0"
alias php8="phpcfg -php 8.0"
alias php81="phpcfg -php 8.1"
alias php82="phpcfg -php 8.2"
alias php83="phpcfg -php 8.3"
alias php84="phpcfg -php 8.4"
alias php85="phpcfg -php 8.5"

PHPVERSIONS=(7.4 8.0 8.1 8.2 8.3 8.4 8.5)

phpcfg_CONFIG_FOLDER="${JAP_FOLDER}plugins/packages/phpcfg/config/"
phpcfg_CONFIG_FILE="${phpcfg_CONFIG_FOLDER}phpcfg.config.json"

gphp=$(jq -r '.global' $phpcfg_CONFIG_FILE)
if [[ ! -z $gphp ]]; then
    alias php="phpcfg -php $gphp"
fi

phpcfg() {
    if [[ "$1" == "-v" || "$1" == "-version" || "$1" == "v" ]]; then
        echo -e "${BLUE}phpcfg$NC$BLUE$BOLD v0.3.0 $NC"
        echo -e "${YELLOW}JAP plugin${NC}"
        return
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
                jq '. + {composerRoot: ""}' "$phpcfg_CONFIG_FILE" >> tmp.$$.json && mv tmp.$$.json "$phpcfg_CONFIG_FILE"
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
        else
            if [[ "$3" == "-r" ]]; then
                args=("${@:4}") 
                code="${(j: :)args}"
                $phpcmd -r "$code"
            else
                shift 2
                $phpcmd "$@"
            fi
        fi
        return 1
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