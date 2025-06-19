#!/bin/bash

parse_config() {
    CONFIG_FILE="$1"

    if ! jq empty "$CONFIG_FILE" 2>/dev/null; then
        error "'$CONFIG_FILE' is not valid JSON"
    fi

    # Parse database_type (case-insensitive)
    DATABASE_TYPE=$(jq -r '
        to_entries | 
        map(select(.key | ascii_downcase == "database_type")) | 
        .[0].value // empty
    ' "$CONFIG_FILE")
    
    if [ -z "$DATABASE_TYPE" ] || [ "$DATABASE_TYPE" = "null" ]; then
        error "Missing or invalid 'database_type' field in config"
    fi

    # Extract connection_info object (case-insensitive)
    CONNECTION_INFO=$(jq -r '
        to_entries |
        map(select(.key | ascii_downcase == "connection_info")) |
        .[0].value
    ' "$CONFIG_FILE")

    # Parse fields from connection_info (case-insensitive)
    HOST=$(jq -r '
        to_entries |
        map(select(.key | ascii_downcase == "host")) |
        .[0].value // empty
    ' <<< "$CONNECTION_INFO")

    PORT=$(jq -r '
        to_entries |
        map(select(.key | ascii_downcase == "port")) |
        .[0].value // empty
    ' <<< "$CONNECTION_INFO")

    USERNAME=$(jq -r '
        to_entries |
        map(select(.key | ascii_downcase == "username")) |
        .[0].value // empty
    ' <<< "$CONNECTION_INFO")

    DATABASE_NAME=$(jq -r '
        to_entries |
        map(select(.key | ascii_downcase == "database_name")) |
        .[0].value // empty
    ' <<< "$CONNECTION_INFO")

    PASSWORD=$(jq -r '
        to_entries |
        map(select(.key | ascii_downcase == "password")) |
        .[0].value // empty
    ' <<< "$CONNECTION_INFO")

    DATABASE_LOCATION=$(jq -r '
        to_entries |
        map(select(.key | ascii_downcase == "database_location")) |
        .[0].value // empty
    ' <<< "$CONNECTION_INFO")

    # Parse output file (optional, case-insensitive)
    OUTPUT_FILE=$(jq -r '
        to_entries | 
        map(select(.key | ascii_downcase == "output_file")) | 
        .[0].value // "database_schema.json"
    ' "$CONFIG_FILE")
}
