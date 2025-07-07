#!/bin/bash

yn_to_bool() {
    local response="$1"
    case "$response" in
        [Yy][Ee][Ss]|[Yy])
            echo "true"
            ;;
        *)
            echo "false"
            ;;
    esac
}

get_mongo_config() {

    read -rp "Enter your MongoDB connection string (optional, leave blank to configure manually): " USER_CONNECTION_STRING

    if [ -z "$USER_CONNECTION_STRING" ]; then
        read -rp "Enter your cluster host (default: localhost): " HOST
        [ -z "$HOST" ] && HOST="localhost"

        while true; do
            read -rp "Enter your cluster port (default: 27017): " PORT
            [ -z "$PORT" ] && PORT="27017"

            if [[ "$PORT" =~ ^[0-9]+$ ]] && [ "$PORT" -ge 1 ] && [ "$PORT" -le 65535 ]; then
                break
            else
                echo "Invalid port number. Please enter a valid port (1-65535)."
            fi
        done
    fi

    
    while true; do
        read -rp "Enter your database name: " DATABASE_NAME
        if [ -n "$DATABASE_NAME" ]; then 
            break
        else
            echo "Database name is required."
        fi
    done


    if [ -z "$USER_CONNECTION_STRING" ]; then
        read -rp "Does your cluster use +srv format? (yes/y): " CONNECT_WITH_SERVICE_RECORD

        read -rp "Enter your username (leave blank if no authentication required): " USERNAME

        read -s -rp "Enter your password (leave blank if no authentication required): " PASSWORD
        echo
    fi

    read -rp "Does your MongoDB cluster require SSL/TLS? (yes/y): " SSL_ENABLED
    read -rp "Allow invalid SSL certificates? (yes/y, typically only for development): " SSL_ALLOW_INVALID_CERTS
    read -rp "CA certificate file path (leave blank if not required): " SSL_CA_FILE_PATH
    read -rp "Client certificate file path (leave blank if not required): " SSL_CLIENT_CERT_PATH

    read -rp 'Analyze all documents in each collection? (yes for complete analysis, no for sample of 100): ' EXHAUSTIVE_SEARCH

    # Convert yes/no responses to true/false using the helper function
    EXHAUSTIVE_SEARCH=$(yn_to_bool "$EXHAUSTIVE_SEARCH")
    CONNECT_WITH_SERVICE_RECORD=$(yn_to_bool "$CONNECT_WITH_SERVICE_RECORD")
    SSL_ENABLED=$(yn_to_bool "$SSL_ENABLED")
    SSL_ALLOW_INVALID_CERTS=$(yn_to_bool "$SSL_ALLOW_INVALID_CERTS")
}