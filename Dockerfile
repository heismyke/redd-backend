FROM golang:1.24-alpine AS builder

WORKDIR /app

COPY go.mod go.sum* ./
RUN go mod download

COPY . .
RUN go build -o redd-admin-backend .
RUN go build -o redd-admin-migrate ./cmd/migrate

FROM alpine:3.19

WORKDIR /app

RUN apk add --no-cache ca-certificates tzdata wget \
  && addgroup -S redd \
  && adduser -S redd -G redd

COPY --from=builder /app/redd-admin-backend /app/redd-admin-backend
COPY --from=builder /app/redd-admin-migrate /usr/local/bin/redd-admin-migrate

USER redd

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 CMD wget -qO- http://127.0.0.1:8000/health || exit 1

CMD ["/app/redd-admin-backend"]
