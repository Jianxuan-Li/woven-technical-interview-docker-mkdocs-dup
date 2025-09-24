# Docker MkDocs

Woven technical challenge: A Docker-based tool that encapsulates MkDocs to produce and serve static websites by containerization.

## Requirements

- **Docker**: Must be installed and running on your system
- **MkDocs Project**: A valid MkDocs project directory containing `mkdocs.yml` (there is a demo inside `test-project`)

## Installation

1. Clone or download this repository
2. Make the wrapper script executable:
   ```bash
   chmod +x mkdockerize.sh
   ```

That's it! The Docker image will be built automatically on first use.

## Usage

### Quick Start

The simplest way to get started:

```bash
# Build the example project and save to site.tar.gz
./mkdockerize.sh produce

# Serve the built website
./mkdockerize.sh serve
```

Then open http://localhost:8000 in your browser.

### Available Commands

#### `produce` - Build MkDocs Site

```bash
./mkdockerize.sh produce [mkdocs_project_dir]
```

- **Input**: MkDocs project directory (defaults to `test-project`)
- **Output**: tar.gz file containing the static website
- **Behavior**:
  - If run in terminal without redirection: saves to `site.tar.gz`
  - If redirected or piped: outputs to stdout

**Examples:**

```bash
./mkdockerize.sh produce                     # Use default project, save to site.tar.gz
./mkdockerize.sh produce ./test-project           # Build specific project, save to site.tar.gz
./mkdockerize.sh produce ./test-project > custom.tar.gz    # Redirect to custom filename
./mkdockerize.sh produce | ./mkdockerize.sh serve  # Pipe directly to serve
```

#### `serve` - Serve Website

```bash
./mkdockerize.sh serve
```

- **Input**: tar.gz file from stdin or default `site.tar.gz` file
- **Output**: Web server on http://localhost:8000
- **Behavior**:
  - If stdin available: reads tar.gz from pipe
  - If no stdin: uses `site.tar.gz` file
  - If no `site.tar.gz` file, it uses the first `.tar.gz` file
  - Press Ctrl+C to stop the server

**Examples:**

```bash
./mkdockerize.sh serve                       # Serve from site.tar.gz file
cat site.tar.gz | ./mkdockerize.sh serve    # Serve from piped input
./mkdockerize.sh produce | ./mkdockerize.sh serve  # Build and serve in one command
```

#### `rebuild` - Rebuild Docker Image

```bash
./mkdockerize.sh rebuild
```

Forces a rebuild of the Docker image, useful when updating dependencies.

### Common Workflows

#### 1. Simple Build and Serve

```bash
./mkdockerize.sh produce    # Builds to site.tar.gz
./mkdockerize.sh serve      # Serves from site.tar.gz
```

#### 2. One-Shot Build and Serve

```bash
./mkdockerize.sh produce | ./mkdockerize.sh serve
```

#### 3. Build Specific Project

```bash
./mkdockerize.sh produce /path/to/my-mkdocs-project
./mkdockerize.sh serve
```

#### 4. Build and Save for Later

```bash
./mkdockerize.sh produce ./docs > my-website.tar.gz
# Later...
cat my-website.tar.gz | ./mkdockerize.sh serve
```

## Project Structure

```
docker-mkdocs/
├── Dockerfile          # Docker image definition with MkDocs and dependencies
├── entrypoint.sh       # Container entrypoint script handling produce/serve commands
├── mkdockerize.sh      # Main wrapper script for user interaction
├── test-project/       # Example MkDocs project for testing
│   ├── mkdocs.yml      # MkDocs configuration
│   └── docs/           # Documentation source files
└── README.md          # This documentation file
```

## MkDocs Project Requirements

Your MkDocs project directory must contain:
- `mkdocs.yml` - MkDocs configuration file
- `docs/` directory with markdown files
- Any other assets referenced in your documentation

Example minimal structure:
```
my-mkdocs-project/
├── mkdocs.yml
└── docs/
    └── index.md
```

## Technical Details

### Docker Implementation

The solution uses a Python 3.11 slim base image with MkDocs and Material theme pre-installed. The container:
- Accepts input directory as read-only volume mount
- Builds static site using `mkdocs build`
- Outputs compressed tar.gz to stdout
- For serving, extracts tar.gz and runs Python's built-in HTTP server

### Signal Handling

Proper signal handling ensures clean shutdown:
- Ctrl+C gracefully stops the container
- Container processes receive SIGTERM/SIGINT signals correctly
- No orphaned containers remain after stopping

### Error Handling

Comprehensive error checking includes:
- Missing mkdocs.yml validation
- Directory existence verification
- Docker image availability
- File existence for serve command

## Troubleshooting

### "mkdocs.yml not found"

Ensure your project directory contains a valid `mkdocs.yml` file in the root.

### "Docker image not found"

The image builds automatically on first use. If issues persist, run:
```bash
./mkdockerize.sh rebuild
```

### "Permission denied"

Make sure the script is executable:
```bash
chmod +x mkdockerize.sh
```

### Port 8000 already in use

Stop any existing services on port 8000 or modify the port in the script.

## License

This project is a submission of Woven technical interview chanllenge, no restriction to any usage.
