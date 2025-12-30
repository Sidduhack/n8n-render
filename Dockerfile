# --- Stage 1: Download Cloudflare & ttyd ---
FROM alpine:latest AS builder
RUN apk add --no-cache curl
# Download Cloudflare (Static binary - very reliable)
RUN curl -L --output /cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 && chmod +x /cloudflared
# Download ttyd (Web Terminal)
RUN curl -L --output /ttyd https://github.com/tsl0922/ttyd/releases/download/1.7.3/ttyd.x86_64 && chmod +x /ttyd

# --- Stage 2: Final image ---
FROM n8nio/n8n:latest
USER root
COPY --from=builder /cloudflared /usr/local/bin/cloudflared
COPY --from=builder /ttyd /usr/local/bin/ttyd

# Create the start script
RUN printf "#!/bin/sh\n\
# 1. Start n8n in background\n\
n8n start &\n\
# 2. Start terminal on port 7681\n\
ttyd -p 7681 -c admin:pass123 sh &\n\
sleep 5\n\
# 3. Start a QUICK tunnel pointing to the terminal\n\
cloudflared tunnel --url http://localhost:7681\n" > /start.sh \
    && chmod +x /start.sh && chown node:node /start.sh

ENTRYPOINT []
USER node
ENV N8N_PORT=5678
EXPOSE 5678
CMD ["sh", "/start.sh"]
