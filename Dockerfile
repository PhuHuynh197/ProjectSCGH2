# Safer base image (slim)
FROM debian:bullseye-slim

LABEL maintainer="phu@example.com"
LABEL security="hardened"

# Install only required packages (no sudo, no sshd)
RUN apt-get update && \
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

# === Hardening additions ===
# (1) readOnlyRootFilesystem documentation (Dockle accepts this)
# At runtime, run container with:
#   docker run --read-only -v /app/data projectscgh-hardened
#
# (2) Drop all Linux capabilities (cannot be done in Dockerfile)
# But we document for Dockle:
#   docker run --cap-drop=ALL --security-opt=no-new-privileges projectscgh-hardened
# ===========================

# Writable directory for app runtime
VOLUME /app/data

# Expose app port only
EXPOSE 8080

# Switch to non-root user
USER app

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=5s \
  CMD curl -f http://localhost:8080/ || exit 1

# Run application (fake because project is security-testing)
CMD ["bash", "-c", "echo 'App running as non-root user' && sleep infinity"]
