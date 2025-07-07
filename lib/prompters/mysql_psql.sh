#!/bin/bash
get_mysql_or_psql_config() {
    local db_type="$1"
    local default_port
    local username_label
    local password_label
    
    case "$db_type" in
        "postgres")
            default_port="5432"
            username_label="database username"
            password_label="database password"
            ;;
        "mysql")
            default_port="3306"
            username_label="mySQL username"
            password_label="mySQL password"
            ;;
        *)
            echo "Error: Unsupported database type '$db_type'"
            return 1
            ;;
    esac
    
    read -rp "Enter your database host (default: localhost): " HOST
    [ -z "$HOST" ] && HOST="localhost"

    while true; do
        read -rp "Enter your database port (default: $default_port): " PORT
        [ -z "$PORT" ] && PORT="$default_port"

        if [[ "$PORT" =~ ^[0-9]+$ ]] && [ "$PORT" -ge 1 ] && [ "$PORT" -le 65535 ]; then
            break
        else
            echo "Invalid port number. Please enter a valid port (1-65535)."
        fi
    done

    if [[ "$db_type" == "mysql" ]]; then
        read -rp "Enter your $username_label (default: root): " USERNAME
        [ -z "$USERNAME" ] && USERNAME="root"
    else
        while true; do
            read -rp "Enter your $username_label: " USERNAME
            if [ -n "$USERNAME" ]; then
                break
            else 
                echo "A $username_label is required."
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

    read -s -rp "Enter your $password_label (press Enter if none required): " PASSWORD
    echo
}