#!/bin/bash

parse_config() {
    local config_file="$1"

    if ! jq empty "$config_file" 2>/dev/null; then
        error "'$config_file' is not valid JSON"
    fi

    DATABASE_TYPE=$(jq -r '
        to_entries | 
        map(select(.key | ascii_downcase == "database_type")) | 
        .[0].value // empty
    ' "$config_file")

    CONNECTION_INFO=$(jq -r '
        to_entries |
        map(select(.key | ascii_downcase == "connection_info")) |
        .[0].value
    ' "$config_file")

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

    USER_CONNECTION_STRING=$(jq -r '
        to_entries |
        map(select(.key | ascii_downcase == "connection_string")) |
        .[0].value // empty
    ' <<< "$CONNECTION_INFO")

    SSL_ENABLED=$(jq -r '
        to_entries |
        map(select(.key | ascii_downcase == "ssl_enabled")) |
        .[0].value // empty
    ' <<< "$CONNECTION_INFO")

    SSL_ALLOW_INVALID_CERTS=$(jq -r '
        to_entries |
        map(select(.key | ascii_downcase == "ssl_allow_invalid_certs")) |
        .[0].value // "false"
    ' <<< "$CONNECTION_INFO")

    CONNECT_WITH_SERVICE_RECORD=$(jq -r '
        to_entries |
        map(select(.key | ascii_downcase == "connect_with_service_record")) |
        .[0].value // "false"
    ' <<< "$CONNECTION_INFO")

    SSL_CA_FILE_PATH=$(jq -r '
        to_entries |
        map(select(.key | ascii_downcase == "ssl_ca_file_path")) |
        .[0].value // empty
    ' <<< "$CONNECTION_INFO")

    SSL_CLIENT_CERT_PATH=$(jq -r '
        to_entries |
        map(select(.key | ascii_downcase == "ssl_client_cert_path")) |
        .[0].value // empty
    ' <<< "$CONNECTION_INFO")

    EXCLUDED_TABLES=()
    while IFS= read -r table; do
        [[ -n "$table" ]] && EXCLUDED_TABLES+=("$table")
    done < <(jq -r '
        to_entries | 
        map(select(.key | ascii_downcase == "excluded_tables")) | 
        .[0].value[]? // empty
    ' "$config_file")

    OUTPUT_FILE=$(jq -r '
        to_entries | 
        map(select(.key | ascii_downcase == "output_file")) | 
        .[0].value // "database_schema.json"
    ' "$config_file")

    EXHAUSTIVE_SEARCH=$(jq -r '
        to_entries | 
        map(select(.key | ascii_downcase == "exhaustive_search")) | 
        .[0].value // "false"
    ' "$config_file")
}
