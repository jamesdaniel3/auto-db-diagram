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

    # Parse connection info (case-insensitive field names)
    HOST=$(jq -r '
        .connection_info // {} | 
        to_entries | 
        map(select(.key | ascii_downcase == "host")) | 
        .[0].value // empty
    ' "$CONFIG_FILE")
    
    PORT=$(jq -r '
        .connection_info // .connection // {} | 
        to_entries | 
        map(select(.key | ascii_downcase == "port")) | 
        .[0].value // empty
    ' "$CONFIG_FILE")
    
    USERNAME=$(jq -r '
        .connection_info // .connection // {} | 
        to_entries | 
        map(select(.key | ascii_downcase == "username")) | 
        .[0].value // empty
    ' "$CONFIG_FILE")
    
    DATABASE_NAME=$(jq -r '
        .connection_info // .connection // {} | 
        to_entries | 
        map(select(.key | ascii_downcase == "database_name")) | 
        .[0].value // empty
    ' "$CONFIG_FILE")
    
    PASSWORD=$(jq -r '
        .connection_info // .connection // {} | 
        to_entries | 
        map(select(.key | ascii_downcase == "password")) | 
        .[0].value // empty
    ' "$CONFIG_FILE")

    # Parse output file (optional, case-insensitive)
    OUTPUT_FILE=$(jq -r '
        to_entries | 
        map(select(.key | ascii_downcase == "output_file")) | 
        .[0].value // "database_schema.json"
    ' "$CONFIG_FILE")

    # Validate required fields
    if [ -z "$HOST" ] || [ "$HOST" = "null" ]; then
        error "Missing or invalid 'host' field in connection info"
    fi
    
    if [ -z "$PORT" ] || [ "$PORT" = "null" ]; then
        error "Missing or invalid 'port' field in connection info"
    fi
    
    if [ -z "$USERNAME" ] || [ "$USERNAME" = "null" ]; then
        error "Missing or invalid 'username' field in connection info"
    fi
    
    if [ -z "$DATABASE_NAME" ] || [ "$DATABASE_NAME" = "null" ]; then
        error "Missing or invalid 'database_name' field in connection info"
    fi
}