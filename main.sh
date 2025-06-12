#!/bin/bash

set -e

# Get the absolute path to the directory where main.sh resides
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load libraries
source "$SCRIPT_DIR/lib/error_handling.sh"
source "$SCRIPT_DIR/lib/tools_check.sh"
source "$SCRIPT_DIR/lib/config_parser.sh"
source "$SCRIPT_DIR/lib/validate_config.sh"

# Check input
[ $# -eq 0 ] && error "No config file provided. Usage: $0 <path/to/config.json>"

CONFIG_FILE="$1"
[ ! -f "$CONFIG_FILE" ] && error "Config file '$CONFIG_FILE' does not exist"

check_tool jq
check_tool psql

# Parse and validate config
parse_config "$CONFIG_FILE"
validate_config

# Load DB-specific handlers
case "$DATABASE_TYPE" in
    postgres)
        source "$SCRIPT_DIR/lib/database/postgres.sh"
        run_postgres_extraction "$SCRIPT_DIR"
        ;;
    *)
        error "Unsupported database type: $DATABASE_TYPE"
        ;;
esac

# Run visualization 
if [ -f "$SCRIPT_DIR/visualize.py" ]; then
    if command -v python3 &>/dev/null; then
        python3 "$SCRIPT_DIR/visualize.py" "$OUTPUT_FILE"
    else
        python "$SCRIPT_DIR/visualize.py" "$OUTPUT_FILE"
    fi
else
    echo "Note: visualize.py not found. Output saved to '$OUTPUT_FILE'"
fi

