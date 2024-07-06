alias php74="phpcfg -php 7.4"
alias php80="phpcfg -php 8.0"
alias php8="phpcfg -php 8.0"
alias php81="phpcfg -php 8.1"
alias php82="phpcfg -php 8.2"
alias php83="phpcfg -php 8.3"
alias php84="phpcfg -php 8.4"

PHPVERSIONS=(7.4 8.0 8.1 8.2 8.3 8.4)

phpcfg_MAIN_FOLDER="${JAP_FOLDER}plugins/packages/phpcfg/config/"
phpcfg_CONFIG_FILE="${phpcfg_MAIN_FOLDER}phpcfg.config.json"

gphp=$(jq -r '.global' $phpcfg_CONFIG_FILE)
if [[ ! -z $gphp ]]; then
    alias php="phpcfg -php $gphp"
fi

phpcfg() {
    if [[ "$1" == "-v" || "$1" == "-version" || "$1" == "v" ]]; then
        echo -e "${BLUE}phpcfg$NC$BLUE$BOLD v0.2.0 $NC"
    fi
    if [[ "$1" == "-php" ]]; then
        v="$2"
        root=$(jq -r '.phpRoot' $phpcfg_CONFIG_FILE)
        phpcmd=${root//"!v"/$v}
        if [[ -e $phpcmd ]]; then
            eval "$phpcmd \"$3\""
        else
            echo -e "${RED}The PHP version is not installed$NC"
        fi
    fi
    
    if [[ "$1" == "e" ]]; then
        e $phpcfg_CONFIG_FILE
    fi
    
    if [[ "$1" == "--list" || "$1" == "list" || "$1" == "-list" ]]; then
        phplist "$2"
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