#!/bin/bash

validate_config() {
    if [ -z "$DATABASE_TYPE" ] || [ "$DATABASE_TYPE" = "null" ]; then
        error "Missing or invalid 'database_type' field in config"
    fi

    case "$DATABASE_TYPE" in 
        "postgres"|"mysql")
            if [ -z "$HOST" ] || [ "$HOST" = "null" ]; then
                error "Missing or invalid 'host' field in connection_info"
            fi
            
            if [ -z "$PORT" ] || [ "$PORT" = "null" ]; then
                error "Missing or invalid 'port' field in connection_info"
            fi
            
            if [ -z "$USERNAME" ] || [ "$USERNAME" = "null" ]; then
                error "Missing or invalid 'username' field in connection_info"
            fi
            
            if [ -z "$DATABASE_NAME" ] || [ "$DATABASE_NAME" = "null" ]; then
                error "Missing or invalid 'database_name' field in connection_info"
            fi
            ;;
        sqlite)
            if [ -z "$DATABASE_LOCATION" ] || [ "$DATABASE_LOCATION" = "null" ]; then
                error "Missing or invalid 'database_location' field in connection_info"
            fi
            ;;
        mongodb)
            if [ -z "$HOST" ] || [ "$HOST" = "null" ]; then
                error "Missing or invalid 'host' field in connection_info"
            fi
            
            if [ -z "$PORT" ] || [ "$PORT" = "null" ]; then
                error "Missing or invalid 'port' field in connection_info"
            fi
            ;;
        *)
            error "Configuration for database type '$DATABASE_TYPE' is not currently supported"
            exit 1
            ;;
    esac
}
