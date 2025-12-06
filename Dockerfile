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

# Drop capabilities (best practice)
# Dockerfile itself cannot set capabilities, but Dockle checks USER + no sudo + no sshd
# These are runtime options, but we comment doc:
#   docker run --cap-drop ALL ...
# Therefore, we explicitly avoid adding harmful packages.

# Read-only filesystem (for Dockle)
# Note: This only works if the app does not need write permission.
# For demo purpose → still included.
VOLUME /app/data

# Expose app port only (not SSH)
EXPOSE 8080

# Switch to non-root user
USER app

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=5s \
  CMD curl -f http://localhost:8080/ || exit 1

# Run application (fake because project is security-testing)
CMD ["bash", "-c", "echo 'App running as non-root user' && sleep infinity"]
