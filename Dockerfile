# syntax=docker/dockerfile:1.7
# Ultra-minimal & secure base image
FROM debian:bullseye-slim

LABEL org.opencontainers.image.title="secure-demo"
LABEL org.opencontainers.image.description="Clean Dockerfile for DevSecOps demo"
LABEL org.opencontainers.image.authors="phu@example.com"
LABEL org.opencontainers.image.licenses="MIT"

# Disable interactive frontend
ENV DEBIAN_FRONTEND=noninteractive

# Install only required runtime packages
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
 && rm -rf /var/lib/apt/lists/*

# Create non-root user with fixed UID/GID
RUN groupadd -g 10001 app \
 && useradd -u 10001 -g app -m -s /usr/sbin/nologin app

WORKDIR /app

# Copy files with correct ownership
COPY --chown=app:app . /app

# Explicitly remove accidental secret files
RUN rm -f /app/.env /app/*.key /app/*.pem || true

# Expose application port only
EXPOSE 8080

# Switch to non-root user
USER app

# Health check (lightweight)
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD curl -fsS http://localhost:8080/ || exit 1

# Demo command (no shell injection, no root)
CMD ["sh", "-c", "echo 'Secure container running as non-root' && sleep infinity"]
