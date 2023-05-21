#!/bin/bash

askRepoDetails () {
    read -p "Name of the repo you want to create: " repo
    read -p "Description: " description

    echo "Which type of repo do you want to create?"
    echo "(1) public"
    echo "(2) private"
    read -p "Choose(1/2): " repoType

    echo "Setup via: "
    echo "(1) ssh"
    echo "(2) https"
    read -p "Choose(1/2): " conf
}

makeNewRepo () {
    curl -L \
    -X POST \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $PAT" \
    -H "X-GitHub-Api-Version: 2022-11-28" https://api.github.com/user/repos \
    -d "{\"name\":\"$repo\",\"description\":\"$description\", \"private\":$repoType}"
}


# Getting the username and pat.
if [[ -f credentials.env ]]; then
    source credentials.env
else 
    read -p "Enter your github username: " USERNAME
    read -p -s "Enter your personal access token: " PAT
    echo "USERNAME=$USERNAME" > credentials.env
    echo "PAT=$PAT" >> credentials.env
    chmod 400 credentials.env
fi

# Get the details for the repo to be created
askRepoDetails

if [[ $repoType = 1 ]]; then
    repoType=false
elif [[ $repoType = 2 ]]; then
    repoType=true
else
    echo "This isn't a valid repo-type.."
    exit 1
fi

if [[ $conf = 1 || $conf = 2 ]]; then
    echo "Configuration is accepted."
else
    echo "This isn't a valid setup type."
    exit 1
fi

response=$( makeNewRepo )

if [[ "$response" =~ "\"message\": \"name already exists on this account\"" ]]; then
    echo "This repository already exists..."
    askRepoDetails
    makeNewRepo    
fi

# Pushing the local repo
mkdir $repo
cd $repo
git init
echo `basename "$0"` > .gitignore
echo "credentials.env" >> .gitignore
echo "# $repo" > README.md
git add .
git commit -m "first commit"
git branch -M main

if [[ $conf = 1 ]]; then
    git remote add origin "git@github.com:$USERNAME/$repo.git"
elif [[ $conf = 2 ]]; then
    git remote add origin "https://github.com/$USERNAME/$repo.git"
fi

git push origin main