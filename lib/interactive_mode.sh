#!/bin/bash

get_database_display_name() {
    # add more as needed
    case "$1" in
        postgres) echo "PostgreSQL" ;;
        mysql) echo "MySQL" ;;
        sqlite) echo "SQLite" ;;
        mongodb) echo "MongoDB" ;;
        *) echo "Unknown Database" ;;
    esac
}

# available database types
DATABASE_KEYS=("postgres" "sqlite" "mysql" "mongodb")  # add more as needed

show_database_menu() {
    echo "Select the type of database you want to connect to?"
    echo

    local options=()
    local keys=()

    for key in "${DATABASE_KEYS[@]}"; do 
        options+=("$(get_database_display_name "$key")")
        keys+=("$key")
    done

    local selected=0
    local total=${#options[@]}

    # hide cursor
    tput civis 

    draw_menu() {
        for i in "${!options[@]}"; do
            if [ "$i" -eq "${selected}" ]; then
                # green circle and highlighted text for selected item
                echo -e "  \033[32m●\033[0m \033[32m${options[$i]}\033[0m"
            else
                # hollow circle for unselected item
                echo -e "  \033[90m○\033[0m \033[90m${options[$i]}\033[0m"
            fi 
        done
    }

    draw_menu

    while true; do
        read -rsn1 input
        # -r: raw (don't interpret backslashes)
        # -s: silent (don't echo)
        # -n1: read exactly 1 character

        case $input in 
            $'\x1b')  # ESC sequence (arrow keys start with this)
                read -rsn2 input  
                case $input in 
                    '[A') # up arrow
                        ((selected--))
                        if [ $selected -lt 0 ]; then  
                            selected=$((total - 1))  
                        fi

                        tput cuu "${total}"
                        draw_menu
                        ;;
                    '[B') # down arrow 
                        ((selected++))
                        if [ $selected -ge "${total}" ]; then
                            selected=0
                        fi

                        tput cuu "${total}"
                        draw_menu
                        ;;
                esac
                ;;
            '') # enter key
                DATABASE_TYPE="${keys[$selected]}"
                break
                ;;
            'q' | 'Q') # quit
                echo
                echo "Operation cancelled."
                exit 0
                ;;
        esac
    done
}

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

get_mongo_config() {

    read -rp "Enter your database host (default: localhost): " HOST
    [ -z "$HOST" ] && HOST="localhost"

    while true; do
        read -rp "Enter your database port (default: 27017): " PORT
        [ -z "$PORT" ] && PORT="27017"

        if [[ "$PORT" =~ ^[0-9]+$ ]] && [ "$PORT" -ge 1 ] && [ "$PORT" -le 65535 ]; then
            break
        else
            echo "Invalid port number. Please enter a valid port (1-65535)."
        fi
    done
    
    while true; do
        read -rp "Enter your database name: " DATABASE_NAME
        if [ -n "$DATABASE_NAME" ]; then 
            break
        else
            echo "Database name is required."
        fi
    done

    read -rp "Enter your username (press Enter if your database does not requie login): " USERNAME

    read -s -rp "Enter your password (press Enter if your database does not requie login): " PASSWORD
    echo
    
}

get_database_config() {
    clear 
    
    show_database_menu
    tput cnorm

    case "$DATABASE_TYPE" in
        postgres)
            get_mysql_or_psql_config "$DATABASE_TYPE"
            ;;
        mysql)
            get_mysql_or_psql_config "$DATABASE_TYPE"
            ;;
        sqlite)
            get_sqlite_config
            ;;
        mongodb)
            get_mongo_config
            ;;
        *)
            error "Configuration for database type '$DATABASE_TYPE' is not currently supported"
            exit 1
    esac
}