#!/bin/bash

validate_config() {
    if [ "$DATABASE_TYPE" = "null" ] || [ "$HOST" = "null" ] || \
       [ "$PORT" = "null" ] || [ "$USERNAME" = "null" ] || \
       [ "$DATABASE_NAME" = "null" ]; then
        error "Missing required configuration fields in JSON. Required: DATABASE_TYPE, HOST, PORT, USERNAME, DATABASE_NAME"
    fi
}
