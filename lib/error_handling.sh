#!/bin/bash

error() {
    echo "Error: $1" >&2
    exit 1
}

warn() {
    echo "Warning: $1" >&2
}
