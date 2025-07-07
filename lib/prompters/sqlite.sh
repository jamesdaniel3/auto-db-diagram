#!/bin/bash
get_sqlite_config() {
    while true; do
        read -rp "Enter the file path to your .db file: " DATABASE_LOCATION
        if [ -n "$DATABASE_LOCATION" ]; then
            break
        else 
            echo "Database location is required."
        fi
    done
}