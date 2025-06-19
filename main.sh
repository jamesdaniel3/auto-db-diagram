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

cleanup() {
    tput cnorm  # restore cursor in the event that the user quits while cursor is hidden
    exit 0
}

# exit scenarios
trap cleanup INT       # ctrl+C
trap cleanup TERM      # termination signal
trap cleanup QUIT      # quit signal

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
    
    echo "Attempting to open ERD diagram..."
    
    # Detect OS and try appropriate open command
    case "$(uname -s)" in
        Darwin)
            # macOS
            if command -v open >/dev/null 2>&1; then
                open "$image_file" && echo "Opened $image_file with default viewer"
            else
                echo "Note: 'open' command not available on macOS"
            fi
            ;;
        Linux)
            # Linux - try various methods
            if command -v xdg-open >/dev/null 2>&1 && [ -n "$DISPLAY" ]; then
                xdg-open "$image_file" && echo "Opened $image_file with default viewer"
            elif command -v gnome-open >/dev/null 2>&1 && [ -n "$DISPLAY" ]; then
                gnome-open "$image_file" && echo "Opened $image_file with GNOME viewer"
            elif command -v kde-open >/dev/null 2>&1 && [ -n "$DISPLAY" ]; then
                kde-open "$image_file" && echo "Opened $image_file with KDE viewer"
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
    
    echo "Generating PNG from DOT file..."
    if dot -Tpng "$dot_file" -o "$png_file"; then
        echo "ERD diagram generated"
        
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
        echo "Running visualization script..."
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
        
        # clean up the JSON output file if visualization successful
        if [ -f "$OUTPUT_FILE" ]; then
            rm "$OUTPUT_FILE"
            echo "Cleaned up intermediate file: $OUTPUT_FILE"
        fi
    else
        echo "Note: visualize.py not found. Output saved to '$OUTPUT_FILE'"
        echo "You can manually process the schema data from this file"
        return 1
    fi
}

run_headless_mode() {
    local config_file="$1"

    [ ! -f "$config_file" ] && error "Config file '$config_file' does not exist"

    echo "Running in headless mode with config: $config_file"
    
    # check required tools
    check_tool jq
    check_tool psql
    check_tool dot  # for Graphviz

    parse_config "$config_file"
    validate_config

    # load DB-specific handlers
    case "$DATABASE_TYPE" in
        postgres)
            source "$SCRIPT_DIR/lib/database/postgres.sh"
            echo "Extracting PostgreSQL schema..."
            if ! run_postgres_extraction; then
                error "Failed to extract PostgreSQL schema"
            fi
            ;;
        sqlite)
            source "$SCRIPT_DIR/lib/database/sqlite.sh"
            echo "Extracting SQLite schema..."
            if ! run_sqlite_extraction; then 
                error "Failed to extract SQLite scheam;"
            fi
            ;;
        *)
            error "Unsupported database type: $DATABASE_TYPE"
            ;;
    esac

    # Run visualization
    if ! run_visualization; then
        error "Failed to generate visualization"
    fi

    # Generate ERD diagram
    if ! generate_erd_diagram; then
        error "Failed to generate ERD diagram"
    fi
}

run_interactive_mode() {
    # check required tools
    check_tool psql
    check_tool dot  # for Graphviz

    get_database_config

    # load DB-specific handlers
    case "$DATABASE_TYPE" in
        postgres)
            source "$SCRIPT_DIR/lib/database/postgres.sh"
            echo "Extracting PostgreSQL schema..."
            if ! run_postgres_extraction; then
                error "Failed to extract PostgreSQL schema"
            fi
            ;;
        sqlite)
            source "$SCRIPT_DIR/lib/database/sqlite.sh"
            echo "Extracting SQLite schema..."
            if ! run_sqlite_extraction; then
                error "Failed to extract SQLite schema"
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