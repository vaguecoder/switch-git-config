#!/usr/bin/env bash

function load_configs() {
    if [ -z "${CONFIG_FILE}" ]; then
        print_red "Missing config file name env: CONFIG_FILE"
        
        return 1
    fi

    if [ ! -e "${CONFIG_FILE}" ]; then
        print_red "Missing config file: ${CONFIG_FILE}"
        
        return 1
    fi

    source ${CONFIG_FILE}
    print_blue "Loaded config file successfully: \"${CONFIG_FILE}\""
}

function check_variables() {
    local REQUIRED_ENVS=(
        "GIT_COMMIT_TEMPLATE_FILE"
        "GIT_DEFAULT_BRANCH"
        "GIT_EMAIL"
        "GIT_USER"
        "GPG_PASSPHRASE"
        "GPG_PRIVATE_KEY_FILE"
        "SSH_PASSPHRASE"
        "SSH_PRIVATE_KEY_FILE"
    )
    local MISSING_ENVS=()

    for ENV in "${REQUIRED_ENVS[@]}"; do
        if ! grep "^${ENV}" ${CONFIG_FILE} >/dev/null ; then
            MISSING_ENVS+=("${ENV}")
        fi
    done

    if [ ${#MISSING_ENVS[@]} -ne 0 ]; then
        print_red "Missing mandatory envs: $(sed 's/ /, /g' <<<${MISSING_ENVS[@]})"

        return 1
    fi

    print_blue "Checked input variables successfully: $(sed 's/ /, /g' <<<${REQUIRED_ENVS[@]})"
}

function clean_up() {
    # Remove Git config, SSH and GPG files
    rm -rf ${HOME}/.gitconfig ${HOME}/.git/commit-msg ${HOME}/.ssh/id_* ${HOME}/.gnupg/
    ssh-add -D

    # Create Empty Directories
    mkdir -p ${HOME}/{.ssh/,.gnupg/,.git/}
    chown -R $(whoami) ${HOME}/.gnupg/
    chmod 700 ${HOME}/.gnupg

    # Hack-around to make gpg create the required files: pubring.kbx, trustdb.gpg
    gpg --list-keys 2>/dev/null

    print_blue "Cleaned-up git, ssh, gpg files successfully"
}

function setup_ssh() {
    # Add SSH Private Key
    if [ "${SSH_PASSPHRASE}" == "" ]; then
        ssh-add ${SSH_PRIVATE_KEY_FILE} 2>&1 | sed -e "s|${HOME}|~|g"
    else
        print_yellow "It will prompt for SSH passphrase, but it is for the script. DO NOT ENTER PASSWORD!"
        expect -c "
            spawn ssh-add ${SSH_PRIVATE_KEY_FILE}
            expect \"Enter passphrase for ${SSH_PRIVATE_KEY_FILE}:\"
            send \"${SSH_PASSPHRASE}\r\"
            expect EOF
        " | sed -e "s|${HOME}|~|g"
    fi

    print_blue "SSH setup successfully"
}

function setup_gpg() {
    # Add GPG Private Key
    gpg --batch --yes --pinentry-mode loopback --passphrase ${GPG_PASSPHRASE} --import ${GPG_PRIVATE_KEY_FILE}

    print_blue "GPG setup successfully"
}

function setup_git() {
    # Update the Git Commit Template
    sed -e "s|#USER|${GIT_USER}|g" -e "s|#EMAIL|${GIT_EMAIL}|g" "${GIT_COMMIT_TEMPLATE_FILE}" > "${HOME}/.git/commit-msg"

    # Fetch GPG Key's ID
    GPG_KEY_ID=$(gpg --list-secret-keys --keyid-format LONG | awk -F/ '/^sec/{print $2}' | awk '{print $1}' | tr -d '\n')

    # Add git configs
    git config --global core.editor "code --wait"
    git config --global user.name ${GIT_USER}
    git config --global user.email ${GIT_EMAIL}
    git config --global init.defaultBranch ${GIT_DEFAULT_BRANCH}
    git config --global commit.gpgsign true
    git config --global user.signingkey ${GPG_KEY_ID}
    git config --global commit.template "${HOME}/.git/commit-msg"
    git config --global user.configname "${CONFIG_FILE}"

    print_blue "Git setup successfully"
}

# Set shell options
set -e

# Main flow
source common.sh
load_configs
check_variables
clean_up
setup_ssh
setup_gpg
setup_git

# Unset shell options
set +e
