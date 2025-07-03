FROM golang:1.24.4-alpine

# Install build dependencies for SQLite
RUN apk add --no-cache gcc musl-dev sqlite-dev

WORKDIR /app

# Explicitly enable CGO for SQLite support
ENV CGO_ENABLED=1
ENV CC=gcc

COPY go.mod go.sum ./
RUN go mod download

COPY . .

# Explicitly set CGO_ENABLED again and build
RUN CGO_ENABLED=1 go build -o evergiven

# Final stage with runtime dependencies
FROM alpine:latest

# Install runtime dependencies
RUN apk add --no-cache ca-certificates sqlite

WORKDIR /app

# Copy binary from previous stage
COPY --from=0 /app/evergiven .

EXPOSE 8080
CMD ["./evergiven"]