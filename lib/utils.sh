#!/bin/bash

error() {
    echo "Error: $1" >&2
    exit 1
}

warn() {
    echo "Warning: $1" >&2
}

check_tool() {
    if ! command -v "$1" &>/dev/null; then
        if [ -n "$2" ]; then
            error "$2"
        fi 
        error "$1 is not installed or not in PATH"
    fi
}