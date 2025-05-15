# Dùng Alpine mới đã được vá lỗi bảo mật
FROM alpine:3.18

# Cài curl và zlib (nếu cần)
RUN apk add --no-cache curl zlib

# Copy app nếu có (tùy vào project của m)
WORKDIR /app
COPY . .

# Default command – chỉ cần có để image không crash
CMD ["sh"]
