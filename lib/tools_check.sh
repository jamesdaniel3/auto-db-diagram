#!/bin/bash

check_tool() {
    if ! command -v "$1" &>/dev/null; then
        error "$1 is not installed or not in PATH"
    fi
}
