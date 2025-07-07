#!/bin/bash

set -eo pipefail

# get the absolute path to the directory where main.sh resides
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# load libraries
source "$SCRIPT_DIR/lib/error_handling.sh"
source "$SCRIPT_DIR/lib/tools_check.sh"
source "$SCRIPT_DIR/lib/config_parser.sh"
source "$SCRIPT_DIR/lib/validate_config.sh"
source "$SCRIPT_DIR/lib/interactive_mode.sh"

cleanup() {
    tput cnorm  # restore cursor in the event that the user quits while cursor is hidden
    rm -f "$OUTPUT_FILE"
    rm -rf "$SCRIPT_DIR/mongo_collections"
    exit 0
}

# exit scenarios
trap cleanup INT TERM QUIT ERR EXIT

show_usage_error_message() {
    echo "Invalid usage of db-diagram, run db-diagram --help for more info or man db-diagram for a full manpage "
    exit 1
}

show_help_message() {
    cat << EOF
db-diagram - Generate ERD diagrams from live database connections

USAGE:
    db-diagram                                   # Interactive mode
    db-diagram --headless <path/to/config.json>  # Headless mode with config

OPTIONS:
    -h, --headless     Use existing JSON config file
    --help             Show this help message

EXAMPLES:
    db-diagram                          # Guided setup
    db-diagram -h my-db-config.json    # Use existing config

CONFIG FILE FORMAT:
    See example config in /config_examples/valid_configs at: https://github.com/jamesdaniel3/auto-db-diagram

EOF
}

open_image_if_possible() {
    local image_file="$1"
    
    # Skip opening if in CI/headless environment
    if [ -n "$CI" ] || [ -n "$GITHUB_ACTIONS" ]; then
        echo "Running in CI environment - skipping image viewer"
        return 0
    fi
    
    if [ ! -f "$image_file" ]; then
        echo "Warning: Image file '$image_file' not found"
        return 1
    fi
    
    # Detect OS and try appropriate open command
    case "$(uname -s)" in
        Darwin)
            # macOS
            if command -v open >/dev/null 2>&1; then
                open "$image_file" 
            else
                echo "Note: 'open' command not available on macOS"
                echo "PNG can be found at the listed filepath"
            fi
            ;;
        Linux)
            # Linux - try various methods
            if command -v xdg-open >/dev/null 2>&1 && [ -n "$DISPLAY" ]; then
                xdg-open "$image_file" 
            elif command -v gnome-open >/dev/null 2>&1 && [ -n "$DISPLAY" ]; then
                gnome-open "$image_file" 
            elif command -v kde-open >/dev/null 2>&1 && [ -n "$DISPLAY" ]; then
                kde-open "$image_file" 
            else
                echo "Note: No GUI available or display not set. $image_file generated successfully."
                echo "To view the image manually:"
                echo "  - Copy $image_file to your local machine"
                echo "  - Or use: display $image_file (if ImageMagick is installed)"
                echo "  - Or use: feh $image_file (if feh is installed)"
            fi
            ;;
        *)
            echo "Note: Unknown OS. $image_file generated successfully at $(pwd)/$image_file"
            ;;
    esac
}

generate_erd_diagram() {
    local dot_file="database_erd.dot"
    local png_file="ERD.png"
    
    if [ ! -f "$dot_file" ]; then
        echo "DOT file '$dot_file' not found"
        echo "Make sure visualize.py successfully generated the DOT file"
        return 1
    fi
    
    if dot -Tpng "$dot_file" -o "$png_file"; then
        
        # show file info
        if [ -f "$png_file" ]; then
            echo "File size: $(ls -lh "$png_file" | awk '{print $5}')"
            echo "File path: $(pwd)/$png_file"
        fi
        
        # attempt to open the image
        open_image_if_possible "$png_file"
        return 0
    else
        echo "Failed to generate PNG from DOT file"
        echo "Manual generation command: dot -Tpng $dot_file -o $png_file"
        return 1
    fi
}

run_visualization() {
    if [ -f "$SCRIPT_DIR/visualize.py" ]; then
        if command -v python3 &>/dev/null; then
            if python3 "$SCRIPT_DIR/visualize.py" "$OUTPUT_FILE"; then
                echo "Visualization script completed successfully"
            else
                echo "Visualization script failed"
                return 1
            fi
        else
            if python "$SCRIPT_DIR/visualize.py" "$OUTPUT_FILE"; then
                echo "Visualization script completed successfully"
            else
                echo "Visualization script failed"
                return 1
            fi
        fi
        
        # clean up the JSON output file 
        if [ -f "$OUTPUT_FILE" ]; then
            rm "$OUTPUT_FILE"
        fi
    else
        echo "Note: visualize.py not found. Output saved to '$OUTPUT_FILE'"
        echo "You can manually process the schema data from this file"
        return 1
    fi
}

run_mode() {
    local mode="$1"
    local config_file="$2"

    case "$mode" in
        "headless")
            [ -z "$config_file" ] && error "Config file required for headless mode"
            [ ! -f "$config_file" ] && error "Config file '$config_file' does not exist"
            
            echo "Running in headless mode with config: $config_file"
            
            check_tool jq
            parse_config "$config_file"
            validate_config
            ;;
        "interactive")
            get_database_config
            ;;
        *)
            error "Invalid mode: $mode. Use 'headless' or 'interactive'"
            ;;
    esac

    check_tool dot  # for Graphviz

    # load DB-specific handlers and run extraction
    case "$DATABASE_TYPE" in
        postgres)
            check_tool psql
            source "$SCRIPT_DIR/lib/database/postgres.sh"
            if ! run_postgres_extraction; then
                error "Failed to extract PostgreSQL schema"
            fi
            ;;
        mysql)
            check_tool mysql
            source "$SCRIPT_DIR/lib/database/mysql.sh"
            if ! run_mysql_extraction; then
                error "Failed to extract MySQL schema"
            fi
            ;;
        sqlite)
            source "$SCRIPT_DIR/lib/database/sqlite.sh"
            if ! run_sqlite_extraction; then 
                error "Failed to extract SQLite schema"
            fi
            ;;
        mongodb)
            mongoexport_error_message=$(cat << 'EOF'
This tool relies on `mongoexport`, which is not part of Homebrew core.
To install it, run:
brew tap mongodb/brew
brew install mongodb-database-tools
EOF
)
            check_tool mongoexport "$mongoexport_error_message"
            check_tool mongosh
            source "$SCRIPT_DIR/lib/database/mongo.sh"
            if ! run_mongo_extraction; then 
                error "Failed to extract MongoDB schema"
            fi
            ;;
        *)
            error "Unsupported database type: $DATABASE_TYPE"
            ;;
    esac

    if ! run_visualization; then
        error "Failed to generate visualization"
    fi

    if ! generate_erd_diagram; then
        error "Failed to generate ERD diagram"
    fi
}

# parse command line args
case $# in 
    0)
        # run in interactive mode 
        run_mode "interactive"
        ;;
    2)
        # confirm headless flag and run headless mode
        if [[ "$1" == "--headless" || "$1" == "-h" ]]; then
            run_mode "headless" "$2"
        else 
            show_usage_error_message
        fi
        ;;
    1)
        if [[ "$1" == "--help" ]]; then
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