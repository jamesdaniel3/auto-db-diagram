#!/bin/bash

parse_config() {
    CONFIG_FILE="$1"

    if ! jq empty "$CONFIG_FILE" 2>/dev/null; then
        error "'$CONFIG_FILE' is not valid JSON"
    fi

    DATABASE_TYPE=$(jq -r '.DATABASE_TYPE' "$CONFIG_FILE")
    HOST=$(jq -r '.HOST' "$CONFIG_FILE")
    PORT=$(jq -r '.PORT' "$CONFIG_FILE")
    USERNAME=$(jq -r '.USERNAME' "$CONFIG_FILE")
    DATABASE_NAME=$(jq -r '.DATABASE_NAME' "$CONFIG_FILE")
}
