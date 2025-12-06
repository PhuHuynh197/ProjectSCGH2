# syntax=docker/dockerfile:1

# Distroless base image (no shell, no package manager)
FROM gcr.io/distroless/base-debian12:nonroot

LABEL maintainer="phu@example.com"
LABEL security="distroless-clean"

# Set working directory
WORKDIR /app

# Copy source code
COPY --chown=nonroot:nonroot . /app

# Expose port (just for demo)
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD ["/busybox/sh", "-c", "true"]

# Run container (no shell injection possible)
USER app
CMD ["sleep", "infinity"]
