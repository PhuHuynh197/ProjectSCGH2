FROM alpine:3.19

WORKDIR /app

# Tạo user không phải root để tăng bảo mật
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# In ra dòng test đơn giản
ENTRYPOINT ["/bin/sh", "-c", "echo Hello from secure container!"]
