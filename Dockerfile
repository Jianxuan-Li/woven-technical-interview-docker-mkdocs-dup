FROM python:3.11-slim

# Install MkDocs and required dependencies
RUN pip install mkdocs mkdocs-material

# Create working directories
RUN mkdir -p /app /input /output

# Copy entrypoint script
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Set working directory
WORKDIR /app

# Set entrypoint
ENTRYPOINT ["/app/entrypoint.sh"]