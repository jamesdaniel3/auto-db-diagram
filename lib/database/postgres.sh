#!/bin/bash

run_postgres_extraction() {
    local QUERY_FILE="$SCRIPT_DIR/queries/postgres.sql"
    OUTPUT_FILE="${DATABASE_NAME}_schema.json"

    if [ ! -f "$QUERY_FILE" ]; then
        error "Query file not found: $QUERY_FILE"
    fi

    EXCLUSION_CONDITION=""
    if [ ${#EXCLUDED_TABLES[@]} -gt 0 ]; then
        EXCLUDED_LIST=$(printf "'%s'," "${EXCLUDED_TABLES[@]}")
        EXCLUDED_LIST="${EXCLUDED_LIST%,}" 
        EXCLUSION_CONDITION="AND t.table_name NOT IN (${EXCLUDED_LIST})"
    fi

    QUERY=$(<"$QUERY_FILE")
    QUERY="${QUERY//--EXCLUSION_PLACEHOLDER--/$EXCLUSION_CONDITION}"
    
    echo "Connecting to $DATABASE_TYPE at $HOST:$PORT..."

    CONNECTION_STRING="postgresql://$USERNAME:$PASSWORD@$HOST:$PORT/$DATABASE_NAME"
    
    # try connection using connection string
    if psql "$CONNECTION_STRING" -t -c "$QUERY" -o "$OUTPUT_FILE" 2>/dev/null; then
        echo "Schema extracted to '$OUTPUT_FILE'"
    else
        echo "Connection failed, trying with environment variable..."
        # fallback to environment variable method
        if ! PGPASSWORD="$PASSWORD" psql -h "$HOST" -p "$PORT" -U "$USERNAME" -d "$DATABASE_NAME" -t -c "$QUERY" -o "$OUTPUT_FILE"; then
            error "Failed to connect to database or execute query"
        fi
    fi

    # format JSON output
    if command -v jq >/dev/null 2>&1; then
        jq '.' "$OUTPUT_FILE" > "${OUTPUT_FILE}.tmp" && mv "${OUTPUT_FILE}.tmp" "$OUTPUT_FILE"
    else
        echo "Warning: jq not found, JSON output not formatted"
    fi
}