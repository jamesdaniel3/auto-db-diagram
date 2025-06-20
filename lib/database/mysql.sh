#!/bin/bash

run_mysql_extraction() {
    local QUERY_FILE="$SCRIPT_DIR/queries/mysql.sql"
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
    
    # try connection using mysql command with options
    if mysql -h "$HOST" -P "$PORT" -u "$USERNAME" -p"$PASSWORD" -D "$DATABASE_NAME" -e "$QUERY" --batch --raw --skip-column-names > "$OUTPUT_FILE" 2>/dev/null; then
        echo "Schema extracted to '$OUTPUT_FILE'"
    else
        if [ -z "$PASSWORD" ]; then
            echo "Connection failed, trying with password prompt..."
            # fallback to password prompt method
            if ! mysql -h "$HOST" -P "$PORT" -u "$USERNAME" -p -D "$DATABASE_NAME" -e "$QUERY" --batch --raw --skip-column-names > "$OUTPUT_FILE"; then
                error "Failed to connect to database or execute query"
            fi
        else
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