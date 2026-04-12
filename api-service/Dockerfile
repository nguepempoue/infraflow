FROM golang:1.24.13-alpine AS builder

RUN apk add --no-cache ca-certificates git

RUN go install github.com/mccutchen/go-httpbin/v2/cmd/go-httpbin@v2.14.0

FROM alpine:3.21

RUN apk add --no-cache ca-certificates

RUN addgroup -S -g 10001 app \
  && adduser -S -D -H -u 10001 -G app app

COPY --from=builder /go/bin/go-httpbin /usr/local/bin/go-httpbin

USER app
EXPOSE 8080

ENTRYPOINT ["go-httpbin"]
CMD ["-port", "8080"]
