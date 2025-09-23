#!/bin/bash

set -e

DOCKER_IMAGE="mkdocs-docker"

ensure_docker_image() {
    if ! docker image inspect "$DOCKER_IMAGE" >/dev/null 2>&1; then
        echo "Building Docker image '$DOCKER_IMAGE'..." >&2
        docker build -t "$DOCKER_IMAGE" "$(dirname "$0")" >&2
    fi
}

handle_produce() {
    local mkdocs_dir="$1"
    local output_file="$2"

    # Use test-project as default if no parameter provided
    if [ -z "$mkdocs_dir" ]; then
        mkdocs_dir="$(dirname "$0")/test-project"
        echo "No directory specified, using default: $mkdocs_dir" >&2
    fi

    if [ ! -d "$mkdocs_dir" ]; then
        echo "Error: Directory '$mkdocs_dir' does not exist" >&2
        exit 1
    fi

    if [ ! -f "$mkdocs_dir/mkdocs.yml" ]; then
        echo "Error: mkdocs.yml not found in '$mkdocs_dir'" >&2
        exit 1
    fi

    ensure_docker_image

    # Convert to absolute path
    mkdocs_dir="$(cd "$mkdocs_dir" && pwd)"

    # Check if output should go to file or stdout
    if [ -t 1 ] && [ -z "$output_file" ]; then
        # If stdout is a terminal and no output file specified, use default
        output_file="site.tar.gz"
        echo "No output redirection detected, saving to: $output_file" >&2

        # Run Docker container and save to file
        docker run --rm \
            -v "$mkdocs_dir:/input:ro" \
            "$DOCKER_IMAGE" produce > "$output_file"

        echo "Site built and saved to: $output_file" >&2
    else
        # Output to stdout (for piping or explicit redirection)
        docker run --rm \
            -v "$mkdocs_dir:/input:ro" \
            "$DOCKER_IMAGE" produce
    fi
}

handle_serve() {
    ensure_docker_image

    # Add signal handling for graceful shutdown
    trap 'echo "Stopping container..."; docker stop $(docker ps -q --filter ancestor="$DOCKER_IMAGE") 2>/dev/null || true; exit 0' SIGTERM SIGINT

    # Check if input is coming from stdin or use default file
    if [ -t 0 ]; then
        # No stdin input, use default file
        local default_file="site.tar.gz"
        if [ ! -f "$default_file" ]; then
            echo "Error: No stdin input and default file '$default_file' not found" >&2
            echo "Please either:" >&2
            echo "  1. Pipe input: cat site.tar.gz | $0 serve" >&2
            echo "  2. Create site.tar.gz by running: $0 produce" >&2
            exit 1
        fi

        echo "No stdin input detected, using default file: $default_file" >&2
        docker run --rm -i -p 8000:8000 --init "$DOCKER_IMAGE" serve < "$default_file"
    else
        # Read from stdin
        docker run --rm -i -p 8000:8000 --init "$DOCKER_IMAGE" serve
    fi
}

handle_rebuild() {
    echo "Rebuilding Docker image '$DOCKER_IMAGE'..."
    docker build -t "$DOCKER_IMAGE" "$(dirname "$0")"
}

usage() {
    echo "Usage: $0 {produce|serve|rebuild}"
    echo ""
    echo "Commands:"
    echo "  produce [mkdocs_project_dir]  Build MkDocs site and output tar.gz to stdout"
    echo "                                (defaults to test-project if not specified)"
    echo "  serve                         Read tar.gz from stdin or default site.tar.gz file"
    echo "  rebuild                       Rebuild the Docker image"
    echo ""
    echo "Examples:"
    echo "  $0 produce                           # Use default test-project, save to site.tar.gz"
    echo "  $0 serve                             # Serve from default site.tar.gz file"
    echo "  $0 produce && $0 serve               # Build then serve"
    echo "  $0 produce | $0 serve               # Build and serve directly"
    echo "  cat site.tar.gz | $0 serve          # Serve from piped input"
    echo "  $0 rebuild"
    exit 1
}

# Main logic
COMMAND="$1"

case "$COMMAND" in
    "produce")
        handle_produce "$2" "$3"
        ;;
    "serve")
        handle_serve
        ;;
    "rebuild")
        handle_rebuild
        ;;
    *)
        usage
        ;;
esac
