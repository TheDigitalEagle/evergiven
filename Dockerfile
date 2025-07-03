FROM golang:1.24.4-alpine

# Ensure statically linked binary
ENV CGO_ENABLED=0

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN go build -o evergiven

EXPOSE 8080
CMD ["./evergiven"]