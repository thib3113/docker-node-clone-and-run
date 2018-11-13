#!/bin/bash

set -e

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env(){
	local var="$1"
	local fileVar="${var}_FILE"
	local def="${2:-}"
	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
		echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
		exit 1
	fi
	local val="$def"
	if [ "${!var:-}" ]; then
		val="${!var}"
	elif [ "${!fileVar:-}" ]; then
		val="$(< "${!fileVar}")"
	fi
	export "$var"="$val"
	unset "$fileVar"
}

file_env 'SSH_KEY'
file_env 'GIT_REPO'
file_env 'SSH_KEY_PASSPHRASE'

if [[ -z "$GIT_REPO" ]];
then
    echo -e "empty repository URL !\nPlease fill environment GIT_REPO, or GIT_REPO_FILE"
    exit 1
else
    if [[ -n "$SSH_HOST" ]];
    then
        #add SSH_KEY if using ssh url
        mkdir -p /root/.ssh && \
        chmod 0700 /root/.ssh && \
        echo "add ${SSH_HOST} to known_hosts" && \
        ssh-keyscan ${SSH_HOST} > /root/.ssh/known_hosts && \
        /usr/bin/printf "%s" "${SSH_KEY}" > /root/.ssh/id_rsa && \
        chmod 600 /root/.ssh/id_rsa && \
        echo "eval ssh-agent" && \
        eval `ssh-agent -s` && \
        printf "${SSH_KEY_PASSPHRASE}\n" | ssh-add $HOME/.ssh/id_rsa
    fi
fi

if [[ -z "$GIT_BRANCH" ]];
then
    echo -e "cloning branch master"
    git clone --single-branch -b master $GIT_REPO ./tmp
else
    echo -e "cloning branch $GIT_BRANCH"
    git clone --single-branch -b $GIT_BRANCH $GIT_REPO ./tmp
fi
mv ./tmp/* .


yarn install --silent --non-interactive 

echo -e "\n"
echo -e "start app"

node -p 'let pkg = require("./package.json");`${pkg.name} - ${pkg.version}`'
yarn start