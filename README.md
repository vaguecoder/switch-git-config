# Switch Git Config
Scripts for switching git config in local Linux environment. (Only tested on Ubuntu)

## Prerequisites
1. Bash shell
2. The script [setup-gitconfig.sh](setup-gitconfig.sh) should be in the same directory.
3. The git config env files per each profile should be in the same directory. This will be discussed in usage section below.

## Usage
1. Add your git configs of a profile in the current directory with 
    - naming `*.gitconfig.env`, eg.,
        - abc.gitconfig.env
        - def.gitconfig.env<br>
    - For sample, refer [sample.gitconfig.env](sample.gitconfig.env) file.
    > Note: [sample.gitconfig.env](sample.gitconfig.env) will be ignored by the script.
2. Make the script executable [switch-gitconfig.sh](switch-gitconfig.sh). The script runs in a bash shell.
    ```
    chmod +x switch-gitconfig.sh
    ```
3. Run the script [switch-gitconfig.sh](switch-gitconfig.sh):
    1. To switch to next git config in circular order:
        ```
        ./switch-gitconfig.sh
        ```
    2. To switch to specific git config:
        ```
        ./switch-gitconfig.sh <file-name-pattern>
        ```
        - Note: If the pattern matches
            - more than one git config file names, script defaults to the first among the matches.
            - none of the git config file names, script falls back to the first among all git configs.
