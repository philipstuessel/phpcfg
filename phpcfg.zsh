alias php80="phpcfg -php 8.0"
alias php8="phpcfg -php 8.0"
alias php81="phpcfg -php 8.1"
alias php82="phpcfg -php 8.2"
alias php83="phpcfg -php 8.3"
alias php84="phpcfg -php 8.4"

phpcfg_MAIN_FOLDER="${JAP_FOLDER}plugins/packages/phpcfg/config/"
phpcfg_CONFIG_FILE="${phpcfg_MAIN_FOLDER}phpcfg.config.json"

gphp=$(jq -r '.global' $phpcfg_CONFIG_FILE)
if [[ ! -z $gphp ]]; then
    alias php="phpcfg -php $gphp"
fi

phpcfg() {
    if [[ "$1" == "-v" || "$1" == "-version" || "$1" == "v" ]]; then
        echo -e "${BLUE}phpcfg$NC$BLUE$BOLD v0.1.2 $NC"
    fi
    if [[ "$1" == "-php" ]]; then
        v="$2"
        root=$(jq -r '.phpRoot' $phpcfg_CONFIG_FILE)
        phpcmd=${root//"!v"/$v}
        if [[ -e $phpcmd ]]; then
            eval "$phpcmd \"$3\""
        else
            echo "${RED}The PHP version is not installed$NC"
        fi
    fi
    
    if [[ "$1" == "e" ]]; then
       $(e $phpcfg_CONFIG_FILE)
    fi
}