#!/bin/bash

run_sqlite_extraction() {
    # extract database name from filepath for output file
    local DB_NAME
    DB_NAME=$(basename "$DATABASE_LOCATION")  
    DB_NAME=${DB_NAME%%.*}   
    OUTPUT_FILE="${DB_NAME}_schema.json"

    # check if database file exists
    if [ ! -f "$DATABASE_LOCATION" ]; then
        error "Database file not found: $DATABASE_LOCATION"
    fi

    # check if sqlite3 is available
    if ! command -v sqlite3 >/dev/null 2>&1; then
        error "sqlite3 command not found. Please install SQLite3."
    fi

    echo "Connecting to SQLite database: $DB_NAME..."
    
    # create temporary files for intermediate data
    local TEMP_DIR
    TEMP_DIR=$(mktemp -d) || error "Failed to create temporary file"
    local TABLES_FILE="$TEMP_DIR/tables.txt"
    local INDEXES_FILE="$TEMP_DIR/indexes.txt"
    
    # get list of tables (excluding system tables)
    sqlite3 "$DATABASE_LOCATION" "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';" > "$TABLES_FILE" 2>&1
    
    # get indexes
    sqlite3 "$DATABASE_LOCATION" <<EOF > "$INDEXES_FILE" 2>/dev/null
SELECT name, tbl_name, sql FROM sqlite_master WHERE type='index' AND name NOT LIKE 'sqlite_%';
EOF

    # start building JSON output
    cat > "$OUTPUT_FILE" <<EOF
{
  "database_info": {
    "database_name": "$DB_NAME",
    "database_type": "sqlite",
    "extracted_at": "$(date -u +"%Y-%m-%dT%H:%M:%S")Z"
  },
  "tables": [
EOF

    local first_table=true
    local table_count=0
    
    while IFS= read -r table; do
        # skip empty lines
        if [[ -n "$table" ]]; then
            table_count=$((table_count + 1))
            
            if [ "$first_table" = false ]; then
                echo "    ," >> "$OUTPUT_FILE"
            fi
            first_table=false
            
            # check if table exists and has columns
            local col_count
            col_count=$(sqlite3 "$DATABASE_LOCATION" "SELECT COUNT(*) FROM pragma_table_info('$table');" 2>/dev/null || echo "0")
            
            if [ "$col_count" -gt 0 ]; then
                # start table object
                cat >> "$OUTPUT_FILE" <<TABLESTART
    {
      "schema": "main",
      "name": "$table",
      "columns": [
TABLESTART
                
                # get column information
                local first_col=true
                sqlite3 "$DATABASE_LOCATION" <<COLEOF | while IFS='|' read -r cid name type notnull dflt_value pk; do
.mode list
.separator |
SELECT cid, name, LOWER(type), "notnull", dflt_value, pk FROM pragma_table_info('$table') ORDER BY cid;
COLEOF
                    if [[ -n "$name" ]]; then
                        if [ "$first_col" = false ]; then
                            echo "        ," >> "$OUTPUT_FILE"
                        fi
                        first_col=false
                        
                        local nullable="YES"
                        if [ "$notnull" = "1" ]; then
                            nullable="NO"
                        fi
                        
                        local is_pk="NO"
                        if [ "$pk" = "1" ]; then
                            is_pk="YES"
                        fi
                        
                        local default_val="null"
                        if [[ -n "$dflt_value" && "$dflt_value" != "" ]]; then
                            default_val="\"$dflt_value\""
                        fi
                        
                        cat >> "$OUTPUT_FILE" <<COLDATA
        {
          "column_name": "$name",
          "data_type": "$type",
          "character_maximum_length": null,
          "numeric_precision": null,
          "numeric_scale": null,
          "is_nullable": "$nullable",
          "column_default": $default_val,
          "ordinal_position": $((cid + 1)),
          "primary_key": "$is_pk"
        }
COLDATA
                    fi
                done
                
                # get constraints for this table
                echo "      ]," >> "$OUTPUT_FILE"
                echo "      \"constraints\": [" >> "$OUTPUT_FILE"
                
                local constraint_found=false
                
                # check for primary key constraint
                local pk_cols
                pk_cols=$(sqlite3 "$DATABASE_LOCATION" "SELECT GROUP_CONCAT(name, ', ') FROM (SELECT name FROM pragma_table_info('$table') WHERE pk > 0 ORDER BY pk);" 2>/dev/null)
                if [[ -n "$pk_cols" ]]; then
                    if [ "$constraint_found" = true ]; then
                        echo "        ," >> "$OUTPUT_FILE"
                    fi
                    constraint_found=true
                    
                    cat >> "$OUTPUT_FILE" <<PKCONSTRAINT
        {
          "constraint_name": "${table}_pkey",
          "constraint_type": "PRIMARY KEY",
          "column_name": "$pk_cols",
          "foreign_table_schema": null,
          "foreign_table_name": null,
          "foreign_column_name": null
        }
PKCONSTRAINT
                fi

                # check for foreign key constraints
                sqlite3 "$DATABASE_LOCATION" <<FKEOF | while IFS='|' read -r id seq foreign_table from_col to_col on_update on_delete match; do
.mode list
.separator |
SELECT id, seq, "table", "from", "to", on_update, on_delete, match FROM pragma_foreign_key_list('$table');
FKEOF
                    if [[ -n "$foreign_table" && -n "$from_col" && -n "$to_col" ]]; then
                        if [ "$constraint_found" = true ]; then
                            echo "        ," >> "$OUTPUT_FILE"
                        fi
                        constraint_found=true
                        
                        cat >> "$OUTPUT_FILE" <<FKCONSTRAINT
        {
          "constraint_name": "${table}_${from_col}_fkey",
          "constraint_type": "FOREIGN KEY",
          "column_name": "$from_col",
          "foreign_table_schema": "main",
          "foreign_table_name": "$foreign_table",
          "foreign_column_name": "$to_col"
        }
FKCONSTRAINT
                    fi
                done
                
                echo "      ]," >> "$OUTPUT_FILE"
                echo "      \"indexes\": [" >> "$OUTPUT_FILE"
                
                # get indexes 
                local first_index=true
                sqlite3 "$DATABASE_LOCATION" <<IDXEOF | while IFS='|' read -r idx_name tbl_name sql; do
.mode list
.separator |
SELECT name, tbl_name, sql FROM sqlite_master WHERE type='index' AND tbl_name='$table' AND name NOT LIKE 'sqlite_%';
IDXEOF
                    if [[ -n "$idx_name" && -n "$sql" ]]; then
                        if [ "$first_index" = false ]; then
                            echo "        ," >> "$OUTPUT_FILE"
                        fi
                        first_index=false
                        
                        cat >> "$OUTPUT_FILE" <<IDXDATA
        {
          "index_name": "$idx_name",
          "index_definition": "$sql"
        }
IDXDATA
                    fi
                done
                
                echo "      ]" >> "$OUTPUT_FILE"
                echo "    }" >> "$OUTPUT_FILE"
            else
                echo "Debug: Table '$table' has no columns, skipping..."
            fi
        fi
    done < "$TABLES_FILE"
    
    cat >> "$OUTPUT_FILE" <<EOF
  ]
}
EOF

    rm -rf "$TEMP_DIR"
    
    if [ -f "$OUTPUT_FILE" ] && [ -s "$OUTPUT_FILE" ]; then
        echo "Schema extracted to '$OUTPUT_FILE'"
    else
        error "Failed to extract schema or create output file"
    fi

    # format JSON output if jq is available
    if command -v jq >/dev/null 2>&1; then
        if jq '.' "$OUTPUT_FILE" > "${OUTPUT_FILE}.tmp" 2>/dev/null; then
            mv "${OUTPUT_FILE}.tmp" "$OUTPUT_FILE"
        else
            echo "Warning: JSON formatting failed, keeping original output"
            rm -f "${OUTPUT_FILE}.tmp"
        fi
    else
        echo "Warning: jq not found, JSON output not formatted"
    fi
}