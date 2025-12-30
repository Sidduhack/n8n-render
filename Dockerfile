# --- Stage 1: The Builder (We download everything here) ---
FROM alpine:latest AS builder
RUN apk add --no-cache curl

# 1. Download Cloudflare
RUN curl -L --output /cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 && chmod +x /cloudflared

# 2. Download ttyd (Terminal Tool)
RUN curl -L --output /ttyd https://github.com/tsl0922/ttyd/releases/download/1.7.3/ttyd.x86_64 && chmod +x /ttyd

# 3. Download a Static Curl (So you can use it in your terminal later)
RUN curl -L --output /curl-static https://github.com/moparisthebest/static-curl/releases/latest/download/curl-amd64 && chmod +x /curl-static

# --- Stage 2: The Final App Image ---
FROM n8nio/n8n:latest
USER root

# We don't run apk or apt-get here at all. We just copy the binaries.
COPY --from=builder /cloudflared /usr/local/bin/cloudflared
COPY --from=builder /ttyd /usr/local/bin/ttyd
COPY --from=builder /curl-static /usr/local/bin/curl

# Create the startup script
RUN printf "#!/bin/sh\n\
# 1. Start n8n in background\n\
n8n start &\n\
# 2. Start terminal on port 7681\n\
ttyd -p 7681 -c admin:pass123 sh &\n\
sleep 5\n\
# 3. Start the quick tunnel\n\
cloudflared tunnel --url http://localhost:7681\n" > /start.sh \
    && chmod +x /start.sh && chown node:node /start.sh

ENTRYPOINT []
USER node

# Networking
ENV N8N_PORT=5678
EXPOSE 5678
CMD ["sh", "/start.sh"]
