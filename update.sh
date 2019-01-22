#!/bin/bash
#set -x
set -euo pipefail

tmpdir=$(mktemp -d -t tmp.XXXXXXXXXX)
logfile=/tmp/mylog.txt
maxfunclen=14

function on_exit {
    rm -rf "$tmpdir"
    log "END with $1
"
    return $?
}

trap 'on_exit $?; exit $?' EXIT

function log() {
    printf "%s %+${maxfunclen}s %s\n" \
           "[$(date +'%Y/%m/%d %T')]" \
           "${FUNCNAME[1]}()" "$1" | \
        tee -a $logfile
}

log "START with $tmpdir"

# start your code here

login_url="https://alt.org/nethack/login.php"
update_url="https://alt.org/nethack/webconf/nhrc_edit.php"
authinfo_file="authinfo.txt"
cookie_file="cookie.txt"
config_file="nethack.config"

function createAuthInfoFile() {
    read -p  'Username: ' username
    read -sp 'Password: ' password

    echo $username > authinfo.txt
    echo $password >> authinfo.txt    
}

function getAuthInfo() {
    if [ ! -f "$authinfo_file" ]; then
	createAuthInfoFile
    fi

    sed -i '/^$/d' $authinfo_file

    if [ $(wc -l < $authinfo_file) -eq 2 ]; then	
	username=$(sed -n 1p $authinfo_file)
	password=$(sed -n 2p $authinfo_file)
	printf "nao_username=%s&nao_password=%s&submit=Login" $username $password
    else
	createAuthInfoFile
    fi
}

function login() {
    data=$(getAuthInfo)
    log "Loging..."
    curl -L "$login_url" \
	 --cookie     "$cookie_file" \
	 --cookie-jar "$cookie_file" \
	 -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:64.0) Gecko/20100101 Firefox/64.0" \
	 -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" \
	 -H "Accept-Language: zh-CN,zh;q=0.8,zh-TW;q=0.7,zh-HK;q=0.5,en-US;q=0.3,en;q=0.2" \
	 --compressed \
	 -H "Referer: https://alt.org/nethack/login.php" \
	 -H "Content-Type: application/x-www-form-urlencoded" \
	 -H "Connection: keep-alive" \
	 -H "Upgrade-Insecure-Requests: 1" \
	 --data "$data" --write-out 'Status: %{http_code}\n' --silent --output /dev/null
    log "Loged"
}

function updateConfig() {
    log "Updating..."
    curl -L "$update_url" \
	 --cookie     "$cookie_file" \
	 --cookie-jar "$cookie_file" \
	 -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:64.0) Gecko/20100101 Firefox/64.0" \
	 -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" \
	 -H "Accept-Language: zh-CN,zh;q=0.8,zh-TW;q=0.7,zh-HK;q=0.5,en-US;q=0.3,en;q=0.2" \
	 --compressed \
	 -H "Referer: https://alt.org/nethack/login.php" \
	 -H "Content-Type: application/x-www-form-urlencoded" \
	 -H "Connection: keep-alive" \
	 -H "Upgrade-Insecure-Requests: 1" \
	 --data-urlencode "rcdata@$config_file" \
	 --data "submit=Save" --write-out 'Status: %{http_code}\n' --silent --output /dev/null
    log "Updated"
}

login
updateConfig
