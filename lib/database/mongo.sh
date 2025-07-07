#!/bin/bash

run_mongo_extraction() {
    OUTPUT_FILE="${DATABASE_NAME}_schema.json"

    DATA_DIR="$SCRIPT_DIR/mongo_collections"
    mkdir -p "$DATA_DIR"
    
    if [ -n "$USER_CONNECTION_STRING" ]; then
        CONNECTION_STRING="$USER_CONNECTION_STRING"
        echo "Connecting to MongoDB at $USER_CONNECTION_STRING..."
    else
        # this does not handle +srv or auth 
        CONNECTION_STRING="mongodb://$HOST:$PORT"
        echo "Connecting to MongoDB at $HOST:$PORT..."
    fi

    EXCLUDE_PATTERN=$(IFS='|'; echo "${EXCLUDED_TABLES[*]}")

    COLLECTIONS=$(mongosh "$CONNECTION_STRING" --quiet --eval "
        db = db.getSiblingDB('$DATABASE_NAME');
        db.runCommand('listCollections').cursor.firstBatch.forEach(
            function(collection) {print(collection.name)}
        );
    " | grep -v -E "^($EXCLUDE_PATTERN)$")

    if [[ "$EXHAUSTIVE_SEARCH" == "true" ]]; then
        LIMIT_FLAG=""
        echo "Running exhaustive search (no limit)"
    else
        LIMIT_FLAG="--limit=100"
    fi

    while IFS= read -r collection; do
        if [[ -n "$collection" ]]; then 
            mongoexport \
                --uri="$CONNECTION_STRING" \
                --db="$DATABASE_NAME" \
                --collection="$collection" \
                --jsonArray \
                --quiet \
                $LIMIT_FLAG \
                --out="$DATA_DIR/${collection}.json"
        fi
    done <<< "$COLLECTIONS"

    local extracted_at
    extracted_at=$(date -Iseconds)

    echo "Export completed. Generating schema..."

    cat > "$OUTPUT_FILE" << EOF 
{
    "database_info": {
        "database_name": "$DATABASE_NAME",
        "database_type": "$DATABASE_TYPE",
        "host": "$HOST",
        "port": "$PORT",
        "extracted_at": "$extracted_at"
    },
    "tables": [
EOF

    local first_table=true

    for json_file in "$DATA_DIR"/*.json; do
        if [[ -f "$json_file" ]]; then

            if [[ "$first_table" == false ]]; then
                echo "  ," >> "$OUTPUT_FILE"
            fi
            first_table=false

            python3 "$SCRIPT_DIR/lib/analyze_nosql.py" "$json_file" >> "$OUTPUT_FILE"
        fi
    done

    cat >> "$OUTPUT_FILE" << EOF

  ]
}
EOF

}