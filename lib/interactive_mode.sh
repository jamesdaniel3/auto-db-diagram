#!/bin/bash

DATABASE_TYPE=""
DB_HOST=""
DB_PORT=""
DB_USERNAME=""
DB_NAME=""
DB_PASSWORD=""

declare -A DATABASE_TYPES=(
    ["postgres"]="PostgreSQL"
)

show_database_menu() {
    echo "Select the type of database you want to connect to?"
    echo

    local options=()
    local keys=()

    for key in "${!DATABASE_TYPES[@]}"; do 
        options+=("${DATABASE_TYPES[$key]}")
        keys+=("$key")
    done 

    local selected=0
    local total=${#options[@]}

    # hide cursor
    tput civis 

    draw_menu() {
        tput cup $((BASH_LINENO[1] + 2)) 0

        for i in "${!options[@]}"; do
            if [ $i -eq $selected ]; then
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

                        tput cuu $total
                        draw_menu
                        ;;
                    '[B') # down arrow 
                        ((selected++))
                        if [ $selected -ge $total ]; then
                            selected=0
                        fi

                        tput cuu $total
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

get_postgres_config() {
    read -p "Enter your database host (default: localhost): " DB_HOST
    [ -z "$DB_HOST" ] && DB_HOST="local_host"

    while true; do
        read -p "Enter your database port (default: 5432): " DB_PORT
        [ -z "$DB_PORT" ] && DB_PORT="5432"

        if [[ "$DB_PORT" =~ ^[0-9]+$ ]] && [ "$DB_PORT" -ge 1 ] && [ "$DB_PORT" -le 65535 ]; then
            break
        else
            echo "Invalid port number. Please enter a valid port (1-65535)."
        fi
    done

    while true; do
        read -p "Enter your databse username: " DB_USERNAME
        if [ -n "$DB_USERNAME" ]; then
            break
        else 
            echo "Database username is required."
        fi
    done

    while true; do
        read -p "Enter your database name: " DB_NAME
        if [ -n "$DB_NAME" ]; then 
            break
        else
            echo "Database name is required."
        fi
    done

    echo
    read -s -p "Enter your database password (press Enter if none required): " DB_PASSWORD
    echo


}

get_database_config() {
    clear 
    
    show_database_menu

    case "$DATABSE_TYPE" in
        postgres)
            get_postgres_config
            ;;
        *)
            error "Configuration for database type '$DATABASE_TYPE' is not currently supported"
            exit 1
    esac

}

create_temp_config() {
    local config_file="$1"
    
    case "$DATABASE_TYPE" in
        postgres)
            cat > "$config_file" << EOF
{
    "database_type": "postgres",
    "connection": {
        "host": "$DB_HOST",
        "port": $DB_PORT,
        "username": "$DB_USERNAME",
        "database": "$DB_NAME",
        "password": "$DB_PASSWORD"
    },
    "output_file": "database_schema.json"
}
EOF
            ;;
        *)
            error "Config generation for database type '$DATABASE_TYPE' is not implemented yet"
            exit 1
            ;;
    esac
}