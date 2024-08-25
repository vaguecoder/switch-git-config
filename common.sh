#!/usr/bin/env bash

function prepend_filename() {
    local FILE_NAME_SHORT=$(basename $0)
    echo -e "[${FILE_NAME_SHORT}] $@"
}

function print_yellow() {
    prepend_filename "\033[1;33m$@\033[0m"
}

function print_red() {
    prepend_filename "\033[1;31m$@\033[0m"
}

function print_blue() {
    prepend_filename "\033[1;34m$@\033[0m"
}
