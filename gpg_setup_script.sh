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

checkIfConfToLatestGPG () {
    echo -n "Do you want this new key to be configutred as the git signing key? (y/n) "
    read bool
    if [ bool -eq "y" ]; then
        configureToLatestGPG
    elif [ bool -eq "n" ]; then
        echo "Okay, exiting..."
        exit 0
    fi
}
#####################################################################


# Checking if gpg and git are installed.
if [ ! `which gpg` ] || [ ! `which git` ]; then
    echo "Install gpg and git before setting up."
    echo "Download gpg from here: https://gnupg.org/download/"
    echo "And git from here: https://git-scm.com/downloads"
    exit 1
fi

while true;

do
    if [[ `gpg --list-keys` ]] ; then

        instruction="Hey! You've previously generated keys. Do you want to..
        (1) Use an existing one
        (2) Generate a new one
        (3) Delete any previous key
        (4) Quit"

        gpgKeyPrompt="Enter the GPG Key ID to be used -->
        (For example: in 'rsa3072/05F733A1C16AB0D4', 
        '05F733A1C16AB0D4' is our GPG Key ID)"
        
        prettyPrint "$instruction"

        echo -n "Enter your choice (1/2/3/4): "
        read choice

        if [ $choice -eq 1 ]; then
            gpg --list-secret-keys --keyid-format=long
            prettyPrint "$gpgKeyPrompt"
            
            # Taking the key to be used and configuring it for signing commits by default.
            read key
            gitConfig $key
        
        elif [ $choice -eq 2 ]; then
            gpg --full-generate-key
            checkIfConfToLatestGPG

        elif [ $choice -eq 3 ]; then
            gpg --list-secret-keys --keyid-format=long
            prettyPrint "$gpgKeyPrompt"
            read key
            gpg --delete-secret-key $key
            gpg --delete-key $key

        elif [ $choice -eq 4 ]; then
            echo "Byeee"
            exit 0
        fi

    else
        # Generate a key if user doesn't have any.
        prettyPrint "It seems you don't have any gpg keys generated..
        Generating one for you :)"
        gpg --full-generate-key
        checkIfConfToLatestGPG
    fi

done