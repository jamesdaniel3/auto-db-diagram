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
DATABASE_KEYS=("postgres" "sqlite" "mysql" "mongodb") 

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

get_database_config() {
    clear 
    
    show_database_menu
    tput cnorm

    case "$DATABASE_TYPE" in
        postgres)
            source "$SCRIPT_DIR/lib/prompters/mysql_psql.sh"
            get_mysql_or_psql_config "$DATABASE_TYPE"
            ;;
        mysql)
            source "$SCRIPT_DIR/lib/prompters/mysql_psql.sh"
            get_mysql_or_psql_config "$DATABASE_TYPE"
            ;;
        sqlite)
            source "$SCRIPT_DIR/lib/prompters/sqlite.sh"
            get_sqlite_config
            ;;
        mongodb)
            source "$SCRIPT_DIR/lib/prompters/mongo.sh"
            get_mongo_config
            ;;
        *)
            error "Configuration for database type '$DATABASE_TYPE' is not currently supported"
            exit 1
    esac
}