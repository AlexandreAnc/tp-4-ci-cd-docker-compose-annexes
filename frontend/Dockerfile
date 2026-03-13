FROM alpine:3.20 AS builder

WORKDIR /app

COPY index.html .

RUN echo "OK" > health

FROM nginx:1.27-alpine AS runtime

COPY --from=builder /app/index.html /usr/share/nginx/html/index.html
COPY --from=builder /app/health /usr/share/nginx/html/health

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s CMD wget -qO- http://127.0.0.1/health || exit 1