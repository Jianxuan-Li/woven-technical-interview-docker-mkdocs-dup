#!/bin/bash

set -e

# Function to produce website from MkDocs project
produce_site() {
    # Build the MkDocs site from the mounted input directory
    if [ ! -f "/input/mkdocs.yml" ]; then
        echo "Error: mkdocs.yml not found in input directory" >&2
        exit 1
    fi

    # Build the site
    cd /input
    mkdocs build --site-dir /output/site

    # Create tar.gz and output to stdout
    cd /output
    tar -czf - site/
}

# Function to serve website from tar.gz stdin
serve_site() {
    # Handle shutdown gracefully
    trap 'echo "Shutting down server..."; exit 0' SIGTERM SIGINT

    # Read tar.gz from stdin and extract
    echo "Extracting site from tar.gz..." >&2
    mkdir -p /tmp/site
    cd /tmp
    tar -xzf -

    # Serve the site
    cd /tmp/site
    echo "Starting server on http://localhost:8000" >&2
    echo "Press Ctrl+C to stop" >&2
    python3 -m http.server 8000 --bind 0.0.0.0
}

# Function to display usage
usage() {
    echo "Usage: $0 {produce|serve}"
    echo "  produce: Build MkDocs site and output tar.gz to stdout"
    echo "  serve:   Read tar.gz from stdin and serve on port 8000"
    exit 1
}

# Main logic
COMMAND="$1"

case "$COMMAND" in
    "produce")
        produce_site
        ;;
    "serve")
        serve_site
        ;;
    *)
        usage
        ;;
esac
