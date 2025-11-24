# Safer base image (slim)
FROM debian:bullseye-slim

LABEL maintainer="phu@example.com"
LABEL security="hardened"

# Install only required packages (minimal, no sudo, no sshd)
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
      curl wget ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Create non-root user "app"
RUN useradd -m -s /bin/bash app

WORKDIR /app

# Copy source code
COPY . /app

# Remove any secret files if accidentally added
RUN rm -f /app/.env || true

# Runtime directory (read-only root fs best practice)
VOLUME /app/data

# Expose app port only (not SSH)
EXPOSE 8080

# Switch to non-root user
USER app

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=5s \
  CMD curl -f http://localhost:8080/ || exit 1

# Run application
CMD ["sh", "-c", "echo 'App running as non-root user' && sleep infinity"]
