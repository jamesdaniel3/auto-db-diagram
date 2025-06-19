#!/bin/bash

error() {
    echo "Error: $1" >&2
    rm -f "$OUTPUT_FILE"
    exit 1
}

warn() {
    echo "Warning: $1" >&2
}
