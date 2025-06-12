#!/bin/bash

run_postgres_extraction() {
    local SCRIPT_DIR="$1"
    local QUERY_FILE="$SCRIPT_DIR/queries/postgres.sql"
    local OUTPUT_FILE="${DATABASE_NAME}_schema.json"

    if [ ! -f "$QUERY_FILE" ]; then
        error "Query file not found: $QUERY_FILE"
    fi

    QUERY=$(<"$QUERY_FILE")
    
    echo "Connecting to $DATABASE_TYPE at $HOST:$PORT..."

    if PGPASSWORD="" psql -h "$HOST" -p "$PORT" -U "$USERNAME" -d "$DATABASE_NAME" -t -c "$QUERY" -o "$OUTPUT_FILE" 2>/dev/null; then
        echo "Schema extracted to '$OUTPUT_FILE'"
    else
        echo "Password prompt likely required..."
        if ! psql -h "$HOST" -p "$PORT" -U "$USERNAME" -d "$DATABASE_NAME" -t -c "$QUERY" -o "$OUTPUT_FILE"; then
            error "Failed to connect to database or execute query"
        fi
    fi

    jq '.' "$OUTPUT_FILE" > "${OUTPUT_FILE}.tmp" && mv "${OUTPUT_FILE}.tmp" "$OUTPUT_FILE"
}

