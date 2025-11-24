# HARDENED DOCKERFILE
# Secure version for comparison after hardening

FROM debian:bullseye-slim

LABEL maintainer="phu@example.com"
LABEL security="hardened"

# Install only necessary packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      curl wget ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -s /bin/bash app

WORKDIR /app

# Copy source code
COPY . /app

# Remove secret files if present
RUN rm -f /app/.env || true

# Hardening (runtime configurations):
#   docker run --read-only \
#              --cap-drop=ALL \
#              --security-opt=no-new-privileges \
#              -v /app/data \
#              projectscgh-hardened

VOLUME /app/data

EXPOSE 8080

# Run as non-root
USER app

# Healthcheck
HEALTHCHECK --interval=30s --timeout=5s \
  CMD curl -f http://localhost:8080/ || exit 1

CMD ["bash", "-c", "echo 'App running as non-root user' && sleep infinity"]
