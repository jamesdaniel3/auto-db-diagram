#!/bin/bash

set -e

# get the absolute path to the directory where main.sh resides
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# load libraries
source "$SCRIPT_DIR/lib/error_handling.sh"
source "$SCRIPT_DIR/lib/tools_check.sh"
source "$SCRIPT_DIR/lib/config_parser.sh"
source "$SCRIPT_DIR/lib/validate_config.sh"
source "$SCRIPT_DIR/lib/interactive_mode.sh"

show_usage_error_message() {
    echo "Invalid usage of db-diagram, run db-diagram --help for more info or man db-diagram for a full manpage "
    exit 1
}

show_help_message() {
    cat << EOF
db-diagram - Generate ERD diagrams from live database connections

USAGE:
    db-diagram                          # Interactive mode
    db-diagram --headless CONFIG_FILE  # Headless mode with config

OPTIONS:
    -h, --headless     Use existing JSON config file
    --help             Show this help message

EXAMPLES:
    db-diagram                          # Guided setup
    db-diagram -h my-db-config.json    # Use existing config

CONFIG FILE FORMAT:
    See example config at: https://github.com/jamesdaniel3/auto-db-diagram/blob/main/example-config.json

EOF
}



run_headless_mode() {
    local config_file="$1"

    [ ! -f "$config_file" ] && error "Config file '$config_file' does not exist"

    check_tool jq
    check_tool psql

    parse_config "$config_file"
    validate_config

    # load DB-specific handlers
    case "$DATABASE_TYPE" in
        postgres)
            source "$SCRIPT_DIR/lib/database/postgres.sh"
            run_postgres_extraction "$SCRIPT_DIR"
            ;;
        *)
            error "Unsupported database type: $DATABASE_TYPE"
            ;;
    esac

    # run visualization 
    if [ -f "$SCRIPT_DIR/visualize.py" ]; then
        if command -v python3 &>/dev/null; then
            python3 "$SCRIPT_DIR/visualize.py" "$OUTPUT_FILE"
        else
            python "$SCRIPT_DIR/visualize.py" "$OUTPUT_FILE"
        fi
        rm "${OUTPUT_FILE}"
    else
        echo "Note: visualize.py not found. Output saved to '$OUTPUT_FILE'"
    fi


    # generate PNG
    dot -Tpng database_erd.dot -o ERD.png

    # on macOS
    open ERD.png
}

run_interactive_mode() {
    check_tool psql

    get_database_config

    local temp_config
    temp_config=$(mktemp) || error "Failed to create temporary file"

    create_temp_config "$temp_config"

    parse_config "$temp_config"
    validate_config

    # load DB-specific handlers
    case "$DATABASE_TYPE" in
        postgres)
            source "$SCRIPT_DIR/lib/database/postgres.sh"
            run_postgres_extraction "$SCRIPT_DIR"
            ;;
        *)
            error "Unsupported database type: $DATABASE_TYPE"
            ;;
    esac
    
    # run visualization 
    if [ -f "$SCRIPT_DIR/visualize.py" ]; then
        if command -v python3 &>/dev/null; then
            python3 "$SCRIPT_DIR/visualize.py" "$OUTPUT_FILE"
        else
            python "$SCRIPT_DIR/visualize.py" "$OUTPUT_FILE"
        fi
        rm "$OUTPUT_FILE"
    else
        echo "Note: visualize.py not found. Output saved to '$OUTPUT_FILE'"
    fi
    
    # generate PNG
    dot -Tpng database_erd.dot -o ERD.png
    
    # on macOS
    open ERD.png
    
    # clean up temporary config
    rm "$temp_config"
}

# parse command line args
case $# in 
    0)
        # run in interactive mode 
        run_interactive_mode
        ;;
    2)
        # confirm headless flag and run headless mode
        if [[ "$1" == "--headless" || "$1" == "-h" ]]; then
            run_headless_mode "$2"
        else 
            show_usage_error_message
        fi
        ;;
    1)
        if [[ "$1" == "--help" ]]; then
            # need to implement help flag
            show_help_message
        else 
            show_usage_error_message
        fi
        ;;
    *)
        # invalid number of args
        show_usage_error_message
        ;;

esac

