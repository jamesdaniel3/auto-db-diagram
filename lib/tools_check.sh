#!/bin/bash

check_tool() {
    if ! command -v "$1" &>/dev/null; then
        if [ -n "$2" ]; then
            error "$2"
        fi 
        error "$1 is not installed or not in PATH"
    fi
}
