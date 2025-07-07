#!/bin/bash

run_mongo_extraction() {
    OUTPUT_FILE="${DATABASE_NAME}_schema.json"

    DATA_DIR="$SCRIPT_DIR/mongo_collections"
    mkdir -p "$DATA_DIR"
    
    build_connection_string_and_flags

    EXCLUDE_PATTERN=$(IFS='|'; echo "${EXCLUDED_TABLES[*]}")

    COLLECTIONS=$(mongosh "$CONNECTION_STRING" $MONGOSH_FLAGS --quiet --eval "
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
                $MONGOEXPORT_FLAGS \
                --out="$DATA_DIR/${collection}.json"
        fi
    done <<< "$COLLECTIONS"

    local extracted_at
    extracted_at=$(date -Iseconds)

    echo "Export completed. Generating schema..."

    generate_schema_header

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

build_connection_string_and_flags() {
    MONGOSH_FLAGS=""
    MONGOEXPORT_FLAGS=""
    
    if [[ -n "$USER_CONNECTION_STRING" ]]; then
        if [[ "$USER_CONNECTION_STRING" =~ mongodb\+srv:// ]] && [[ ! "$USER_CONNECTION_STRING" =~ /[^?]+ ]]; then
            USER_CONNECTION_STRING="${USER_CONNECTION_STRING%\?*}/${DATABASE_NAME}?${USER_CONNECTION_STRING#*\?}"
        fi
        CONNECTION_STRING="$USER_CONNECTION_STRING"
    else
        build_connection_string_from_components
    fi
    
    add_ssl_flags
}

build_connection_string_from_components() {
    local protocol="mongodb"
    
    if [[ "$CONNECT_WITH_SERVICE_RECORD" == "true" ]]; then
        protocol="mongodb+srv"
    fi
    
    CONNECTION_STRING="${protocol}://"
    
    if [[ -n "$USERNAME" && -n "$PASSWORD" ]]; then
        CONNECTION_STRING="${CONNECTION_STRING}${USERNAME}:${PASSWORD}@"
    elif [[ -n "$USERNAME" ]]; then
        CONNECTION_STRING="${CONNECTION_STRING}${USERNAME}@"
    fi
    
    CONNECTION_STRING="${CONNECTION_STRING}${HOST}"
    
    if [[ "$CONNECT_WITH_SERVICE_RECORD" != "true" ]]; then
        CONNECTION_STRING="${CONNECTION_STRING}:${PORT}"
    fi
    
    CONNECTION_STRING="${CONNECTION_STRING}/${DATABASE_NAME}"
    
    local query_params=()
    
    if [[ "$SSL_ENABLED" == "true" ]]; then
        query_params+=("ssl=true")
    fi
    
    if [[ "$SSL_ALLOW_INVALID_CERTS" == "true" ]]; then
        query_params+=("sslAllowInvalidCertificates=true")
    fi
    
    if [[ -n "$USERNAME" ]]; then
        query_params+=("authSource=admin")
    fi
    
    if [[ ${#query_params[@]} -gt 0 ]]; then
        local query_string
        query_string=$(IFS='&'; echo "${query_params[*]}")
        CONNECTION_STRING="${CONNECTION_STRING}?${query_string}"
    fi
}

add_ssl_flags() {
    if [[ "$SSL_ENABLED" == "true" ]]; then
        MONGOSH_FLAGS="$MONGOSH_FLAGS --tls"
        MONGOEXPORT_FLAGS="$MONGOEXPORT_FLAGS --ssl"
        
        if [[ "$SSL_ALLOW_INVALID_CERTS" == "true" ]]; then
            MONGOSH_FLAGS="$MONGOSH_FLAGS --tlsAllowInvalidCertificates"
            MONGOEXPORT_FLAGS="$MONGOEXPORT_FLAGS --sslAllowInvalidCertificates"
        fi
        
        if [[ -n "$SSL_CA_FILE_PATH" ]]; then
            MONGOSH_FLAGS="$MONGOSH_FLAGS --tlsCAFile \"$SSL_CA_FILE_PATH\""
            MONGOEXPORT_FLAGS="$MONGOEXPORT_FLAGS --sslCAFile \"$SSL_CA_FILE_PATH\""
        fi
        
        if [[ -n "$SSL_CLIENT_CERT_PATH" ]]; then
            MONGOSH_FLAGS="$MONGOSH_FLAGS --tlsCertificateKeyFile \"$SSL_CLIENT_CERT_PATH\""
            MONGOEXPORT_FLAGS="$MONGOEXPORT_FLAGS --sslPEMKeyFile \"$SSL_CLIENT_CERT_PATH\""
        fi
    fi
}

generate_schema_header() {
    local display_host="$HOST"
    local display_port="$PORT"
    
    if [[ -n "$USER_CONNECTION_STRING" ]]; then
        # if using connection string, try to extract host/port for display
        if [[ "$USER_CONNECTION_STRING" =~ mongodb(\+srv)?://([^:/@]+)(:([0-9]+))?@ ]]; then
            display_host="${BASH_REMATCH[2]}"
            if [[ -n "${BASH_REMATCH[4]}" ]]; then
                display_port="${BASH_REMATCH[4]}"
            elif [[ "$USER_CONNECTION_STRING" =~ mongodb\+srv ]]; then
                display_port="N/A (SRV)"
            fi
        elif [[ "$USER_CONNECTION_STRING" =~ mongodb(\+srv)?://([^:/@]+)(:([0-9]+))?/ ]]; then
            display_host="${BASH_REMATCH[2]}"
            if [[ -n "${BASH_REMATCH[4]}" ]]; then
                display_port="${BASH_REMATCH[4]}"
            elif [[ "$USER_CONNECTION_STRING" =~ mongodb\+srv ]]; then
                display_port="N/A (SRV)"
            fi
        else
            display_host="Provided via connection string"
            display_port="N/A"
        fi
    fi

    cat > "$OUTPUT_FILE" << EOF 
{
    "database_info": {
        "database_name": "$DATABASE_NAME",
        "database_type": "$DATABASE_TYPE",
        "host": "$display_host",
        "port": "$display_port",
        "extracted_at": "$extracted_at"
    },
    "tables": [
EOF
}