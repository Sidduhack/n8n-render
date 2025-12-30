# --- Stage 1: The Builder (Downloads the tools) ---
FROM alpine:latest AS builder
RUN apk add --no-cache curl
RUN curl -L --output /cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 && chmod +x /cloudflared
RUN curl -L --output /ttyd https://github.com/tsl0922/ttyd/releases/download/1.7.3/ttyd.x86_64 && chmod +x /ttyd
RUN curl -L --output /curl-static https://github.com/moparisthebest/static-curl/releases/latest/download/curl-amd64 && chmod +x /curl-static

# --- Stage 2: The Final App Image ---
FROM n8nio/n8n:latest
USER root

# Install nano so you can edit files! 
# We try apk first; if n8n is debian it will fail, so we check.
RUN if [ -f /sbin/apk ]; then apk add --no-cache nano; else apt-get update && apt-get install -y nano && rm -rf /var/lib/apt/lists/*; fi

COPY --from=builder /cloudflared /usr/local/bin/cloudflared
COPY --from=builder /ttyd /usr/local/bin/ttyd
COPY --from=builder /curl-static /usr/local/bin/curl

RUN printf "#!/bin/sh\n\
n8n start &\n\
ttyd -p 7681 -c admin:pass123 sh &\n\
sleep 5\n\
cloudflared tunnel --url http://localhost:7681\n" > /start.sh \
    && chmod +x /start.sh && chown node:node /start.sh

ENTRYPOINT []
USER node
ENV N8N_PORT=5678
EXPOSE 5678
CMD ["sh", "/start.sh"]
