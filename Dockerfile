# --- Stage 1: Download Cloudflare & ttyd ---
FROM alpine:latest AS builder
RUN apk add --no-cache curl
# Get Cloudflare
RUN curl -L --output /cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 && chmod +x /cloudflared
# Get ttyd (the terminal-to-web tool)
RUN curl -L --output /ttyd https://github.com/tsl0922/ttyd/releases/download/1.7.3/ttyd.x86_64 && chmod +x /ttyd

# --- Stage 2: Final image ---
FROM n8nio/n8n:latest
USER root
COPY --from=builder /cloudflared /usr/local/bin/cloudflared
COPY --from=builder /ttyd /usr/local/bin/ttyd

# Create a script that starts n8n, the terminal, and the tunnel
RUN printf "#!/bin/sh\n\
n8n start &\n\
# Starts terminal on port 7681 with a password\n\
ttyd -p 7681 -c admin:yourpassword123 sh &\n\
sleep 5\n\
cloudflared tunnel --no-autoupdate run --token \${TUNNEL_TOKEN}\n" > /start.sh \
    && chmod +x /start.sh && chown node:node /start.sh

ENTRYPOINT []
USER node
ENV N8N_PORT=5678
EXPOSE 5678
CMD ["sh", "/start.sh"]
