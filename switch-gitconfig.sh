#!/usr/bin/env bash

# Prerequisites:
# 1. Bash shell
# 2. The script setup-gitconfig.sh should be in the same directory.
# 3. The git config env files per each profile should be in the same directory. This will be discussed in usage section below.
# 
# Usage:
#   Note: The symbol $ denotes the command should be executed in the shell excluding the symbol
#   1. Add your git configs of a profile in the current directory with naming *.gitconfig.env, eg.,
#       abc.gitconfig.env
#       def.gitconfig.env
#     For sample, refer sample.gitconfig.env file. Note: sample.gitconfig.env will be ignored by the script.
#   2. Make the script executable. The script runs in a bash shell.
#     $ chmod +x switch-gitconfig.sh
#   3. Run the script:
#     1. To switch to next git config in circular order: 
#       $ ./switch-gitconfig.sh
#     2. To switch to specific git config:
#       $ ./switch-gitconfig.sh <file-name-pattern>
#       Note: If the pattern matches
#             - more than one git config file names, script defaults to the first among the matches.
#             - none of the git config file names, script falls back to the first among all git configs.

function prepend_filename() {
    local FILE_NAME_SHORT=$(basename $0)
    echo "[*${FILE_NAME_SHORT}] $@"
}

function switch_gitconfig() {
    # Variables
    local SETUP_GITCONFIG_SCRIPT_PATH="${PWD}/setup-gitconfig.sh"
    local SETUP_GITCONFIG_SCRIPT_PATH_SHORT=$(basename ${SETUP_GITCONFIG_SCRIPT_PATH})
    local ALL_GITCONFIGS=($(ls ${PWD}/*.gitconfig.env | grep -v 'sample.gitconfig.env'))
    local CURRENT_GITCONFIG=$(git config --global user.configname)
    local NEXT_GITCONFIG=

    # Determine git config sspecified in input
    if [ ! -z ${PATTERN} ]; then
        local MATCHED_GITCONFIGS=($(printf -- '%s\n' ${ALL_GITCONFIGS[@]} | grep "$PATTERN"))
        if [ ${#MATCHED_GITCONFIGS[@]} -eq 0 ]; then
            echo "Pattern \"${PATTERN}\" didn't match any git configs from ${ALL_GITCONFIGS[@]}"
            echo "Falling back to ${ALL_GITCONFIGS[0]}"
            NEXT_GITCONFIG=${ALL_GITCONFIGS[0]}
        elif [ ${#MATCHED_GITCONFIGS[@]} -eq 1 ]; then
            echo "Pattern \"${PATTERN}\" matched ${MATCHED_GITCONFIGS[0]}"
            NEXT_GITCONFIG=${MATCHED_GITCONFIGS[0]}
        else
            echo "Pattern \"${PATTERN}\" matched all these git configs: ${MATCHED_GITCONFIGS[@]}"
            echo "Defaulting to ${MATCHED_GITCONFIGS[0]}"
            NEXT_GITCONFIG=${MATCHED_GITCONFIGS[0]}
        fi
    fi

    # Derive Next Git Config
    if [ -z "${NEXT_GITCONFIG}" ]; then
        if [ -z "${CURRENT_GITCONFIG}" ]; then
            NEXT_GITCONFIG=${ALL_GITCONFIGS[0]}
        else
            local FOUND_CURRENT=false
            local INDEX=0
            while true; do
                # Variable(s)
                local GITCONFIG=${ALL_GITCONFIGS[$INDEX]}

                # When the current (in system) git config is found in the list in the last iteration, note the
                # current (in loop) git config as next git config to switch to, and break.
                if [ ${FOUND_CURRENT} == true ]; then
                    NEXT_GITCONFIG=${GITCONFIG}

                    break
                fi

                # When current (in loop) git config matches current (in system) git config, mark the flag FOUND_CURRENT as found.
                if [ ${GITCONFIG} == ${CURRENT_GITCONFIG} ]; then
                    FOUND_CURRENT=true
                fi

                # Increment the index. If index exceeds the count of items in the list, make it zero so that it iterated from
                # the start again. This helps when the last git config in the list is the current (in system) git config, and
                # the script has to switch to first git config in the list.
                ((INDEX+=1))
                if [ ${INDEX} == ${#ALL_GITCONFIGS[@]} ]; then
                    INDEX=0
                fi
            done
        fi
    fi
    prepend_filename "Current Git Config: ${CURRENT_GITCONFIG}" | sed -e "s|${HOME}|~|g"
    prepend_filename "Next Git Config: ${NEXT_GITCONFIG}" | sed -e "s|${HOME}|~|g"

    # Switch to Next Git Config
    if [ "${CURRENT_GITCONFIG}" == "${NEXT_GITCONFIG}" ]; then
        prepend_filename "Git already on ${NEXT_GITCONFIG}. Overwriting for updates in config."
    fi
    CONFIG_FILE=${NEXT_GITCONFIG} bash ${SETUP_GITCONFIG_SCRIPT_PATH} 2>&1 | sed "s|^| ↳ [${SETUP_GITCONFIG_SCRIPT_PATH_SHORT}] |g"
    prepend_filename "Switched to Git Config: ${NEXT_GITCONFIG}" | sed -e "s|${HOME}|~|g"
}

# Set shell options
set -e

# Main flow
PATTERN=$1 switch_gitconfig

# Unset shell options
set +e
