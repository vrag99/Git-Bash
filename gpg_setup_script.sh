#!/bin/bash

# Utils ############################################################
prettyPrint () {
    echo "-------------------------------------------------------"
    echo "$1"
    echo "-------------------------------------------------------"
}

gitConfig () {
    git config --global user.signingkey $1
	git config --global commit.gpgsign true
    [ -f ~/.bashrc ] && echo 'export GPG_TTY=$(tty)' >> ~/.bashrc
    gpg --export --armor $1 | cat
    echo "Copy this and paste in your GitHub's gpg key section."
}

getLatestGPGKeyID () {
    # Get the rsa id part which is preceeded by sec
    keys=$(gpg --list-secret-keys --keyid-format=long | awk '/sec/{print $2}')

    # Creating the array of those keys.
    keyList=($(echo $keys))

    # Getting the last key and splitting it by '/'
    lastKey=($(echo ${keyList[-1]} | tr '/' ' '))

    # The id is preceeded by a '/', hence getting the id of the latest gpg key.
    latestGpgKeyId=${lastKey[1]}

    echo $latestGpgKeyId
}

configureToLatestGPG () {
    latestGPGKeyID=$(getLatestGPGKeyID)
    gitConfig $latestGPGKeyID
}
#####################################################################


# Checking if gpg and git are installed.
if [ ! `which gpg` ] || [ ! `which git` ]; then
    echo "Install gpg and git before setting up."
    exit 1
fi

if [[ `gpg --list-keys` ]] ; then

    instruction="Hey! You've previously generated keys. Do you want to..
    (1) Use an existing one
    (2) Generate a new one
    (3) Delete any previous key"

    prettyPrint "$instruction"

    echo -n "Enter your choice (1/2/3): "
    read choice

    if [ $choice -eq 1 ]; then
        gpg --list-secret-keys --keyid-format=long
        echo -n "Enter the secret key to be used: "
        
        # Taking the key to be used and configuring it for signing commits by default.
        read key
        gitConfig $key
    
    elif [ $choice -eq 2 ]; then
        gpg --full-generate-key
        configureToLatestGPG

    elif [ $choice -eq 3 ]; then
        gpg --list-secret-keys
        echo -n "Enter the secret key to be deleted: "
        read key
        gpg --delete-key $key
        gpg --delete-secret-key $key
    fi

else
    # Generate a key if user doesn't have any.
    prettyPrint "It seems you don't have any gpg keys generated..
    Generating one for you :)"
    gpg --full-generate-key
    configureToLatestGPG
fi