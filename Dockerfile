FROM golang:1.24-alpine AS builder

WORKDIR /app
COPY . .
RUN go mod download
RUN CGO_ENABLED=0 GOOS=linux go build -o /app/worker ./cmd/worker
RUN CGO_ENABLED=0 GOOS=linux go build -o /app/api ./cmd/api

FROM alpine:latest
WORKDIR /app
COPY --from=builder /app/worker /app/worker
COPY --from=builder /app/api /app/api

# Create non-root user
RUN adduser -D -g '' appuser
USER appuser

CMD ["/app/api"] 